#+ private file
package game_screens

import state "../game_state"
import "../scene"
import karl2d "../karl2d"
import "../window"
import "../ui"
import "../input"

@(private="package")
screen_title_def: scene.SceneDef = {
    name = "Title",
    init = init,
    finit = finit,
    update = process,
    draw = draw,
    gui = gui,
    next = {scene.SceneId(Screens.Main_Menu)},     // likely next: its assets start loading in the background
}

TITLE :: "Hellope!"

init :: proc() {
    state.g.background_color = karl2d.BLACK
}

finit :: proc() {}

process :: proc() {
    if input.is_any_key_released() {
        // state.change_game_state(screen_menu_state)
        Set(Screens.Main_Menu)
    }
}

draw :: proc() {
    // karl2d.clear(background_color)
}

gui :: proc() {
    window_size: = window.get_window_size()
    title_size:f32 = window_size.y * 0.25
    measure_title:Vec2 = karl2d.measure_text(TITLE, title_size, karl2d.FONT_DEFAULT)
    title_position:Vec2 = ui.GetElementPosition({0,0,window_size.x, window_size.y}, measure_title, {0.5, 0.3})
	karl2d.draw_text(TITLE, title_position, title_size, karl2d.DARK_BLUE)
}