package vfx

import spr "../sprite"
import spr_glue "../sprite/karl2d"
import karl2d "../karl2d"


vec2 :: [2]f32

Vfx :: struct {
    using visual: spr_glue.SpriteKarl2d,
    is_foreground:bool,
    id:int,
}

MAX_VFX :: 512
background_pool: [MAX_VFX]Vfx
foreground_pool: [MAX_VFX]Vfx
bg_count:int
fg_count:int


Reset :: proc() {
    bg_count = 0
    fg_count = 0
}

GetNewBg :: proc(preset: Vfx)->(vfx: ^Vfx, ok:bool) {
    if bg_count == MAX_VFX { return }
    vfx = &background_pool[bg_count]
    vfx^ = preset
    vfx.id = bg_count
    ok = true
    bg_count += 1
    return
}

GetNewFg :: proc(preset: Vfx)->(inst: ^Vfx, ok:bool) {
    if fg_count == MAX_VFX { return }
    inst = &foreground_pool[fg_count]
    inst^ = preset
    inst.id = fg_count
    ok = true
    fg_count += 1
    return
}

NewInstance :: proc(preset:Vfx, pos:vec2)->(inst:^Vfx, ok:bool) {
    if preset.is_foreground {
        inst, ok = GetNewFg(preset)
    } else {
        inst, ok = GetNewBg(preset)
    }
    if !ok { return }
    inst.position = pos

    return
}

Remove :: proc(inst: ^Vfx) {
    if inst.is_foreground {
        RemoveFG(inst)
        return
    }
    RemoveBG(inst)
}

RemoveBG :: proc(inst: ^Vfx){
    if inst.id >= bg_count { return }
    if inst.id != background_pool[inst.id].id { return }
    if bg_count == 0 { return }
    if inst.id == bg_count - 1 {
        bg_count -= 1
        return
    }
    new_inst: ^Vfx = &background_pool[bg_count - 1]
    new_inst.id = inst.id
    background_pool[inst.id] = new_inst^
    bg_count -= 1
}

RemoveFG :: proc(inst: ^Vfx){
    if inst.id >= fg_count { return }
    if inst.id != foreground_pool[inst.id].id { return }
    if fg_count == 0 { return }
    if inst.id == fg_count - 1 {
        fg_count -= 1
        return
    }
    new_inst: ^Vfx = &foreground_pool[fg_count - 1]
    new_inst.id = inst.id
    foreground_pool[inst.id] = new_inst^
    fg_count -= 1
}

Update :: proc(delta_time:f32) {
    for i:int = fg_count - 1; i > -1; i -= 1 {
        if !UpdateAnimation(&foreground_pool[i].animation_set, delta_time) { continue }
        RemoveFG(&foreground_pool[i])
    }

    for i:int = bg_count - 1; i > -1; i -= 1 {
        if !UpdateAnimation(&background_pool[i].animation_set, delta_time) { continue }
        RemoveBG(&background_pool[i])
    }
}

UpdateAnimation::proc(animation_set:^spr.AnimationSet, delta_time:f32)->(wrap:bool) {
    animation_set.time += delta_time * animation_set.frame_rate
    if animation_set.time < 1 {
        return
    }
    image_count:int = len(animation_set.frames[animation_set.animation_index].data)
    increment:u32 = cast(u32)animation_set.time
    animation_set.time -= cast(f32)increment
    animation_set.image_index = (animation_set.image_index + increment)
    if animation_set.image_index < cast(u32)image_count {
        return
    }
    animation_set.image_index = cast(u32)image_count - 1
    wrap = true
    return
}

DrawBackground :: proc() {
    for i:int = bg_count - 1; i > -1; i -= 1 {
        vfx: ^Vfx = &background_pool[i]
        DrawInstance(vfx)
    }
}

DrawForeground :: proc() {
    for i:int = fg_count - 1; i > -1; i -= 1 {
        vfx: ^Vfx = &foreground_pool[i]
        DrawInstance(vfx)
    }
}

DrawInstance::proc(inst: ^Vfx){
    spr_glue.DrawSprite(&inst.sprite, inst.texture, inst.tint)
}