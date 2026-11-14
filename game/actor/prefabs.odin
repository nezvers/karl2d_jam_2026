package actor

import karl2d "../karl2d"
import spr "../sprite"
import "../assets"
import "../scene"
import "../sfx"

CHAR_SIZE :spr.vec2: {16, 16}
// All positions on texture
tex_pos_char: []spr.vec2 = {{0,0}, {16,0}, {32,0}, {48,0}, {64,0}, {80,0}, {96,0}, {112,0}}
anim_char_idle: spr.Frames = {tex_pos_char[0:2], CHAR_SIZE}
anim_char_walk: spr.Frames = {tex_pos_char[2:8], CHAR_SIZE}
anim_char_up: spr.Frames = {tex_pos_char[5:6], CHAR_SIZE}
anim_char_down: spr.Frames = {tex_pos_char[7:8], CHAR_SIZE}

character_animations: spr.AnimationSet = {
    {&anim_char_idle, &anim_char_walk, &anim_char_up, &anim_char_down},
    cast(u32)ActorAnimations.char_idle, 0, 12, 0,
}

// Prefabs are data: a root value and patches over it, like an inherited scene. A child only says what is different.
// They are resolved ONCE (ResolvePrefabs, when the scene starts) into the plain values below, so spawning stays a struct copy.
// Each prefab lists the assets it needs, the scenes that use it wait for them (see scene.PrefabRegister).

// Abstract base: no texture of its own, nothing needs loading for it
def_character: scene.PrefabDef(Actor) = {
    value = {
        visuals = {
            animation_set = character_animations,
            position = {0, 0},
            origin = {8, 16},
            scale = {1, 1},
            rotation = 0.0,
            visible = true,
            tint = karl2d.WHITE,
        },
        properties = {
            acceleration = 3.0,
            deacceleration = 3.0,
            max_speed = 120.0,
        },
        health = {
            value = 100,
        },
        damage_sound = &sfx.damage,
        spawn_callback = nil,
        draw_callback = nil,
        update_callback = UpdateCharacter, // TODO: each character its specialized update
        type = .Player,
    },
}

def_plumber: scene.PrefabDef(Actor) = {
    base = &def_character,
    patches = {scene.PatchField(Actor, "texture_asset", assets.TEXTURE_PLUMBER)},
    assets = {assets.TEXTURE_PLUMBER},
}

def_electrician: scene.PrefabDef(Actor) = {
    base = &def_character,
    patches = {
        scene.PatchField(Actor, "texture_asset", assets.TEXTURE_ELECTRICIAN),
        scene.PatchField(Actor, "draw_callback", DrawElectricianCallback),
    },
    assets = {assets.TEXTURE_ELECTRICIAN},
}

def_zombie: scene.PrefabDef(Actor) = {
    base = &def_character,
    patches = {
        scene.PatchField(Actor, "texture_asset", assets.TEXTURE_ZOMBIE),
        scene.PatchField(Actor, "deacceleration", f32(1.0)),
        scene.PatchField(Actor, "max_speed", f32(20.0)),
        scene.PatchField(Actor, "damage_sound", (^sfx.SfxKarl2D)(nil)),
        scene.PatchField(Actor, "type", ActorType.Enemy),
    },
    assets = {assets.TEXTURE_ZOMBIE},
}

// The finished values, filled by ResolvePrefabs. enemies.Reset adjusts the zombie after that
prefab_plumber: Actor
prefab_electrician: Actor
prefab_zombie: Actor

// Ids of the prefab records in the scene system, in the order RegisterPrefabs adds them. Scenes list these
PREFAB_PLUMBER :: scene.PrefabId(0)
PREFAB_ELECTRICIAN :: scene.PrefabId(1)
PREFAB_ZOMBIE :: scene.PrefabId(2)

// Tell the scene system what each prefab needs, once when the game starts
RegisterPrefabs :: proc(system: ^scene.SceneSystem) {
    buffer: [scene.MAX_PREFAB_ASSETS]scene.AssetId
    id: scene.PrefabId = scene.PrefabRegister(system, scene.PrefabAssets(&def_plumber, buffer[:]))
    assert(id == PREFAB_PLUMBER)
    id = scene.PrefabRegister(system, scene.PrefabAssets(&def_electrician, buffer[:]))
    assert(id == PREFAB_ELECTRICIAN)
    id = scene.PrefabRegister(system, scene.PrefabAssets(&def_zombie, buffer[:]))
    assert(id == PREFAB_ZOMBIE)
}

// Base value plus patches into the values that are spawned from. A few copies, done when a scene starts
ResolvePrefabs :: proc() {
    scene.PrefabResolve(&def_plumber, &prefab_plumber)
    scene.PrefabResolve(&def_electrician, &prefab_electrician)
    scene.PrefabResolve(&def_zombie, &prefab_zombie)
}
