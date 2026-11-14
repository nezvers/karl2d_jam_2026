package game_state

import "base:runtime"
import karl2d "../karl2d"

// Build knobs of the hot reload test (hot_reload_test/): they change the size or the layout of Game_Memory on purpose
GAME_MEMORY_PAD :: #config(GAME_MEMORY_PAD, 0)
GAME_MEMORY_FLOAT_COUNTER :: #config(GAME_MEMORY_FLOAT_COUNTER, false)
Counter :: f64 when GAME_MEMORY_FLOAT_COUNTER else int

Game_Memory :: struct {
	allocator: runtime.Allocator,
	counter: Counter, // frames since the memory was created
	_test_pad: [GAME_MEMORY_PAD]u8,
	window_width:int,
	window_height:int,
	window_scale: f32,
	game_width:int,
	game_height:int,
    game_screen:int,
	background_color: Color,
	camera: Camera,
	view_rect: Rect,
	projected_rect: Rect,
	game_texture: Render_Texture, // TODO: solve render texture with camera
}

g: ^Game_Memory

GameState :: struct {
    init: proc(),
    finit: proc(),
    update: proc(),
    draw: proc(),
    gui: proc(),
    name: string,
}

current: GameState

change_game_state :: proc(new_state: GameState) {
    if (current.finit != nil) {
        current.finit()
    }
    current = new_state
    
    if (current.init != nil) {
        current.init()
    }
}