package karl2d_hot_reload_build

import "core:os"
import "core:fmt"
import "core:path/filepath"
import "core:time"

main :: proc() {
	DLL_DIR :: "bin/hot_reload"
	DLL_PDB_DIR :: DLL_DIR + "/pdbs"
	EXE_NAME :: "game_hot_reload.exe"

	pids, pids_err := os.process_list(context.allocator)

	if pids_err != nil {
		fmt.println("Failed to list processes")
		return
	}

	game_running := false

	for pid in pids {
		info, info_err := os.process_info_by_pid(pid, {.Executable_Path}, context.allocator)

		if info_err == nil {
			if filepath.base(info.executable_path) == EXE_NAME {
				game_running = true
				break
			}
		}
	}

	if !game_running {
		os.remove(DLL_DIR)
		os.remove(DLL_PDB_DIR)
		os.make_directory_all(DLL_DIR)
		os.make_directory_all(DLL_PDB_DIR)
	}
	
	pdb_number := time.to_unix_nanoseconds(time.now())

	fmt.println("Building game DLL...")

	build_game_state, _, build_game_errmsg, build_game_err := os.process_exec(
		desc = {
			command = {
				"odin.exe",
				"build",
				"game",
				"-debug",
				"-build-mode:dll",
				"-out:" + DLL_DIR + "/game.dll",
				fmt.tprintf("-pdb-name:%s/game_%i.pdb", DLL_PDB_DIR, pdb_number),
			},
		},
		allocator = context.allocator,
	)

	if build_game_err != nil {
		fmt.eprintln("Failed to build game DLL:", build_game_err)
		os.exit(1)
	}

	if build_game_state.exit_code != 0 {
		fmt.eprintln("Failed to build game DLL:", string(build_game_errmsg), sep = "\n")
		os.exit(1)
	}

	if game_running {
		fmt.println("Hot reloading...")
		os.exit(0)
	}

	fmt.println("Building game EXE...")

	build_exe_state, _, build_exe_errmsg, build_exe_err := os.process_exec(
		desc = {
			command = {
				"odin.exe",
				"build",
				"main_hot_reload",
				"-debug",
				"-out:" + EXE_NAME,
			},
		},
		allocator = context.allocator,
	)

	if build_exe_err != nil {
		fmt.eprintln("Failed to build game EXE:", build_exe_err)
		os.exit(1)
	}

	if build_exe_state.exit_code != 0 {
		fmt.eprintln("Failed to build game EXE:", string(build_exe_errmsg), sep = "\n")
		os.exit(1)
	}
}