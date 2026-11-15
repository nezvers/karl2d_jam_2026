#+vet explicit-allocators
package karl2d_hot_reload_game

import karl2d "karl2d"
import "base:runtime"
import "core:fmt"
import state "game_state"
import screen "game_screens"
import "window"
import "actor"
import "projectile"
import "vfx"
import "assets"
import "sfx"
import "scene"
import scene_glue "scene/karl2d"
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

// Finish the running scene once (its finit, its listeners and its memory). A second call (restart, shutdown) finds nothing to do
@(private="file")
release_screen :: proc() {
	if g != nil {
		scene.SceneRelease(&g.scene_system)
	}
}

// Hot reload: the old DLL owns what the running scene holds in its globals and its listeners, so it has to release them
// before its code is left behind. Loaded assets and the scene ids stay in the game memory
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
	window.refresh()

	// Assets: a table of data that is loaded in the background. Scenes say what they need, the system loads it behind a transition
	// when a scene was not predicted and prefetches the assets of the scenes that are likely to come next
	g.placeholder = scene_glue.PlaceholderTexture()
	assets.Bind(&g.scene_system.assets, g.placeholder)
	scene.SceneSystemInit(&g.scene_system, {scene_memory = g.scene_memory[:], decode_memory = g.decode_memory[:], allocator = allocator}, screen.List(), assets.defs[:], scene_glue.loaders[:], &g.asset_storage)
	bind_game_memory()
	actor.RegisterPrefabs(&g.scene_system)

	// STARTING SCREEN: the one the player was on when the memory had to be rebuilt (restart, a reload that changed the memory)
	if restore_screen >= 0 {
		screen.StartAt(cast(screen.Screens)restore_screen)
		g.notice = restore_notice
	} else {
		screen.Start()
	}
	restore_screen = -1
	restore_notice = 0
}

NOTICE_RELOADED :: 1
NOTICE_RESTARTED :: 2
NOTICE_RECREATED :: 3
NOTICE_SECONDS :: 2.0

// Set by the exe before game_init_state, and kept in the DLL: the new memory has nothing to remember it with
restore_screen: int = -1
restore_notice: u8

// The code has its own copy of every global: point the packages at the data in the game memory
bind_game_memory :: proc() {
	sfx.Bind(g.sfx_states[:])
	actor.Bind(&g.actors)
	projectile.Bind(&g.projectiles)
	vfx.Bind(&g.effects)
}

// The screen that is running, or the one it is going to. -1 when there is none
@export
game_current_screen :: proc() -> int {
	if g == nil { return -1 }
	if g.scene_system.transition.phase != .NONE { return int(g.scene_system.target) }
	return int(g.scene_system.current) if g.scene_system.has_current else -1
}

// The next game_init_state starts on this screen and shows the notice (NOTICE_*, 0 for none)
@export
game_set_restore :: proc(screen_index: int, notice: int) {
	restore_screen = screen_index
	restore_notice = u8(notice)
}

// A label in the corner that fades out: tells that a reload or restart did happen
draw_notice :: proc(delta_time: f32) {
	if g.notice == 0 { return }
	g.notice_time += delta_time
	if g.notice_time >= NOTICE_SECONDS {
		g.notice = 0
		g.notice_time = 0
		return
	}
	text: string = "Restarted"
	if g.notice == NOTICE_RELOADED { text = "Code reloaded" }
	if g.notice == NOTICE_RECREATED { text = "State recreated" }
	// full for the first second, then fades
	alpha: f32 = clamp((NOTICE_SECONDS - g.notice_time) / (NOTICE_SECONDS - 1.0), 0, 1)
	size: f32 = window.get_window_size().y * 0.04
	color: karl2d.Color = karl2d.DARK_GREEN
	color.a = u8(alpha * 255)
	karl2d.draw_text(text, {size * 0.5, size * 0.5}, size, color)
}

@export
game_destroy_state :: proc() {
	scene.SceneShutdown(&g.scene_system)
	scene_glue.DestroyPlaceholderTexture(g.placeholder)
	state.g = nil
	allocator: runtime.Allocator = g.allocator
	free(g, allocator)
	g = nil
}


@export
game_update :: proc() -> bool {
	if !karl2d.update() {
		return false
	}

	events := karl2d.get_events()
	window.process_events(events)

	g.counter += 1
	// loads a few assets, runs the transition and the update of the scene
	scene.SceneUpdate(&g.scene_system, karl2d.get_frame_time())

	karl2d.clear(g.background_color)
	scene.SceneDraw(&g.scene_system)
	scene.SceneGui(&g.scene_system)
	scene_glue.DrawTransition(&g.scene_system, window.get_window_size())
	draw_notice(karl2d.get_frame_time())
	karl2d.present()

	free_all(context.temp_allocator)
	return true
}

@export	
game_memory :: proc() -> ^Game_Memory {
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
	case ^runtime.Type_Info_Struct:
		for i in 0 ..< int(v.field_count) {
			hash_bytes(hash, v.names[i])
			hash_bytes(hash, fmt.tprintf("@%d:", v.offsets[i]))
			hash_layout(hash, v.types[i])
		}
	case ^runtime.Type_Info_Array:
		hash_bytes(hash, fmt.tprintf("[%d]", v.count))
		hash_layout(hash, v.elem)
	}
}

Debug_Info :: struct {
	screen: int,
	counter: int,
	gameplay_frames: int,
}

// For the hot reload test
@export
game_debug_info :: proc() -> Debug_Info {
	if g == nil {return {}}
	current: int = int(g.scene_system.current) if g.scene_system.has_current else -1
	return {screen = current, counter = int(g.counter), gameplay_frames = g.gameplay_frames}
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
	// The new code has its own tables. The memory (loaded assets, which scene runs) is the old one
	assets.Bind(&g.scene_system.assets, g.placeholder)
	bind_game_memory()
	scene.SceneRebind(&g.scene_system, screen.List(), assets.defs[:], scene_glue.loaders[:])
	scene.SceneResume(&g.scene_system)
	g.notice = restore_notice if restore_notice != 0 else NOTICE_RELOADED
	restore_notice = 0
	g.notice_time = 0
}

// 0: nothing. 1: F6, release the screen and start it again on the same memory (the game continues where it was).
// 2: Shift + F6, throw the memory away and start over on the same screen
@export
game_force_restart :: proc() -> int {
	if !karl2d.key_went_down(.F6) { return 0 }
	return 2 if karl2d.key_is_held(.Left_Shift) || karl2d.key_is_held(.Right_Shift) else 1
}