package vfx

import spr "../sprite"
import "../animations"
import spr_glue "../sprite/karl2d"
import "../assets"
import "../scene"


vec2 :: [2]f32

Vfx :: struct {
    using visual: spr_glue.SheetSpriteKarl2d,
    is_foreground:bool,
    id:int,
    texture_asset: scene.AssetId,
}

MAX_VFX :: 512
// Data in the game memory, the package works on the pool it is bound to
Pool :: struct {
    background: [MAX_VFX]Vfx,
    foreground: [MAX_VFX]Vfx,
    bg_count: int,
    fg_count: int,
}
pool: ^Pool

Bind :: proc(effects: ^Pool) {
    pool = effects
}


Reset :: proc() {
    pool.bg_count = 0
    pool.fg_count = 0
}

GetNewBg :: proc(preset: Vfx)->(vfx: ^Vfx, ok:bool) {
    if pool.bg_count == MAX_VFX { return }
    vfx = &pool.background[pool.bg_count]
    vfx^ = preset
    vfx.id = pool.bg_count
    ok = true
    pool.bg_count += 1
    return
}

GetNewFg :: proc(preset: Vfx)->(inst: ^Vfx, ok:bool) {
    if pool.fg_count == MAX_VFX { return }
    inst = &pool.foreground[pool.fg_count]
    inst^ = preset
    inst.id = pool.fg_count
    ok = true
    pool.fg_count += 1
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
    if inst.id >= pool.bg_count { return }
    if inst.id != pool.background[inst.id].id { return }
    if pool.bg_count == 0 { return }
    if inst.id == pool.bg_count - 1 {
        pool.bg_count -= 1
        return
    }
    new_inst: ^Vfx = &pool.background[pool.bg_count - 1]
    new_inst.id = inst.id
    pool.background[inst.id] = new_inst^
    pool.bg_count -= 1
}

RemoveFG :: proc(inst: ^Vfx){
    if inst.id >= pool.fg_count { return }
    if inst.id != pool.foreground[inst.id].id { return }
    if pool.fg_count == 0 { return }
    if inst.id == pool.fg_count - 1 {
        pool.fg_count -= 1
        return
    }
    new_inst: ^Vfx = &pool.foreground[pool.fg_count - 1]
    new_inst.id = inst.id
    pool.foreground[inst.id] = new_inst^
    pool.fg_count -= 1
}

Update :: proc(delta_time:f32) {
    for i:int = pool.fg_count - 1; i > -1; i -= 1 {
        if !spr.AnimatorUpdateOnce(animations.List(), &pool.foreground[i].sprite.animator, delta_time) { continue }
        RemoveFG(&pool.foreground[i])
    }

    for i:int = pool.bg_count - 1; i > -1; i -= 1 {
        if !spr.AnimatorUpdateOnce(animations.List(), &pool.background[i].sprite.animator, delta_time) { continue }
        RemoveBG(&pool.background[i])
    }
}

DrawBackground :: proc() {
    for i:int = pool.bg_count - 1; i > -1; i -= 1 {
        vfx: ^Vfx = &pool.background[i]
        DrawInstance(vfx)
    }
}

DrawForeground :: proc() {
    for i:int = pool.fg_count - 1; i > -1; i -= 1 {
        vfx: ^Vfx = &pool.foreground[i]
        DrawInstance(vfx)
    }
}

DrawInstance::proc(inst: ^Vfx){
    if inst.texture_asset != scene.ASSET_NONE { inst.texture = assets.Texture(inst.texture_asset) }
    spr_glue.DrawSheetSprite(animations.List(), &inst.sprite, inst.texture, inst.tint)
}