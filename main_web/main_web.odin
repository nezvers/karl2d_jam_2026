// For making a web build

package karl2d_hot_reload_main_web

import "core:log"
import game "../game"

init :: proc() {
	logger := log.create_console_logger()
	context.logger = logger
	
	k2_state := game.game_startup(context.allocator)
	game.game_init_state(k2_state, context.allocator)
}

step :: proc() -> bool {
	return game.game_update()
}