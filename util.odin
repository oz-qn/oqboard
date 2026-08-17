package main

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
		return nil, false
	}

	delete(stderr)
	return stdout, true
}

get_hovered_frame :: proc(mouse_pos: rl.Vector2) -> (^Frame, int) {
	#reverse for &frame, index in frames {
		if rl.CheckCollisionPointRec(mouse_pos, frame) do return &frame, index
	}
	return nil, -1
}

selection_valid :: #force_inline proc(selection: SelectionData) -> bool {
	return selection.selected != nil
}

get_hovered_edge :: proc(mouse_pos: rl.Vector2, frame: ^Frame) -> (EdgeType, bool) {
	top_left := rl.Vector2{frame.x, frame.y}
	top_right := rl.Vector2{frame.x + frame.width, frame.y}
	bottom_left := rl.Vector2{frame.x, frame.y + frame.height}
	bottom_right := rl.Vector2{frame.x + frame.width, frame.y + frame.height}

	switch {
	case rl.CheckCollisionPointLine(mouse_pos, top_left, bottom_left, 5):
		return .LEFT, true
	case rl.CheckCollisionPointLine(mouse_pos, top_left, top_right, 5):
		return .UP, true
	case rl.CheckCollisionPointLine(mouse_pos, top_right, bottom_right, 5):
		return .RIGHT, true
	case rl.CheckCollisionPointLine(mouse_pos, bottom_left, bottom_right, 5):
		return .DOWN, true
	case:
		return .NONE, false
	}
}
