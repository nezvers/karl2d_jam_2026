// Tests the hot reload memory transition with the real game_hot_reload exe and real DLLs. Run from the project root:
//   odin run hot_reload_test
// Builds the exe in test mode (it prints its state and takes commands through files) and three DLL variants:
//   base    the game as it is
//   pad     Game_Memory has a different size
//   layout  Game_Memory has the same size, but a different type
// then loads them one after another into the running exe and checks what happens to the game memory and to resources.
package hot_reload_test

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:time"

DIR :: "bin/hot_reload_test"
EXE :: DIR + "/hot_reload_test.exe"
OUTPUT :: DIR + "/output.txt"

Status :: struct {
	frame, version, screen, counter: int,
	valid: bool,
}

failures: int

check :: proc(ok: bool, format: string, args: ..any) {
	if ok {
		fmt.printfln("ok    %s", fmt.tprintf(format, ..args))
	} else {
		failures += 1
		fmt.printfln("FAIL  %s", fmt.tprintf(format, ..args))
	}
}

build :: proc(what: string, arguments: ..string) -> bool {
	command: [dynamic]string
	append(&command, "odin", "build")
	append(&command, ..arguments)
	state, _, errors, err := os.process_exec({command = command[:]}, context.allocator)
	if err != nil || state.exit_code != 0 {
		fmt.printfln("FAIL  build %s\n%s", what, string(errors))
		return false
	}
	fmt.printfln("built %s", what)
	return true
}

// The last status line the exe printed
status :: proc() -> (result: Status) {
	data, err := os.read_entire_file(OUTPUT, context.temp_allocator)
	if err != nil {return}
	text := string(data)
	for line in strings.split_lines_iterator(&text) {
		if !strings.has_prefix(line, "[HR] ") {continue}
		parsed: Status
		for field in strings.split(line[5:], " ", context.temp_allocator) {
			key, _, value := strings.partition(field, "=")
			number, _ := strconv.parse_int(value)
			switch key {
			case "frame": parsed.frame = number
			case "version": parsed.version = number
			case "screen": parsed.screen = number
			case "counter": parsed.counter = number
			}
		}
		parsed.valid = true
		result = parsed
	}
	return
}

output_has :: proc(needle: string) -> bool {
	data, err := os.read_entire_file(OUTPUT, context.temp_allocator)
	return err == nil && strings.contains(string(data), needle)
}

// Wait until the exe reports a state that satisfies the condition
wait_for :: proc(condition: proc(s: Status) -> bool, seconds: f64 = 15) -> (result: Status, ok: bool) {
	start := time.now()
	for time.duration_seconds(time.since(start)) < seconds {
		result = status()
		if result.valid && condition(result) {return result, true}
		time.sleep(50 * time.Millisecond)
	}
	return result, false
}

// New file in place at once, so the exe never sees a half written DLL
install :: proc(variant: string) {
	data, _ := os.read_entire_file(fmt.tprintf("%s/variants/%s.dll", DIR, variant), context.temp_allocator)
	_ = os.write_entire_file(DIR + "/incoming.dll", data)
	os.remove(DIR + "/game.dll")
	os.rename(DIR + "/incoming.dll", DIR + "/game.dll")
}

command :: proc(name: string) {
	_ = os.write_entire_file(fmt.tprintf("%s/%s", DIR, name), "")
}

at_gameplay :: proc(s: Status) -> bool {
	return s.screen == 2 && s.counter > 20
}

main :: proc() {
	os.make_directory_all(DIR + "/variants")
	built := build("exe", "main_hot_reload", "-debug", "-out:" + EXE, "-define:HOT_RELOAD_TEST=true", "-define:DLL_DIR=" + DIR)
	built &&= build("dll base", "game", "-build-mode:dll", "-out:" + DIR + "/variants/base.dll")
	built &&= build("dll pad", "game", "-build-mode:dll", "-out:" + DIR + "/variants/pad.dll", "-define:GAME_MEMORY_PAD=64")
	built &&= build("dll layout", "game", "-build-mode:dll", "-out:" + DIR + "/variants/layout.dll", "-define:GAME_MEMORY_FLOAT_COUNTER=true")
	if !built {os.exit(1)}

	os.remove(DIR + "/stop")
	os.remove(DIR + "/restart")
	os.remove(DIR + "/gameplay")
	install("base")
	os.remove(OUTPUT)
	// A shell redirect gives the child a plain file for stdout and stderr that can be read while it is still written
	redirected, _ := strings.replace_all(fmt.tprintf("%s > %s 2>&1", EXE, OUTPUT), "/", "\\", context.temp_allocator)
	process, start_err := os.process_start({command = {"cmd", "/c", redirected}})
	if start_err != nil {
		fmt.println("FAIL  could not start", EXE, start_err)
		os.exit(1)
	}

	started, started_ok := wait_for(at_gameplay)
	check(started_ok, "game starts and reaches the gameplay screen (counter %d)", started.counter)

	// 1. Same Game_Memory: the memory stays, the screen is restarted by the new code
	before := status()
	install("base")
	same, same_ok := wait_for(proc(s: Status) -> bool {return s.version == 1})
	check(same_ok, "reload with the same memory layout is picked up")
	check(same.counter >= before.counter, "same layout: game memory is kept (counter %d -> %d)", before.counter, same.counter)
	check(same.screen == 2, "same layout: the screen stays on gameplay (screen %d)", same.screen)

	// 2. Another size: memory is rebuilt from scratch
	before, _ = wait_for(at_gameplay)
	install("pad")
	size_changed, size_ok := wait_for(proc(s: Status) -> bool {return s.version == 2})
	check(size_ok, "reload with another memory size is picked up")
	check(size_changed.counter < before.counter, "size change: memory is new (counter %d -> %d)", before.counter, size_changed.counter)
	check(size_changed.screen == 0, "size change: game starts again from the title screen (screen %d)", size_changed.screen)

	// 3. Same size, other type: must not be read as if nothing changed
	install("base")                                                                       // the size changed above, start the comparison from the base build
	_, base_again := wait_for(proc(s: Status) -> bool {return s.version == 3})
	check(base_again, "back to the base build after the size change")
	command("gameplay")
	before, _ = wait_for(at_gameplay)
	install("layout")
	layout_changed, layout_ok := wait_for(proc(s: Status) -> bool {return s.version == 4})
	check(layout_ok, "reload with another layout of the same size is picked up")
	check(layout_changed.counter < before.counter, "same size, other layout: memory is new, the old bytes are not reused (counter %d -> %d)", before.counter, layout_changed.counter)
	check(layout_changed.screen == 0, "same size, other layout: starts from the title screen (screen %d)", layout_changed.screen)

	// 4. Restart key while on gameplay
	command("gameplay")
	before, _ = wait_for(at_gameplay)
	command("restart")
	restarted, restarted_ok := wait_for(proc(s: Status) -> bool {return s.version == 4 && s.counter < 15 && s.screen == 0})
	check(restarted_ok, "restart: memory and screen start over (counter %d)", restarted.counter)

	// 5. The build is still writing the DLL: the exe must keep running and take the finished DLL later
	command("gameplay")
	before, _ = wait_for(at_gameplay)
	data, _ := os.read_entire_file(DIR + "/variants/base.dll", context.temp_allocator)
	os.remove(DIR + "/game.dll")
	_ = os.write_entire_file(DIR + "/game.dll", data[:len(data) / 3])
	time.sleep(700 * time.Millisecond)
	after_partial := status()
	time.sleep(300 * time.Millisecond)
	still_running := status()
	check(still_running.frame > after_partial.frame && !output_has("panic"), "half written DLL: the running game is not taken down")
	install("base")
	_, finished_ok := wait_for(proc(s: Status) -> bool {return s.version >= 5})
	check(finished_ok, "half written DLL: the finished DLL is loaded afterwards")

	// 6. Closing: no leaks, no crash
	command("stop")
	state, wait_err := os.process_wait(process, 15 * time.Second)
	if wait_err != nil || !state.exited {
		_ = os.process_kill(process)
		check(false, "the game exits when asked to")
	} else {
		check(state.exit_code == 0, "the game exits cleanly (exit code %d)", state.exit_code)
	}
	check(!output_has("Leaked") && !output_has("Memory leaks"), "no memory leaks at exit")

	if failures > 0 {
		fmt.printfln("%d checks failed, output of the game: %s", failures, OUTPUT)
		os.exit(1)
	}
	fmt.println("hot reload transition: ALL PASS")
}
