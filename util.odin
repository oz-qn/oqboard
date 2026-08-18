package main

import "clipboard"
import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"
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

get_clipboard_data :: proc() -> (clipboard.Data, bool) {
	return clipboard.get()
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

update_cursor :: proc() {
	switch selection.selected_edge {
	case .LEFT, .RIGHT:
		rl.SetMouseCursor(.RESIZE_EW)
	case .UP, .DOWN:
		rl.SetMouseCursor(.RESIZE_NS)
	case .NONE:
		rl.SetMouseCursor(.POINTING_HAND if is_hovering else .DEFAULT)
	}
}

@(private = "file")
TextState :: enum u8 {
	MEASURE_STATE,
	DRAW_STATE,
}

draw_text_wrapped :: proc(
	text: string,
	rect: rl.Rectangle,
	font: rl.Font,
	font_size: f32 = 20,
	spacing: f32 = 1,
	buffer: f32,
	color: rl.Color = rl.WHITE,
) {
	bounds := rl.Rectangle {
		rect.x + buffer,
		rect.y + buffer,
		rect.width - buffer,
		rect.height - buffer,
	}

	ctext := strings.unsafe_string_to_cstring(text)
	length := rl.TextLength(ctext)

	text_offset := [2]f32{0, 0}

	scale_factor: f32 = font_size / f32(font.baseSize)

	state: TextState = .MEASURE_STATE

	start_line: i32 = -1
	end_line: i32 = -1
	last_k: i32 = -1

	i: u32 = 0
	k: i32 = 0

	for i < length {
		codepoint_byte_count: i32 = 0
		char := text[i]
		codepoint := rl.GetCodepoint(
			strings.unsafe_string_to_cstring(strings.string_from_ptr(&char, 1)),
			&codepoint_byte_count,
		)
		index := rl.GetGlyphIndex(font, codepoint)

		if (codepoint == 0x3f) {
			codepoint_byte_count = 1
		}
		i += u32(codepoint_byte_count - 1)

		glyph_width: f32 = 0
		if (codepoint != '\n') {
			glyph_width =
				font.recs[index].width * scale_factor if (font.glyphs[index].advanceX == 0) else f32(font.glyphs[index].advanceX) * scale_factor
			if (i + 1 < length) do glyph_width = glyph_width + spacing
		}

		if state == .MEASURE_STATE {
			if (codepoint == ' ') || (codepoint == '\t') || (codepoint == '\n') do end_line = i32(i)

			if (text_offset.x + glyph_width) > bounds.width {
				end_line = i32(i) if end_line < 1 else end_line
				if i32(i) == end_line do end_line -= codepoint_byte_count
				if (start_line + codepoint_byte_count) == end_line do end_line = (i32(i) - codepoint_byte_count)

				state = .DRAW_STATE
			} else if (i + 1) == length {
				end_line = i32(i)
				state = .DRAW_STATE
			} else if codepoint == '\n' {
				state = .DRAW_STATE
			}

			if state == .DRAW_STATE {
				text_offset.x = 0
				i = u32(start_line)
				glyph_width = 0
				tmp := last_k
				last_k = k - 1
				k = tmp
			}
		} else {
			if text_offset.y + f32(font.baseSize) * scale_factor > bounds.height do break
			if codepoint != ' ' && codepoint != '\t' {
				rl.DrawTextCodepoint(
					font,
					codepoint,
					{bounds.x + text_offset.x, bounds.y + text_offset.y},
					font_size,
					color,
				)
			}
			if i == u32(end_line) {
				text_offset.y += (f32(font.baseSize) + (f32(font.baseSize) / 2)) * scale_factor
				text_offset.x = 0
				start_line = end_line
				end_line = -1
				glyph_width = 0
				k = last_k

				state = .MEASURE_STATE
			}
		}

		if (text_offset.x != 0) || (codepoint != ' ') do text_offset.x += glyph_width

		i += 1
		k += 1
	}
}
