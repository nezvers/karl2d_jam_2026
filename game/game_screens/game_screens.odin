package game_screens

import state "../game_state"

list: []state.GameState = {
    screen_title_state,
}

SetScreen :: proc(index:int) {
    assert(index >= 0 && index < len(list))
    state.g.game_screen = index
    next: = list[index]
    state.change_game_state(next)
}