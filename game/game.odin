#+vet explicit-allocators
package karl2d_hot_reload_game

import karl2d "karl2d"
import "base:runtime"
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
		}
	)
}

@export
game_shutdown :: proc() {
	if state.current.finit != nil {state.current.finit()}
	karl2d.shutdown()
}

@export
game_init_state :: proc(k2_state: ^karl2d.State, allocator: runtime.Allocator) {
	// TODO: Load game
	g = new(Game_Memory, allocator)
	state.g = g
	g.allocator = allocator
	g.window_scale = karl2d.get_window_scale()
	g.game_width = 480
	g.game_height = 270
	g.background_color = karl2d.WHITE

	screen.SetScreen(0)
}

@export
game_destroy_state :: proc() {
	if state.current.finit != nil {state.current.finit()}
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

@export
game_hot_reloaded :: proc(memory: ^Game_Memory, k2_state: ^karl2d.State) {
	karl2d.set_internal_state(k2_state)
	g = memory
	state.g = g
	screen.SetScreen(g.game_screen)
}

@export
game_force_restart :: proc() -> bool {
	return karl2d.key_went_down(.F6)
}