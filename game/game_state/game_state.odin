package game_state

import "base:runtime"
import "../assets"
import "../scene"
import "../sfx"
import "../sound_effects"

// Build knobs of the hot reload test (hot_reload_test/): they change the size or the layout of Game_Memory on purpose
GAME_MEMORY_PAD :: #config(GAME_MEMORY_PAD, 0)
GAME_MEMORY_FLOAT_COUNTER :: #config(GAME_MEMORY_FLOAT_COUNTER, false)
Counter :: f64 when GAME_MEMORY_FLOAT_COUNTER else int

// Memory of the running scene: what a scene allocates in init goes here and is freed in one step when the scene exits
SCENE_MEMORY_SIZE :: 256 * 1024
// Split between the loader threads, each decodes images into its part. Empty (or a platform without threads, the web): everything
// decodes on the main thread. Per thread it has to fit the biggest decoded texture
DECODE_MEMORY_SIZE :: 1024 * 1024

Game_Memory :: struct {
	allocator: runtime.Allocator,
	counter: Counter, // frames since the memory was created
	_test_pad: [GAME_MEMORY_PAD]u8,
	window_width:int,
	window_height:int,
	window_scale: f32,
	game_width:int,
	game_height:int,
	background_color: Color,
	camera: Camera,
	view_rect: Rect,
	projected_rect: Rect,
	game_texture: Render_Texture, // TODO: solve render texture with camera

	// Scenes and assets. Plain data, so it survives a hot reload: scenes are ids and the code is looked up again
	scene_system: scene.SceneSystem,
	asset_storage: scene.AssetStorage(assets.COUNT),
	scene_memory: [SCENE_MEMORY_SIZE]byte,
	decode_memory: [DECODE_MEMORY_SIZE]byte,
	sfx_states: [sfx.COUNT]sound_effects.SoundState,    // pitch and last trigger of each sound effect, the settings are constant data in sfx
	placeholder: scene.AssetValue,    // texture shown until a texture asset is loaded
}

g: ^Game_Memory
