package window

import state "../game_state"
import karl2d "../karl2d"
import viewport "../viewport_rect"
import "core:math"

USE_GAME_TEXTURE :: false

process_events :: proc(events: []karl2d.Event) {
	// events := karl2d.get_events()

	for event in events {
		#partial switch e in event {
		case karl2d.Event_Window_Scale_Changed:
			when ODIN_OS != .JS && USE_GAME_TEXTURE  {
				state.g.window_scale = e.scale
				update_scale()
			}

		case karl2d.Event_Screen_Resize:
			state.g.window_scale = karl2d.get_window_scale()
			state.g.window_width = int(f32(e.width) / state.g.window_scale)
			state.g.window_height = int(f32(e.height) / state.g.window_scale)
			update_game_center()
		}
	}
}

// Get actual window size with scaling
get_window_size :: proc()->[2]f32 {
	return {(cast(f32)state.g.window_width * state.g.window_scale), (cast(f32)state.g.window_height * state.g.window_scale)}
}

get_view_mouse_position :: proc()->[2]f32 {
	mouse_pos: = karl2d.get_mouse_position()
	if !USE_GAME_TEXTURE {
		return mouse_pos
	}
	// TODO: fix zoom displacement
	return {mouse_pos.x - state.g.view_rect.x, mouse_pos.y - state.g.view_rect.y}
}

get_world_mouse_position :: proc()->Vec2 {
	mouse_pos: = karl2d.get_mouse_position()
	return state.g.camera.target + (-state.g.camera.offset + mouse_pos) / state.g.camera.zoom
}

update_scale :: proc() {
	karl2d.set_screen_size(int(f32(state.g.window_width) * state.g.window_scale), int(f32(state.g.window_height) * state.g.window_scale))
}

update_game_center :: proc() {
	window_size: = get_window_size()
    state.g.camera.offset = window_size * 0.5
	assert(state.g.game_width != 0)
	assert(state.g.game_height != 0)
	state.g.camera.zoom = math.max(1, cast(f32)(cast(int)window_size.y / state.g.game_height))

	if !USE_GAME_TEXTURE { return }
	// TODO: fix camera zooming for render texture

	// view_rect.x = (window_size.x - view_rect.w) * 0.5
	// view_rect.y = (window_size.y - view_rect.h) * 0.5
	viewport.ViewportKeepHeightPixel(
		cast(^viewport.Rect)&state.g.view_rect, 
		cast(^viewport.Rect)&state.g.projected_rect, 
		{cast(i32)state.g.game_width, cast(i32)state.g.game_height}, 
		{cast(i32)window_size.x, cast(i32)window_size.y},
	)

	karl2d.destroy_render_texture(state.g.game_texture)
	state.g.game_texture = karl2d.create_render_texture(cast(int)state.g.view_rect.w, cast(int)state.g.view_rect.h)
}