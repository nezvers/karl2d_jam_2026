// Development game exe. Loads game.dll and reloads it whenever it changes.

package karl2d_hot_reload_main

import "core:dynlib"
import "core:fmt"
import "core:c/libc"
import "core:os"
import "core:log"
import "core:mem"
import "core:time"
import "core:strings"
import "base:runtime"

// Folder where build.odin puts game.dll. The hot reload test (hot_reload_test/) uses its own folder
DLL_DIR :: #config(DLL_DIR, "bin/hot_reload")
// Test mode: scripted by files in DLL_DIR, prints a status line every few frames
HOT_RELOAD_TEST :: #config(HOT_RELOAD_TEST, false)

when ODIN_OS == .Windows {
	DLL_EXT :: ".dll"
} else when ODIN_OS == .Darwin {
	DLL_EXT :: ".dylib"
} else {
	DLL_EXT :: ".so"
}

copy_dll :: proc(to: string) -> bool {
	err := os.copy_file(to, DLL_DIR + "/game" + DLL_EXT)
	if err != nil {
		log.errorf("Failed to copy game" + DLL_EXT + " to {0}: {1}", to, err)
		return false
	}
	return true
}

// Messages the game shows in the corner, same numbers as in game.odin
NOTICE_RELOADED :: 1
NOTICE_RESTARTED :: 2
NOTICE_RECREATED :: 3

Debug_Info :: struct {
	screen: int,
	counter: int,
	gameplay_frames: int,
}

Game_API :: struct {
	lib: dynlib.Library,
	startup: proc(allocator: runtime.Allocator) -> (k2_state: rawptr),
	shutdown: proc(),
	init_state: proc(k2_state: rawptr, allocator: runtime.Allocator),
	destroy_state: proc(),
	update: proc() -> bool,
	memory: proc() -> rawptr,
	memory_size: proc() -> int,
	hot_reloaded: proc(mem: rawptr, k2_state: rawptr),
	force_restart: proc() -> int,
	release_screen: proc(),
	memory_layout: proc() -> u64,
	debug_info: proc() -> Debug_Info,
	debug_set_screen: proc(index: int),
	current_screen: proc() -> int,
	set_restore: proc(screen_index: int, notice: int),
	modification_time: time.Time,
	api_version: int,
}

// A DLL that is still being written, or that doesn't match this exe, is not fatal: the game keeps running the old one
load_game_api :: proc(api_version: int) -> (api: Game_API, ok: bool) {
	mod_time, mod_time_error := os.last_write_time_by_name(DLL_DIR + "/game" + DLL_EXT)
	if mod_time_error != os.ERROR_NONE {
		log.errorf(
			"Failed getting last write time of game" + DLL_EXT + ", error code: {1}",
			mod_time_error,
		)
		return
	}

	// NOTE: this needs to be a relative path for Linux to work.
	game_dll_name := fmt.tprintf("{0}game_{1}" + DLL_EXT, "./" when ODIN_OS != .Windows else "", api_version)
	copy_dll(game_dll_name) or_return

	_, ok = dynlib.initialize_symbols(&api, game_dll_name, "game_", "lib")
	if !ok {
		log.errorf("Failed initializing symbols: {0}", dynlib.last_error())
		api.api_version = api_version
		unload_game_api(&api)
		api = {}
		return
	}

	api.api_version = api_version
	api.modification_time = mod_time
	ok = true

	return
}

unload_game_api :: proc(api: ^Game_API) {
	if api.lib != nil {
		if !dynlib.unload_library(api.lib) {
			log.errorf("Failed unloading lib: {0}", dynlib.last_error())
		}
	}

	// the copy is named after the version of the build that was loaded, os.remove fails while it is still loaded
	if os.remove(fmt.tprintf("game_{0}" + DLL_EXT, api.api_version)) != nil {
		log.errorf("Failed to remove game_{0}" + DLL_EXT + " copy", api.api_version)
	}
}


// Memory has to be reused only when the new DLL describes it exactly like the old one. Same size is not enough, a reordered or
// retyped field keeps the size and would be read as garbage.
same_game_memory :: proc(a, b: Game_API) -> bool {
	return a.memory_size() == b.memory_size() && a.memory_layout() == b.memory_layout()
}

// Hand the running game over to a newly loaded DLL. The old DLL stays loaded because the new state can still point into it.
switch_game_api :: proc(old, new: Game_API, k2_state: rawptr, old_game_apis: ^[dynamic]Game_API) -> Game_API {
	append(old_game_apis, old)

	if same_game_memory(old, new) {
		// Keep the game memory. What the running screen holds (globals, audio, textures) lives in the old DLL and is released by
		// it, the new DLL starts the screen again on the same memory.
		game_memory := old.memory()
		old.release_screen()
		new.hot_reloaded(game_memory, k2_state)
	} else {
		// the memory is new, the screen the player was on is not
		new.set_restore(old.current_screen(), NOTICE_RELOADED)
		old.destroy_state()
		new.init_state(k2_state, context.allocator)
	}
	return new
}

main :: proc() {
	context.logger = log.create_console_logger()

	default_allocator := context.allocator
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, default_allocator)
	context.allocator = mem.tracking_allocator(&tracking_allocator)

	reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> ([]mem.Tracking_Allocator_Entry, bool) {
		err := false
		leaks := make([dynamic]mem.Tracking_Allocator_Entry, context.temp_allocator)

		for _, value in a.allocation_map {
			append(&leaks, value)
			err = true
		}

		mem.tracking_allocator_clear(a)
		return leaks[:], err
	}

	game_api_version := 0
	game_api, game_api_ok := load_game_api(game_api_version)

	if !game_api_ok {
		log.error("Failed to load Game API")
		return
	}

	game_api_version += 1
	k2_state := game_api.startup(context.allocator)
	game_api.init_state(k2_state, context.allocator)

	old_game_apis := make([dynamic]Game_API, default_allocator)
	next_reload_try: time.Time

	window_open := true
	frame := 0
	for window_open {
		when HOT_RELOAD_TEST {
			frame += 1
			// gameplay has the real resources to keep or release
			if frame == 10 || os.exists(DLL_DIR + "/gameplay") {
				os.remove(DLL_DIR + "/gameplay")
				game_api.debug_set_screen(2)
			}
			if frame % 5 == 0 {
				info := game_api.debug_info()
				fmt.printfln("[HR] frame=%d version=%d screen=%d counter=%d run=%d", frame, game_api.api_version, info.screen, info.counter, info.gameplay_frames)
			}
			if os.exists(DLL_DIR + "/stop") {
				break
			}
		}
		restart := game_api.force_restart()
		restart_requested := restart == 2
		when HOT_RELOAD_TEST {
			if os.exists(DLL_DIR + "/restart") {
				os.remove(DLL_DIR + "/restart")
				restart_requested = true
			}
		}
		if restart == 1 {
			// same memory, the code starts the screen again on it: the state is recreated, not lost
			game_api.set_restore(-1, NOTICE_RECREATED)
			game_api.release_screen()
			game_api.hot_reloaded(game_api.memory(), k2_state)
		}
		if restart_requested {
			game_api.set_restore(game_api.current_screen(), NOTICE_RESTARTED)
			game_api.destroy_state()
			game_api.init_state(k2_state, context.allocator)
		}
		
		window_open = game_api.update()

		game_dll_mod, game_dll_mod_err := os.last_write_time_by_name(DLL_DIR + "/game" + DLL_EXT)
		reload := game_dll_mod_err == os.ERROR_NONE && game_api.modification_time != game_dll_mod

		if reload && time.since(next_reload_try) > 0 {
			new_game_api, new_game_api_ok := load_game_api(game_api_version)

			if new_game_api_ok {
				game_api = switch_game_api(game_api, new_game_api, k2_state, &old_game_apis)
				game_api_version += 1
			} else {
				// most likely the build is still writing the DLL
				next_reload_try = time.time_add(time.now(), 500 * time.Millisecond)
			}
		}

		free_all(context.temp_allocator)
	}

	free_all(context.temp_allocator)
	game_api.destroy_state()
	game_api.shutdown()
	
	if leaks, has_leaks := reset_tracking_allocator(&tracking_allocator); has_leaks {
		for l in leaks {
			fmt.eprintfln("%v: Leaked %v bytes", l.location, l.size)
		}

		panic("Memory leaks detected!")
	}

	for &g in old_game_apis {
		unload_game_api(&g)
	}

	delete(old_game_apis)

	unload_game_api(&game_api)
	mem.tracking_allocator_destroy(&tracking_allocator)
}

// make game use good GPU on laptops etc

@(export)
NvOptimusEnablement: u32 = 1

@(export)
AmdPowerXpressRequestHighPerformance: i32 = 1
