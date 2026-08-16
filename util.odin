package main

import "core:fmt"
import "core:math"
import "core:os"
import rl "vendor:raylib"

draw_grid :: proc() {
	top_left := rl.GetScreenToWorld2D({-40, -40}, camera)
	bottom_right := rl.GetScreenToWorld2D({1280 + 40, 720 + 40}, camera)
	start_x := i32(top_left.x / 20) * 20
	end_x := i32(bottom_right.x / 20) * 20
	start_y := i32(top_left.y / 20) * 20
	end_y := i32(bottom_right.y / 20) * 20

	for x: i32 = start_x; x <= end_x; x += 20 {
		rl.DrawLineV({f32(x), f32(start_y)}, {f32(x), f32(end_y)}, {255, 255, 255, 50})
	}
	for y: i32 = start_y; y <= end_y; y += 20 {
		rl.DrawLineV({f32(start_x), f32(y)}, {f32(end_x), f32(y)}, {255, 255, 255, 50})
	}
}

to_grid :: #force_inline proc "contextless" (a: [2]f32, grid_size: f32) -> [2]f32 {
	a := a
	a.x = math.round(a.x / grid_size) * grid_size
	a.y = math.round(a.y / grid_size) * grid_size
	return a
}

get_clipboard_text :: proc() -> (string, bool) {
	state, stdout, stderr, err := os.process_exec(
		os.Process_Desc{command = []string{"wl-paste", "--no-newline"}},
		context.temp_allocator,
	)

	if err != os.ERROR_NONE || !state.success {
		delete(stdout)
		delete(stderr)
		return "", false
	}

	delete(stderr)
	return string(stdout), true
}

get_clipboard_image :: proc() -> ([]byte, bool) {
	state, stdout, stderr, err := os.process_exec(
		os.Process_Desc{command = []string{"wl-paste", "-timage/png"}},
		context.temp_allocator,
	)

	if err != os.ERROR_NONE || !state.success {
		delete(stdout)
		delete(stderr)
		return nil, false
	}

	delete(stderr)
	return stdout, true
}
