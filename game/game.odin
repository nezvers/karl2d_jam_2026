#+vet explicit-allocators
package karl2d_hot_reload_game

import karl2d "karl2d"
import "base:runtime"
import "core:fmt"
import state "game_state"
import screen "game_screens"
import "window"
// import "core:math"
// import viewport "viewport_rect"
// import "core:math/linalg"
// import "core:fmt"

Vec2 :: karl2d.Vec2
Vec2i :: [2]int
Rect :: karl2d.Rect
Color :: karl2d.Color
Camera :: karl2d.Camera

Game_Memory :: state.Game_Memory
@(private="file")
g: ^Game_Memory

WINDOW_SIZE :[2]int: {1280, 720}
GAME_TITLE :: "Karl2D Game Template"

@export
game_startup :: proc(allocator: runtime.Allocator) -> (k2_state: ^karl2d.State) {
	return karl2d.init(
		WINDOW_SIZE.x,
		WINDOW_SIZE.y,
		GAME_TITLE,
		allocator = allocator,
		options = {
			window_mode = .Windowed_Resizable,
		},
	)
}

@export
game_shutdown :: proc() {
	release_screen()
	karl2d.shutdown()
}

// Finish the running screen once. Clearing it makes a second call (restart, shutdown) harmless
@(private="file")
release_screen :: proc() {
	if state.current.finit != nil {state.current.finit()}
	state.current = {}
}

// Hot reload: the old DLL owns the resources of the running screen (its globals, audio, textures), so it has to release them
// before its code is left behind
@export
game_release_screen :: proc() {
	release_screen()
}

@export
game_init_state :: proc(k2_state: ^karl2d.State, allocator: runtime.Allocator) {
	// A new DLL has its own copy of the Karl2D globals, they have to point at the state the exe holds.
	// Without this a reload that has to rebuild the memory (see game_memory_layout) calls Karl2D with no state.
	karl2d.set_internal_state(k2_state)
	// TODO: Load game
	g = new(Game_Memory, allocator)
	state.g = g
	g.allocator = allocator
	g.window_scale = karl2d.get_window_scale()
	g.game_width = 480
	g.game_height = 270
	g.background_color = karl2d.WHITE

	// STARTING SCREEN
	screen.Set(.Title)
}

@export
game_destroy_state :: proc() {
	release_screen()
	state.g = nil
	free(g, g.allocator)
}


@export
game_update :: proc() -> bool {
	if !karl2d.update() {
		return false
	}

	events := karl2d.get_events()
	window.process_events(events)

	g.counter += 1
	if state.current.update != nil {state.current.update()}

	karl2d.clear(g.background_color)
	if state.current.draw != nil {state.current.draw()}
	if state.current.gui != nil {state.current.gui()}
	karl2d.present()

	free_all(context.temp_allocator)
	return true
}

@export	
game_memory :: proc() -> ^Game_Memory {
	// TODO: exit state.current ???
	// TODO: Save game
	return g
}

@export
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

// Identifies the exact layout of the memory, not only its size: reordered or retyped fields can keep the same size.
// typeid is no use for this, it only hashes the name of a named type.
@export
game_memory_layout :: proc() -> u64 {
	hash: u64 = 14695981039346656037
	hash_layout(&hash, type_info_of(Game_Memory))
	return hash
}

@(private="file")
hash_bytes :: proc(hash: ^u64, text: string) {
	for b in transmute([]u8)text {
		hash^ = (hash^ ~ u64(b)) * 1099511628211
	}
}

// Field names, offsets and types, through nested structs and arrays
@(private="file")
hash_layout :: proc(hash: ^u64, info: ^runtime.Type_Info) {
	base := runtime.type_info_base(info)
	hash_bytes(hash, fmt.tprintf("%v|%d|", info.id, info.size))
	#partial switch v in base.variant {
	case runtime.Type_Info_Struct:
		for i in 0 ..< int(v.field_count) {
			hash_bytes(hash, v.names[i])
			hash_bytes(hash, fmt.tprintf("@%d:", v.offsets[i]))
			hash_layout(hash, v.types[i])
		}
	case runtime.Type_Info_Array:
		hash_bytes(hash, fmt.tprintf("[%d]", v.count))
		hash_layout(hash, v.elem)
	}
}

Debug_Info :: struct {
	screen: int,
	counter: int,
}

// For the hot reload test
@export
game_debug_info :: proc() -> Debug_Info {
	if g == nil {return {}}
	return {screen = g.game_screen, counter = int(g.counter)}
}

@export
game_debug_set_screen :: proc(index: int) {
	screen.Set(cast(screen.Screens)index)
}

@export
game_hot_reloaded :: proc(memory: ^Game_Memory, k2_state: ^karl2d.State) {
	karl2d.set_internal_state(k2_state)
	g = memory
	state.g = g
	screen.Set(cast(screen.Screens)g.game_screen)
}

@export
game_force_restart :: proc() -> bool {
	return karl2d.key_went_down(.F6)
}