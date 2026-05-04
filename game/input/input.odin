package input

import "../karl2d"
import "core:math"

is_any_key_held :: proc()->bool {
    for i:int=0; i < 349; i += 1 {
        if karl2d.key_is_held(cast(karl2d.Keyboard_Key)i){
            return true
        }
    }
    for i:int=0; i < 3; i += 1 {
        if karl2d.mouse_button_is_held(cast(karl2d.Mouse_Button)i){
            return true
        }
    }
    for gamepad:karl2d.Gamepad_Index=0; gamepad < karl2d.MAX_GAMEPADS; gamepad += 1 {
        if !karl2d.is_gamepad_active(gamepad) {continue}
        for button: = cast(karl2d.Gamepad_Button)0; button < karl2d.Gamepad_Button.Middle_Face_Right + cast(karl2d.Gamepad_Button)1; button += cast(karl2d.Gamepad_Button)1 {
            if karl2d.gamepad_button_is_held(gamepad, button) {
                return true
            }
        }
        for axis: = cast(karl2d.Gamepad_Axis)0; axis < karl2d.Gamepad_Axis.Right_Trigger + cast(karl2d.Gamepad_Axis)1; axis += cast(karl2d.Gamepad_Axis)1 {
            if math.abs(karl2d.get_gamepad_axis(gamepad, axis)) > 0.5 {
                return true
            }
        }
    }
    return false
}

is_any_key_released :: proc()->bool {
    for i:int=0; i < 349; i += 1 {
        if karl2d.key_went_up(cast(karl2d.Keyboard_Key)i){
            return true
        }
    }
    for i:int=0; i < 3; i += 1 {
        if karl2d.mouse_button_went_up(cast(karl2d.Mouse_Button)i){
            return true
        }
    }
    for gamepad:karl2d.Gamepad_Index=0; gamepad < karl2d.MAX_GAMEPADS; gamepad += 1 {
        if !karl2d.is_gamepad_active(gamepad) {continue}
        for button: = cast(karl2d.Gamepad_Button)0; button < karl2d.Gamepad_Button.Middle_Face_Right + cast(karl2d.Gamepad_Button)1; button += cast(karl2d.Gamepad_Button)1 {
            if karl2d.gamepad_button_went_up(gamepad, button) {
                return true
            }
        }
        // for axis: = cast(karl2d.Gamepad_Axis)0; axis < karl2d.Gamepad_Axis.Right_Trigger + cast(karl2d.Gamepad_Axis)1; axis += cast(karl2d.Gamepad_Axis)1 {
        //     if math.abs(karl2d.get_gamepad_axis(gamepad, axis)) > 0.5 {
        //         return true
        //     }
        // }
    }
    return false
}