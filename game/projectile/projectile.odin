package projectile

import spr "../sprite"
import "../animations"
import spr_glue "../sprite/karl2d"
import karl2d "../karl2d"
import "core:math/rand"
import "../cool_math"
import "../vfx"
import "../sfx"
import "../assets"
import "../scene"
// import "core:math"

vec2 :: [2]f32

Properties :: struct {
    speed: f32,
    kickback: f32,
    damping: f32,
    collide: u32,
    damage: f32,
    stay:bool,
    dont_rotate: bool,
}

State :: struct {
    velocity: karl2d.Vec2,
    move_dir: karl2d.Vec2,
    lifetime: f32,
}

Projectile :: struct {
    using state: State,
    using visual: spr_glue.SheetSpriteKarl2d,
    using properties: Properties,
    vfx_impact: vfx.Id,
    sfx_impact: sfx.Id,
    id:int,
    texture_asset: scene.AssetId,
}

MAX_PROJECTILES :: 512
// Data in the game memory, the package works on the pool it is bound to
Pool :: struct {
    buffer: [MAX_PROJECTILES]Projectile,
    count: int,
}
pool: ^Pool

Bind :: proc(projectiles: ^Pool) {
    pool = projectiles
}


Reset :: proc() {
    pool.count = 0
}

GetNew :: proc(preset: Projectile)->(projectile: ^Projectile, ok:bool) {
    if pool.count == MAX_PROJECTILES { return }
    projectile = &pool.buffer[pool.count]
    projectile^ = preset
    projectile.id = pool.count
    ok = true
    pool.count += 1
    return
}

Remove :: proc(projectile: ^Projectile) {
    if projectile.id >= pool.count { return }
    if projectile.id != pool.buffer[projectile.id].id { return }
    if pool.count == 0 { return }
    if projectile.id == pool.count - 1 {
        pool.count -= 1
        return
    }
    new_projectile: ^Projectile = &pool.buffer[pool.count - 1]
    new_projectile.id = projectile.id
    pool.buffer[projectile.id] = new_projectile^
    pool.count -= 1
}

Update :: proc(delta_time: f32) {
    for i:int = pool.count - 1; i > -1; i -= 1 {
        UpdateInstance(&pool.buffer[i], delta_time)
    }
}

UpdateInstance :: proc(projectile: ^Projectile, delta_time: f32) {
    if projectile.lifetime <= 0 {
        Remove(projectile)
        return
    }
    spr.SheetSpriteUpdate(animations.List(), &projectile.sprite, delta_time)
    projectile.lifetime -= delta_time
    projectile.position += projectile.velocity * delta_time
    projectile.velocity -= projectile.velocity * projectile.damping
    // TODO: collision check
}

Draw :: proc() {
    active_pool: = pool.buffer[:pool.count]
    for &projectile in active_pool {
        if projectile.texture_asset != scene.ASSET_NONE { projectile.texture = assets.Texture(projectile.texture_asset) }
        spr_glue.DrawSheetSprite(animations.List(), &projectile.sprite, projectile.texture, projectile.tint)
    }
}

SpawnProjectile :: proc(preset:Projectile, position:vec2, dir:vec2, spread:f32)->(inst: ^Projectile, ok:bool) {
    inst, ok = GetNew(preset)
    if !ok { return }
    inst.position = position
    inst.move_dir = cool_math.Vec2Rotate(dir, -spread + rand.float32() * spread * 2)
    inst.velocity = inst.move_dir * inst.speed
    if !preset.dont_rotate{
        inst.rotation = cool_math.Vec2Angle(inst.move_dir)
    }
    return
}