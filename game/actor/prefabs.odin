package actor

import karl2d "../karl2d"

import "../assets"
import "../scene"
import "../sfx"
import "../weapon"
import "../animations"

// Prefabs are data: a root value and patches over it, like an inherited scene. A child only says what is different.
// They are resolved ONCE (ResolvePrefabs, when the scene starts) into the plain values below, so spawning stays a struct copy.
// Each prefab lists the assets it needs, the scenes that use it wait for them (see scene.PrefabRegister).

// Abstract base: no texture of its own, nothing needs loading for it
def_character: scene.PrefabDef(Actor) = {
    value = {
        visuals = {
            animator = {sheet = animations.SHEET_CHARACTER, clip = animations.CHAR_IDLE, frame_rate = 12},
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
        damage_sound = sfx.DAMAGE,
        update_kind = .Character, // TODO: each character its specialized update
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
        scene.PatchField(Actor, "draw_kind", DrawKind.Electrician),
    },
    assets = {assets.TEXTURE_ELECTRICIAN},
}

def_zombie: scene.PrefabDef(Actor) = {
    base = &def_character,
    patches = {
        scene.PatchField(Actor, "texture_asset", assets.TEXTURE_ZOMBIE),
        scene.PatchField(Actor, "deacceleration", f32(1.0)),
        scene.PatchField(Actor, "max_speed", f32(20.0)),
        scene.PatchField(Actor, "damage_sound", sfx.NONE),
        scene.PatchField(Actor, "weapon", weapon.BITE),
        scene.PatchField(Actor, "type", ActorType.Enemy),
        scene.PatchField(Actor, "update_kind", UpdateKind.Zombie),
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
