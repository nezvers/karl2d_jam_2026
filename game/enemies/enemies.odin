package enemies

import "../actor"
import "../perf"
import "core:math/rand"
import "../cool_math"
import "core:math"
// import "../projectile"

// import karl2d "../karl2d"
// import spr "../sprite"
// import spr_glue "../sprite/karl2d"

vec2 :: [2]f32

// MAX_ENEMIES :: 30
START_ENEMY_COUNT :: 200 when perf.PERF_STRESS else 20

// The procs of this package, given to the actors by number. Call it again after a hot reload: the table is a global of the code
Bind :: proc() {
    actor.update_procs[.Zombie] = UpdateZombie
}

Start :: proc() {
    Bind()
}

GetSpawnPoint :: proc()->vec2 {
    RANGE :: 200
    center:vec2 = actor.pool.buffer[0].position
    range:f32 = 100 + rand.float32() * RANGE
    angle:f32 = math.TAU * rand.float32()
    result:vec2 = center + cool_math.Vec2Rotate(vec2{1,0} * range, angle)
    return result
}

Update :: proc(delta_time:f32) {
    for i:int = actor.pool.count; i < (START_ENEMY_COUNT + 2); i += 1 {
        _, ok: = actor.NewInstance(actor.prefab_zombie, GetSpawnPoint())
        if !ok { continue }
    }
}

UpdateZombie :: proc(zombie: ^actor.Actor, delta_time: f32) {
    nearest:^actor.Actor = &actor.pool.buffer[0]
    distance:vec2 = nearest.position - zombie.position
    distance2:vec2 = actor.pool.buffer[1].position - zombie.position
    mag2: = cool_math.Vec2Mag2(distance)

    if mag2 > (300 * 300){
        actor.Remove(zombie)
        return
    }

    if mag2 > cool_math.Vec2Mag2(distance2) {
        nearest = &actor.pool.buffer[1]
        distance = distance2
        mag2 = cool_math.Vec2Mag2(distance)
    }

    zombie.move_dir = cool_math.Vec2Norm(distance)

    
    if mag2 > (50 * 50) {
        // Little spreading help at distance
        angle:f32 = cool_math.Vec2Angle(zombie.move_dir)
        sector_angle:f32 = math.round(angle/ (math.PI * 0.25))
        quantized_angle:f32 = sector_angle * (math.PI * 0.25)
        zombie.move_dir = cool_math.Vec2Rotate(vec2{1,0}, quantized_angle)
    }
    zombie.aim_dir = zombie.move_dir

    // attack range
    zombie.attack = mag2 < (25)

    actor.UpdateCharacter(zombie, delta_time)
}
