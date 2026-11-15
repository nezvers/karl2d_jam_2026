package weapon

import "../animations"
import "../projectile"
import "../sfx"
import "../assets"
import karl2d "../karl2d"
import "core:math"

// Templates, constant data: the texture is looked up from the asset when drawn
prefabs: [COUNT]Weapon = {
    SHOTGUN = {
        properties = {
            spread = math.PI * 0.015,
            fire_rate = 2,
            count = 5,
            kickback = 2000,
            angles = {-math.PI * 0.1, -math.PI * 0.05, 0, math.PI * 0.1, math.PI * 0.05},
            angle_count = 5,
        },
        sprite = {
            animator = {sheet = animations.SHEET_WEAPON},
            origin = {8, 8},
            scale = {1, 1},
        },
        bullet = projectile.BULLET,
        sound = sfx.GUN,
        visible = true,
        tint = karl2d.WHITE,
        name = "Shotgun",
        texture_asset = assets.TEXTURE_SHOTGUN,
    },
    BITE = {
        properties = {
            spread = math.PI * 0.015,
            fire_rate = 2,
            count = 5,
            kickback = 2000,
            angles = {0, 0, 0, 0, 0},
            angle_count = 1,
        },
        sprite = {
            animator = {sheet = animations.SHEET_WEAPON},
            origin = {8, 8},
            scale = {1, 1},
        },
        bullet = projectile.BITE,
        visible = false,
        tint = karl2d.WHITE,
        name = "Bite",
    },
}
