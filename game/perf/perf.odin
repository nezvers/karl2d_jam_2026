package perf

// TEMPORARY measurements of the running game. Build with -define:PERF_TEST=true:
//   the players cannot be damaged, the shotgun has no kickback, the second player shoots at the nearest zombie all the time,
//   and once a second the frame times and the counts of things are printed (main_release writes stdout to log.txt)

import "core:time"

PERF_TEST :: #config(PERF_TEST, false)
// The game stops after this many seconds so a run ends by itself
PERF_STRESS :: #config(PERF_STRESS, false)   // 200 zombies and a 6 times faster shotgun
PERF_SECONDS :: #config(PERF_SECONDS, 120)

// counters filled by the game, printed and cleared once a second
sfx_asked: int          // sfx.Play calls
sfx_played: int         // calls that reached the audio
vfx_spawned: int
projectiles_spawned: int

Window :: struct {
    start: time.Tick,
    frames: int,
    work_sum: f64,      // ms of update + draw, without present
    work_max: f64,
    update_max: f64,
    draw_max: f64,
    present_max: f64,
    frame_max: f64,     // ms between two frames
    last_frame: time.Tick,
}
window: Window
run_start: time.Tick
