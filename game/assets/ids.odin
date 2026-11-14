package assets

// The asset table of the game: one row per asset, data only. The scene system loads rows in the background,
// scenes and prefabs list the ids they need (see game_screens and actor/prefabs.odin).
// Bytes are embedded (see assets.odin), so the same table works in the browser.

import "../karl2d"
import "../scene"
import glue "../scene/karl2d"

Id :: scene.AssetId

NONE :: Id(0)
TEXTURE_PLUMBER :: Id(1)
TEXTURE_ELECTRICIAN :: Id(2)
TEXTURE_ZOMBIE :: Id(3)
TEXTURE_SHOTGUN :: Id(4)
TEXTURE_BULLET :: Id(5)
TEXTURE_BITE :: Id(6)
TEXTURE_IMPACT :: Id(7)
SOUND_GUN :: Id(8)
SOUND_DAMAGE :: Id(9)
SOUND_IMPACT :: Id(10)
MUSIC_DEEPER_DUNGEON :: Id(11)
COUNT :: 12

PREMULTIPLY :: glue.FLAG_PREMULTIPLY_ALPHA

// Not a constant: the placeholders are set when the game starts
defs: [COUNT]scene.AssetDef = {
    TEXTURE_PLUMBER = {name = "plumber", kind = glue.KIND_TEXTURE, source = texture_char_plumber, flags = PREMULTIPLY},
    TEXTURE_ELECTRICIAN = {name = "electrician", kind = glue.KIND_TEXTURE, source = texture_char_electrician, flags = PREMULTIPLY},
    TEXTURE_ZOMBIE = {name = "zombie", kind = glue.KIND_TEXTURE, source = texture_char_zomby_walker, flags = PREMULTIPLY},
    TEXTURE_SHOTGUN = {name = "shotgun", kind = glue.KIND_TEXTURE, source = texture_weapon_shotgun, flags = PREMULTIPLY},
    TEXTURE_BULLET = {name = "bullet", kind = glue.KIND_TEXTURE, source = texture_projectile_bullet1, flags = PREMULTIPLY},
    TEXTURE_BITE = {name = "bite", kind = glue.KIND_TEXTURE, source = texture_projectile_bite, flags = PREMULTIPLY},
    TEXTURE_IMPACT = {name = "impact", kind = glue.KIND_TEXTURE, source = texture_vfx_impact, flags = PREMULTIPLY},
    SOUND_GUN = {name = "gun", kind = glue.KIND_AUDIO_CLIP, source = sound_gun1},
    SOUND_DAMAGE = {name = "damage", kind = glue.KIND_AUDIO_CLIP, source = sound_damage},
    SOUND_IMPACT = {name = "impact sound", kind = glue.KIND_AUDIO_CLIP, source = sound_impact},
    MUSIC_DEEPER_DUNGEON = {name = "deeper dungeon", kind = glue.KIND_AUDIO_STREAM, source = music_deeper_dungeon},
}

// The store of the running game. Set again by Bind after a hot reload, a global of the code is lost with the code
store: ^scene.AssetStore

// Use the store and give the texture assets their placeholder (a small checker): a sprite that is drawn before its texture is loaded
// shows that instead of nothing
Bind :: proc(asset_store: ^scene.AssetStore, placeholder_texture: scene.AssetValue) {
    store = asset_store
    glue.SetPlaceholders(defs[:], glue.KIND_TEXTURE, placeholder_texture)
}

// The texture of an asset: the real one when it is loaded, the placeholder before that
Texture :: proc(id: Id) -> karl2d.Texture {
    return glue.TextureOf(store, id)
}
