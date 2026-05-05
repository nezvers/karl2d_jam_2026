package weapon

import spr "../sprite"
import projectile "../projectile"
import spr_glue "../sprite/karl2d"
import karl2d "../karl2d"
import "../sfx"
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
}

DrawInstance::proc(weapon: ^Weapon){
    spr_glue.DrawSprite(&weapon.sprite, weapon.texture, weapon.tint)
}