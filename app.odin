package main

import "core:math"
import rl "vendor:raylib"

frames: [dynamic]Frame
selection: SelectionData
camera: rl.Camera2D

app_init :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE})
	rl.InitWindow(1280, 720, "oqboard")
	rl.SetTargetFPS(240)

	camera = rl.Camera2D {
		zoom = 1,
	}
}

app_update :: proc() {
	mouse_pos := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)
	camera.offset = rl.GetMousePosition()
	camera.target = mouse_pos

	hovered, index := get_hovered_frame(mouse_pos)

	if hovered != nil {
		rl.SetMouseCursor(.POINTING_HAND)
	} else {
		rl.SetMouseCursor(.DEFAULT)
	}

	if rl.IsMouseButtonPressed(.RIGHT) {
		if rl.IsKeyDown(.LEFT_SHIFT) {
			pos := to_grid(mouse_pos, 20)
			new_rect := Frame{{pos.x, pos.y, 100, 60}, Rect{rl.GRAY, .FILLED}}
			append(&frames, new_rect)
		}
		if rl.IsKeyDown(.LEFT_CONTROL) {
			if index != -1 {
				delete_frame(hovered, index)
			}
		}
	}

	if rl.IsMouseButtonDown(.RIGHT) {
		delta := rl.GetMouseDelta()
		delta = delta * (-1 / camera.zoom)
		camera.target += delta
	}

	if selection_valid(selection) && !rl.IsMouseButtonDown(.LEFT) {
		selection.selected_edge, selection.edge_found = get_hovered_edge(
			mouse_pos,
			selection.selected,
		)
	}

	if rl.IsMouseButtonDown(.LEFT) {

		if rl.IsMouseButtonPressed(.LEFT) && !selection.edge_found {
			offset: rl.Vector2
			if hovered != nil do offset = {mouse_pos.x - hovered.x, mouse_pos.y - hovered.y}
			selection = SelectionData{hovered, offset, .NONE, false}
		}

		if selection_valid(selection) {
			if selection.edge_found {
				grid_pos := to_grid(mouse_pos, 20)
				frame := selection.selected
				#partial switch selection.selected_edge {
				case .LEFT:
					prev := frame.x
					frame.x = grid_pos.x
					frame.width += (prev - frame.x)
				case .RIGHT:
					frame.width = grid_pos.x - frame.x
				case .UP:
					prev := frame.y
					frame.y = grid_pos.y
					frame.height += (prev - frame.y)
				case .DOWN:
					frame.height = grid_pos.y - frame.y
				}
			} else {
				frame := selection.selected
				target := to_grid(
					{mouse_pos.x - selection.offset.x, mouse_pos.y - selection.offset.y},
					20,
				)
				frame.x = target.x
				frame.y = target.y

			}
		}
	}

	if rl.IsKeyPressed(.V) {
		if rl.IsKeyDown(.LEFT_CONTROL) {
			if test, ok := get_clipboard_image(); ok {
				img := rl.LoadImageFromMemory(".png", rawptr(raw_data(test)), i32(len(test)))
				texture := rl.LoadTextureFromImage(img)
				src := rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)}
				pos := to_grid(mouse_pos, 20)
				new_rect := Frame {
					{pos.x, pos.y, src.width, src.height},
					Texture{src, texture, rl.WHITE},
				}
				append(&frames, new_rect)
			}
		}
	}

	mouse_wheel: f32 = rl.GetMouseWheelMove() * 0.25
	scale := 0.2 * mouse_wheel
	camera.zoom = math.clamp(math.exp(math.log(camera.zoom, 2.71828) + scale), 0.125, 64)
}

app_draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground({50, 50, 50, 255})

	rl.BeginMode2D(camera)

	draw_grid()

	for &rect in frames {
		switch r in rect.render {
		case Rect:
			rl.DrawRectangleRec(rect.bounds, r.color)
		case Texture:
			rl.DrawTexturePro(r.texture, r.src, rect.bounds, {0, 0}, 0, r.tint)
		}
	}

	if selection.selected != nil {
		border := selection.selected.bounds
		border.x -= 3
		border.y -= 3
		border.width += 6
		border.height += 6
		rl.DrawRectangleLinesEx(border, 3, rl.WHITE)
	}

	switch selection.selected_edge {
	case .LEFT, .RIGHT:
		rl.SetMouseCursor(.RESIZE_EW)
	case .UP, .DOWN:
		rl.SetMouseCursor(.RESIZE_NS)
	case .NONE:
		rl.SetMouseCursor(.DEFAULT)
	}

	rl.EndMode2D()
	rl.EndDrawing()
}

app_exit :: proc() {
	delete(frames)
	rl.CloseWindow()
}

app_should_run :: #force_inline proc() -> bool {
	return !rl.WindowShouldClose()
}
