package game_screens

import "core:slice"
import "../scene"
import state "../game_state"

Screens :: enum int {
    Title,
    Main_Menu,
    Gameplay,
}

// The scenes of the game: a table of data, indexed by Screens (a Screens value is the SceneId)
scenes: [Screens]scene.SceneDef = {
    .Title = screen_title_def,
    .Main_Menu = screen_menu_def,
    .Gameplay = screen_game_def,
}

// The table as a slice, what the scene system takes
List :: proc() -> []scene.SceneDef {
    return slice.enumerated_array(&scenes)
}

// The first scene
Start :: proc() {
    scene.SceneStart(&state.g.scene_system, scene.SceneId(Screens.Title))
}

// Go to a scene: at once when it is loaded already, else behind a transition
Set :: proc(index:Screens) {
    scene.SceneGoto(&state.g.scene_system, scene.SceneId(index))
}
