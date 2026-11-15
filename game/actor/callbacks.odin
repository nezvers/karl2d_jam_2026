package actor


import spr "../sprite"
import "../animations"
import "../weapon"
import "../sfx"
import "../cool_math"
import "../projectile"
import "../perf"

LerpVelocity :: proc(from, to: vec2, t:f32)->vec2 {
    return from + (to - from) * t
}

UpdateCharacter :: proc(actor: ^Actor, delta_time:f32) {
    is_moving:bool = (actor.move_dir.x * actor.move_dir.x) + (actor.move_dir.y * actor.move_dir.y) > 0.01
    if is_moving {
        actor.velocity = LerpVelocity(actor.velocity, actor.move_dir * actor.max_speed, actor.acceleration * delta_time)
    } else {
        actor.velocity = LerpVelocity(actor.velocity, 0, actor.deacceleration * delta_time)
    }

    // Flip
    if actor.aim_dir.x > 0.01 {
        actor.scale.x = 1
    } else if actor.aim_dir.x < -0.01 {
        actor.scale.x = -1
    }
    UpdateAnimation(&actor.sprite.animator, is_moving)
    spr.SheetSpriteUpdate(animations.List(), &actor.sprite, delta_time)

    actor.position += actor.velocity * delta_time

    if actor.weapon != weapon.NONE { UpdateActorWeapon(actor, delta_time) }
}


UpdateActorWeapon :: proc(actor: ^Actor, delta_time: f32) {
    current: ^weapon.Weapon = &weapon.prefabs[actor.weapon]
    if !actor.attack {
        actor.attack_timer += current.fire_rate * delta_time
        if actor.attack_timer > 1 { 
            actor.attack_timer = 1
        }
        return
    }
    fire_rate: f32 = current.fire_rate * (6 if perf.PERF_STRESS else 1)
    actor.attack_timer += fire_rate * delta_time
    if actor.attack_timer < 1 { return }

    count:i32 = i32(actor.attack_timer)
    actor.attack_timer -= f32(count)
    for i:i32 = 0; i < count; i += 1 {
        when !perf.PERF_TEST { actor.velocity += delta_time * current.kickback * -actor.aim_dir }
        for angle in current.angles[:current.angle_count] {
            SPAWN_DIST :: 5
            pos: vec2 = actor.position + actor.aim_dir * SPAWN_DIST
            dir:vec2 = cool_math.Vec2Rotate(actor.aim_dir, angle)
            inst, ok: = projectile.SpawnProjectile(projectile.prefabs[current.bullet], pos, dir, current.spread)
            if !ok { continue }
            inst.collide = ~cast(u32)actor.type
        }
        sfx.Play(current.sound)
        // if i < 1 { continue }
        // TODO: pre-heat projectile update by fire_rate
    }
}

UpdateAnimation :: proc(animator: ^spr.Animator, is_walking: bool) {
    if is_walking == (animator.clip == animations.CHAR_WALK) {
        return
    }
    spr.AnimatorChange(animator, animations.CHAR_WALK if is_walking else animations.CHAR_IDLE)
}

DrawElectricianCallback :: proc(actor_ptr: ^Actor) {
    // Keep assigned weapon as reference data.
    if actor_ptr.weapon == weapon.NONE { return }
    weapon_copy: = weapon.prefabs[actor_ptr.weapon]
    weapon_copy.position = actor_ptr.position + {0, -5}
    weapon_copy.rotation = cool_math.Vec2Angle(actor_ptr.aim_dir)
    
    if actor_ptr.aim_dir.x < 0 {
        weapon_copy.scale.y = -1
        // weapon_copy.origin.y = -weapon_copy.origin.y + 16
    }
    weapon.DrawInstance(&weapon_copy)
    
    // karl2d.draw_circle_outline(mouse_position, 3, 1, karl2d.LIGHT_GRAY)
}