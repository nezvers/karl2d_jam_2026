package game_screens

import state "../game_state"

list: []state.GameState = {
    screen_title_state,
    screen_menu_state,
    screen_game_state,
}

Screens :: enum int {
    Title,
    Main_Menu,
    Gameplay,
}

Set :: proc(index:Screens) {
    assert(int(index) >= 0 && int(index) < len(list))
    state.g.game_screen = int(index)
    next: = list[index]
    state.change_game_state(next)
}