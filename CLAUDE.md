# karl2d_jam_2026 (Rope and Shotgun)

Jam game on Karl2D with the hot reload template. Git repo nezvers/karl2d_jam_2026 (`master`; `perf-harness` holds the performance
measurement code, see below). Parent: `../../CLAUDE.md`. Libraries are mine from `../../odin_utilities`, see its CLAUDE.md for style.

## Layout
- `game/` the game as one package built into a DLL for hot reload: `game.odin` (entry procs, `Game_Memory`), `game_state/` (`Game_Memory` and shared state), `game_screens/` (title, menu, gameplay), `actor/` (actors, prefabs, callbacks), `enemies/`, `weapon/`, `projectile/`, `vfx/`, `sfx/`, `animations/`, `input/`, `window/`, `ui/`.
- `game/karl2d` is a directory junction to the fork (`../../odin_plug/karl2d`), git ignored.
- `game/sprite`, `game/sound_effects`, `game/scene`, `game/cool_math`, `game/viewport_rect` are copies of odin_utilities libraries (`scene` without its tests). They are not synced: they still have the old `raylib/`/`karl2d/` glue dir names and lack later library fixes (sound_effects first trigger pitch). Port a fix by copying by hand.
- `main_hot_reload/`, `main_release/`, `main_web/` are the three executables over the same `game` package; `build.odin` builds the DLL and starts or reloads the hot reload exe; `hot_reload_test/` tests the reload mechanism.
- `assets/`, `bin/` (git ignored outputs).

## Commands (run in this folder)
- `odin run .` builds the game DLL; with `game_hot_reload.exe` running it reloads the DLL, otherwise it starts it. Windows only.
- `odin run main_release` / `odin build main_release`: release build. `odin run game/karl2d/build_web -- main_web`: web build in `main_web/bin`.
- `odin run hot_reload_test`: opens the game for a few seconds and checks memory is kept or rebuilt for same layout, other size, other layout, a half written DLL, the restart key and leaks at exit.

## Architecture rules
- Gameplay state lives in `Game_Memory` (allocated by the game, survives a reload when the layout hash matches). A layout change rebuilds it ("State recreated" notice). Scenes use `SceneDef.resume` to continue after a reload.
- Hot reload keys: F6 soft recreate (keeps the screen), Shift+F6 hard restart. A reload shows a fading notice ("Code reloaded", "Restarted", "State recreated").
- Camera and window refit go through `window.refresh()`.
- Data driven: actors are built from prefabs (`actor/prefabs.odin`) with callbacks, scenes come from the `scene` library tables.
- Nothing allocates per frame; use arenas or fixed storage, like the libraries.

## Performance measurements
- `PERF_TEST` / `PERF_STRESS` harness and `perf.txt` output live only on branch `perf-harness` (master has a revert commit). Do not merge it into master; check it out to measure, record whether hot reload was used.
