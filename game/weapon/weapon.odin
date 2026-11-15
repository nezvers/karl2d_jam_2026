package weapon

import projectile "../projectile"
import spr_glue "../sprite/karl2d"
import "../animations"
import "../sfx"
import "../assets"
import "../scene"

// A weapon is a row of prefabs (prefabs.odin), actors refer to it by Id. It holds ids and numbers only, no pointers
Id :: distinct u8
NONE :: Id(0)
SHOTGUN :: Id(1)
BITE :: Id(2)
COUNT :: 3

MAX_ANGLES :: 5

Properties :: struct {
    spread: f32,
    fire_rate: f32,
    count: u32,
    kickback: f32,
    angles: [MAX_ANGLES]f32,
    angle_count: u8,
}

Weapon :: struct {
    using visual: spr_glue.SheetSpriteKarl2d,
    using properties: Properties,
    bullet: projectile.Id,
    sound: sfx.Id,
    name: string,
    texture_asset: scene.AssetId,
}

DrawInstance::proc(weapon: ^Weapon){
    if weapon.texture_asset != scene.ASSET_NONE { weapon.texture = assets.Texture(weapon.texture_asset) }
    spr_glue.DrawSheetSprite(animations.List(), &weapon.sprite, weapon.texture, weapon.tint)
}
