package sfx

import "../assets"
import "../karl2d"
import "../sound_effects"
import "../scene"
import scene_glue "../scene/karl2d"
import snd_glue "../sound_effects/karl2d"
SfxKarl2D :: snd_glue.SfxKarl2D

settings_gun1: sound_effects.SoundEffect = {
    volume = 0.7,
    pitch_rand_min = 0.9,
    pitch_rand_max = 1.2,
    pitch_min = 0.5,
    pitch_max = 1.75,
    pitch_increment = 0.01,     // Pitch change on fast retrigger
    retrigger_treshold = 0.02,  // Don't play if sooner than this
    retrigger_interval = 0,     // Applay pitch_increment
    pitch_return = 0,           // Return to starting pitch
}

settings_damage: sound_effects.SoundEffect = {
    volume = 0.7,
    pitch_rand_min = 0.9,
    pitch_rand_max = 1.2,
    pitch_min = 0.5,
    pitch_max = 1.75,
    pitch_increment = 0.01,     // Pitch change on fast retrigger
    retrigger_treshold = 0.02,  // Don't play if sooner than this
    retrigger_interval = 0,     // Applay pitch_increment
    pitch_return = 0,           // Return to starting pitch
}

settings_impact: sound_effects.SoundEffect = {
    volume = 1,
    pitch_rand_min = 0.9,
    pitch_rand_max = 1.2,
    pitch_min = 0.5,
    pitch_max = 1.75,
    pitch_increment = 0.01,     // Pitch change on fast retrigger
    retrigger_treshold = 0.02,  // Don't play if sooner than this
    retrigger_interval = 0,     // Applay pitch_increment
    pitch_return = 0,           // Return to starting pitch
}

clip_gun1: karl2d.Audio_Clip
clip_damage: karl2d.Audio_Clip
clip_impact: karl2d.Audio_Clip

gun: SfxKarl2D
damage: SfxKarl2D
impact: SfxKarl2D   // Projectile.sfx_impact

// Point the sound effects at the clips that the scene system loaded. Call when the scene that needs the sounds starts, they
// are required by it. A clip that is not there keeps a null effect: Play skips it
Bind :: proc() {
    gun = bind_clip(&settings_gun1, &clip_gun1, assets.SOUND_GUN)
    damage = bind_clip(&settings_damage, &clip_damage, assets.SOUND_DAMAGE)
    impact = bind_clip(&settings_impact, &clip_impact, assets.SOUND_IMPACT)
}

@(private="file")
bind_clip :: proc(settings: ^sound_effects.SoundEffect, clip: ^karl2d.Audio_Clip, id: scene.AssetId) -> SfxKarl2D {
    ready: bool
    clip^, ready = scene_glue.AudioClipOf(assets.store, id)
    if !ready { return {} }
    return snd_glue.Init(settings, clip)
}

Play :: proc(sound: ^SfxKarl2D) {
    if sound.clip == nil { return }     // not loaded: no sound, no crash
    snd_glue.PlaySfxKarl2D(sound, karl2d.get_time())
}