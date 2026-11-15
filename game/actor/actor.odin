package actor

// import spr "../sprite"
import spr_glue "../sprite/karl2d"
import "../assets"
import "../scene"
// import karl2d "../karl2d"
import "../weapon"
import "../sfx"
import "../animations"
import "core:sort"
// import "core:math/rand"

vec2 :: [2]f32
ActorType :: enum {
    Player =    1 << 0,
    Enemy =     1 << 2,
}

Input :: struct {
    move_dir:vec2,
    aim_dir:vec2,
    attack:bool,
}

Properties :: struct {
    acceleration: f32,
    deacceleration: f32,
    max_speed: f32,
}

State :: struct {
    velocity: vec2,
    attack_timer: f32,
}

Health :: struct {
    value: f32,
    timer: f32,
}

// Behaviour is chosen by number, not by a proc pointer: a pointer into the code is wrong after a hot reload, a number is not
UpdateKind :: enum u8 {
    None,
    Character,
    Zombie,     // set by the enemies package, which imports this one (see enemies.Bind)
}

DrawKind :: enum u8 {
    None,
    Electrician,
}

update_procs: [UpdateKind]proc(^Actor, f32) = {
    .None = nil,
    .Character = UpdateCharacter,
    .Zombie = nil,
}

draw_procs: [DrawKind]proc(^Actor) = {
    .None = nil,
    .Electrician = DrawElectricianCallback,
}

Actor :: struct {
    using visuals: spr_glue.SheetSpriteKarl2d,
    using input: Input,
    using properties: Properties,
    using state: State,
    health: Health,
    update_kind: UpdateKind,      // what the actor does each frame: a number, the procs are looked up in update_procs
    draw_kind: DrawKind,
    type:ActorType,
    id:int,
    weapon: weapon.Id,            // a row of weapon.prefabs, not a pointer: the actor stays plain data
    damage_sound: sfx.Id,
    texture_asset: scene.AssetId,   // looked up when drawn: a placeholder until the texture is loaded
}



// Actor Pool
MAX_ACTORS :: 32
// The actors are data in the game memory (a hot reload keeps them), the package works on the pool it is bound to
Pool :: struct {
    buffer: [MAX_ACTORS]Actor,
    count: int,
}
pool: ^Pool

Bind :: proc(actors: ^Pool) {
    pool = actors
}
// For Y sorting
sorted_list: [MAX_ACTORS]^Actor

Reset :: proc() {
    pool.count = 0
}

GetNew :: proc(preset:Actor)->(actor:^Actor, ok:bool) {
    if pool.count >= len(pool.buffer) {
        return
    }
    actor = &pool.buffer[pool.count]
    // sorted_list[pool.count] = actor
    actor^ = preset
    actor.id = pool.count
    pool.count += 1
    ok = true
    return
}

Remove :: proc(actor:^Actor) {
    if actor.id >= pool.count { return }
    if actor.id != pool.buffer[actor.id].id { return }
    if pool.count == 0 { return }
    if actor.id == pool.count - 1 {
        pool.count -= 1
        return
    }
    new_actor: ^Actor = &pool.buffer[pool.count - 1]
    new_actor.id = actor.id
    actor^ = new_actor^
    pool.count -= 1
}

NewInstance :: proc(preset:Actor, pos:vec2)->(actor:^Actor, ok:bool) {
    actor,ok = GetNew(preset)
    if !ok { return }
    actor.position = pos
    // TODO: spawn effect in actor
    return
}

Update :: proc(delta_time: f32) {
    actor:^Actor

    for i:int = pool.count -1; i > -1; i -= 1 {
        actor = &pool.buffer[i]
        update: proc(^Actor, f32) = update_procs[actor.update_kind]
        if update != nil { update(actor, delta_time) }
    }
}

Draw :: proc() {
    // TODO: optimize with removal
    for i:int = 0; i < pool.count; i += 1 {
        sorted_list[i] = &pool.buffer[i]
    }
    sort.quick_sort_proc(sorted_list[:pool.count], Ysort)

    for i:int = 0; i < pool.count; i += 1 {
        actor:^Actor = sorted_list[i]
        if actor.texture_asset != scene.ASSET_NONE { actor.visuals.texture = assets.Texture(actor.texture_asset) }
        spr_glue.DrawSheetSpriteKarl2d(animations.List(), &actor.visuals)
        draw: proc(^Actor) = draw_procs[actor.draw_kind]
        if draw != nil { draw(actor) }
    }
}

Ysort :: proc(a: ^Actor, b: ^Actor)->int {
    return (a.position.y > b.position.y) ? 1 : (a.position.y < b.position.y) ? -1 : 0
}