package vfx

import karl2d "../karl2d"
import "../animations"
import "../assets"

// Effects are rows of this table, the code that makes them (a projectile hit) refers to them by Id
Id :: distinct u8
NONE :: Id(0)
IMPACT :: Id(1)
COUNT :: 2

prefabs: [COUNT]Vfx = {
    IMPACT = {
        sprite = {
            animator = {sheet = animations.SHEET_VFX, clip = 0, frame_rate = 12},
            origin = {8, 8},
            scale = {1, 1},
        },
        visible = true,
        tint = karl2d.WHITE,
        is_foreground = true,
        texture_asset = assets.TEXTURE_IMPACT,
    },
}
