package weapon

import projectile "../projectile"
import spr_glue "../sprite/karl2d"
import "../sfx"
import "../assets"
import "../scene"
// import "core:math"

Properties :: struct {
    spread: f32,
    fire_rate: f32,
    count: u32,
    kickback: f32,
    angles: []f32,
}

Weapon :: struct {
    using visual: spr_glue.SpriteKarl2d,
    using properties: Properties,
    bullet: ^projectile.Projectile, 
    sound: ^sfx.SfxKarl2D,
    name: string,
    texture_asset: scene.AssetId,
}

DrawInstance::proc(weapon: ^Weapon){
    if weapon.texture_asset != scene.ASSET_NONE { weapon.texture = assets.Texture(weapon.texture_asset) }
    spr_glue.DrawSprite(&weapon.sprite, weapon.texture, weapon.tint)
}