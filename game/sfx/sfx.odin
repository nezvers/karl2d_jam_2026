package sfx

// The sound effects of the game. An effect is a number (Id): prefabs, weapons and projectiles hold the id, not a pointer, so they are
// plain data that can be copied, overridden and saved, and nothing dangles after a hot reload.
//   settings      - the tuning of each effect, constant data
//   sound_assets  - which asset holds the sound, loaded in the background by the scene system
//   the state     - the current pitch and the time of the last trigger, a few bytes per effect, in the game memory (Bind)
// Playing an effect whose sound is not loaded yet does nothing, and does not use up its retrigger time.

import "../assets"
import "../karl2d"
import "../scene"
import scene_glue "../scene/karl2d"
import "../sound_effects"
import snd_glue "../sound_effects/karl2d"

Id :: sound_effects.SoundId
NONE :: sound_effects.SOUND_NONE
GUN :: Id(1)
DAMAGE :: Id(2)
IMPACT :: Id(3)
COUNT :: 4

settings: [COUNT]sound_effects.SoundSettings = {
    GUN = {
        volume = 0.7,
        pitch_rand_min = 0.9,
        pitch_rand_max = 1.2,
        pitch_min = 0.5,
        pitch_max = 1.75,
        pitch_increment = 0.01,     // Pitch change on fast retrigger
        retrigger_treshold = 0.02,  // Don't play if sooner than this
        retrigger_interval = 0,     // Applay pitch_increment
        pitch_return = 0,           // Return to starting pitch
    },
    DAMAGE = {
        volume = 0.7,
        pitch_rand_min = 0.9,
        pitch_rand_max = 1.2,
        pitch_min = 0.5,
        pitch_max = 1.75,
        pitch_increment = 0.01,
        retrigger_treshold = 0.02,
        retrigger_interval = 0,
        pitch_return = 0,
    },
    IMPACT = {
        volume = 1,
        pitch_rand_min = 0.9,
        pitch_rand_max = 1.2,
        pitch_min = 0.5,
        pitch_max = 1.75,
        pitch_increment = 0.01,
        retrigger_treshold = 0.02,
        retrigger_interval = 0,
        pitch_return = 0,
    },
}

sound_assets: [COUNT]scene.AssetId = {
    GUN = assets.SOUND_GUN,
    DAMAGE = assets.SOUND_DAMAGE,
    IMPACT = assets.SOUND_IMPACT,
}

bank: sound_effects.SoundBank

// Use the states in the game memory. A global of the code is lost with the code, so call this again after a hot reload:
// the states are kept, the settings are the ones of the new code
Bind :: proc(states: []sound_effects.SoundState) {
    bank = {settings = settings[:], states = states}
}

Play :: proc(id: Id) {
    if id == NONE { return }
    clip, loaded := scene_glue.AudioClipOf(assets.store, sound_assets[id])
    if !loaded { return }       // not loaded yet: no sound, no crash, and the effect keeps its retrigger time
    snd_glue.PlayBank(&bank, id, clip, karl2d.get_time())
}
