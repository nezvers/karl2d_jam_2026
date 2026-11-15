package projectile

import karl2d "../karl2d"
import "../animations"
import "../vfx"
import "../assets"
import "../sfx"

// Projectiles are rows of this table, weapons refer to them by Id
Id :: distinct u8
NONE :: Id(0)
BULLET :: Id(1)
BITE :: Id(2)
COUNT :: 3

// Templates, constant data: the texture is looked up from the asset when drawn
prefabs: [COUNT]Projectile = {
    BULLET = {
        texture_asset = assets.TEXTURE_BULLET,
        state = {
            lifetime = 0.5,
        },
        properties = {
            kickback = 200,
            speed = 240,
            damping = 0.05,
            damage = 50.0,
        },
        sprite = {
            animator = {sheet = animations.SHEET_PROJECTILE, clip = animations.PROJECTILE_BULLET},
            origin = {8, 8},
            scale = {1, 1},
            offset = {0, -7},
        },
        visible = true,
        tint = karl2d.WHITE,
        vfx_impact = vfx.IMPACT,
        sfx_impact = sfx.IMPACT,
    },
    BITE = {
        texture_asset = assets.TEXTURE_BITE,
        state = {
            lifetime = 0.42,
        },
        properties = {
            kickback = 100,
            speed = 0,
            damping = 0.05,
            damage = 10.0,
            stay = true,
            dont_rotate = true,
        },
        sprite = {
            animator = {sheet = animations.SHEET_PROJECTILE, clip = animations.PROJECTILE_BITE, frame_rate = 12},
            origin = {8, 8},
            scale = {1, 1},
            offset = {0, -7},
        },
        visible = true,
        tint = karl2d.WHITE,
    },
}
