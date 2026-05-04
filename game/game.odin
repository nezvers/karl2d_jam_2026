#+vet explicit-allocators
package karl2d_hot_reload_game

import karl2d "karl2d"
import "base:runtime"
// import "core:math/linalg"
// import "core:fmt"

Vec2 :: karl2d.Vec2

Game_Memory :: struct {
	allocator: runtime.Allocator,
	counter: int,
	player_pos: karl2d.Vec2,
}

@(private="file")
g: ^Game_Memory

@export
game_startup :: proc(allocator: runtime.Allocator) -> (k2_state: ^karl2d.State) {
	// TODO: Load game
	return karl2d.init(
		1280,
		720,
		"Karl2D: Hot Reload Example",
		allocator = allocator,
		options = {
			window_mode = .Windowed_Resizable,
		}
	)
}

@export
game_shutdown :: proc() {
	karl2d.shutdown()
}

@export
game_init_state :: proc(k2_state: ^karl2d.State, allocator: runtime.Allocator) {
	g = new(Game_Memory, allocator)
	g.allocator = allocator
	g.player_pos = {200, 200}
}

@export
game_destroy_state :: proc() {
	free(g, g.allocator)
}


@export
game_update :: proc() -> bool {
	if !karl2d.update() {
		return false
	}

	karl2d.clear(karl2d.LIGHT_BLUE)

	karl2d.present()

	free_all(context.temp_allocator)
	return true
}

@export	
game_memory :: proc() -> ^Game_Memory {
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
}

@export
game_force_restart :: proc() -> bool {
	return karl2d.key_went_down(.F6)
}
