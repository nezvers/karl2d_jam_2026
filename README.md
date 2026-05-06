# Rope and Shotgun
Using Karl2D Hot-Reload template
Play game on [Itch.io](https://nezvers.itch.io/rope-and-shotgun)    
    
Project utilizes my utility libraries - [Odin Utilities](https://github.com/nezvers/odin_utilities)    

### Build
`odin run main_release`

# Hot-Reload
Hot-Reload currently only works on Windows.

## How to use the hot reload
1. Download this repository, use it as a template for your project
2. Put the contents of the Karl2D repository into `game/karl2d`.
3. Execute `odin run .` in the project's root folder (where `build.odin` lives). This will compile the stuff in the `game` folder as a DLL and also compile a `game_hot_reload.exe` executable.
4. Start `game_hot_reload.exe`, leave it running.
5. Make changes to `game/game.odin`, for example, change the color passed to `k2.draw_circle` from `k2.DARK_BLUE` to `k2.RED`.
6. Run `odin run .` in the project's root folder again. Only the DLL is rebuilt and then reloaded by the running game.

## Making a web build
In the project's root, run: `odin run game/karl2d/build_web -- main_web`. The web build will end up in `main_web/bin`.

>[!NOTE]
>I'm aware that you currently get two `bin` folders: `bin/hot_reload` and `main_web/bin`. Ideally both would use the same folder. Again, this is at the moment an experimental repository.

## Making a release build your game
In the project's root, run: `odin build main_release`
