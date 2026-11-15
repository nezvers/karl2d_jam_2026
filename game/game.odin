#+vet explicit-allocators
package karl2d_hot_reload_game

import karl2d "karl2d"
import "base:runtime"
import "core:fmt"
import state "game_state"
import screen "game_screens"
import "window"
import "actor"
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
	sfx.Bind(g.sfx_states[:])
	actor.RegisterPrefabs(&g.scene_system)

	// STARTING SCREEN
	screen.Start()
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
}

// For the hot reload test
@export
game_debug_info :: proc() -> Debug_Info {
	if g == nil {return {}}
	current: int = int(g.scene_system.current) if g.scene_system.has_current else -1
	return {screen = current, counter = int(g.counter)}
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
	sfx.Bind(g.sfx_states[:])
	scene.SceneRebind(&g.scene_system, screen.List(), assets.defs[:], scene_glue.loaders[:])
	scene.SceneResume(&g.scene_system)
}

@export
game_force_restart :: proc() -> bool {
	return karl2d.key_went_down(.F6)
}