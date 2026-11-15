package animations

// The animation data of the game: one table of sheets that every sprite of the game refers to by number. Where the frames are on a
// texture and which frames make a clip is data here, a sprite instance only holds numbers (see sprite/sheet.odin), so prefabs that
// contain a sprite can be copied, overridden field by field and saved.

import spr "../sprite"

SHEET_CHARACTER :: spr.SheetId(0)
SHEET_WEAPON :: spr.SheetId(1)
SHEET_PROJECTILE :: spr.SheetId(2)
SHEET_VFX :: spr.SheetId(3)

// clips of SHEET_CHARACTER
CHAR_IDLE :: u16(0)
CHAR_WALK :: u16(1)
CHAR_UP :: u16(2)
CHAR_DOWN :: u16(3)

// clips of SHEET_PROJECTILE
PROJECTILE_BULLET :: u16(0)
PROJECTILE_BITE :: u16(1)

// A strip of 16x16 frames, the textures are all laid out this way
@(private)
strip: [8]spr.vec2 = {{0, 0}, {16, 0}, {32, 0}, {48, 0}, {64, 0}, {80, 0}, {96, 0}, {112, 0}}
@(private)
weapon_frame: [1]spr.vec2 = {{0, 0}}

@(private)
character_clips: [4]spr.Clip = {{0, 2}, {2, 6}, {5, 1}, {7, 1}}     // idle, walk, up, down
@(private)
weapon_clips: [1]spr.Clip = {{0, 1}}
@(private)
projectile_clips: [2]spr.Clip = {{0, 1}, {0, 5}}                     // bullet, bite
@(private)
vfx_clips: [1]spr.Clip = {{0, 6}}

sheets: [4]spr.Sheet = {
    SHEET_CHARACTER = {frame_size = {16, 16}, frames = strip[:], clips = character_clips[:]},
    SHEET_WEAPON = {frame_size = {16, 16}, frames = weapon_frame[:], clips = weapon_clips[:]},
    SHEET_PROJECTILE = {frame_size = {16, 16}, frames = strip[:], clips = projectile_clips[:]},
    SHEET_VFX = {frame_size = {16, 16}, frames = strip[:], clips = vfx_clips[:]},
}

// The table as a slice, what the drawing and update procs take
List :: proc() -> []spr.Sheet {
    return sheets[:]
}
