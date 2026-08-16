package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

rects: [dynamic]RenderRect
selection: SelectionData
camera: rl.Camera2D
texture: rl.Texture2D

app_init :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE})
	rl.InitWindow(1280, 720, "whiteboard")
	rl.SetTargetFPS(240)

	camera = rl.Camera2D {
		zoom = 1,
	}
}

app_update :: proc() {
	mouse_pos := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)
	camera.offset = rl.GetMousePosition()
	camera.target = mouse_pos

	if rl.IsMouseButtonPressed(.RIGHT) {
		if rl.IsKeyDown(.LEFT_SHIFT) {
			pos := to_grid(mouse_pos, 20)
			new_rect := RenderRect{{pos.x, pos.y, 100, 60}, rl.RAYWHITE, .FILLED}
			append(&rects, new_rect)
		}
	}

	if rl.IsMouseButtonDown(.RIGHT) {
		delta := rl.GetMouseDelta()
		delta = delta * (-1 / camera.zoom)
		camera.target += delta
	}

	if rl.IsMouseButtonPressed(.LEFT) {
		selected: ^RenderRect = nil
		mouse_offset: rl.Vector2
		for &rect in rects {
			if rl.CheckCollisionPointRec(mouse_pos, rect) {
				selected = &rect
				mouse_offset = mouse_pos - {rect.x, rect.y}
			}
		}
		selection = SelectionData{selected, mouse_offset}
		fmt.println(selection)
	}

	if rl.IsMouseButtonDown(.LEFT) && selection.selected != nil {
		pos := to_grid(mouse_pos - selection.offset, 20)

		selection.selected.x = pos.x
		selection.selected.y = pos.y
	}

	if rl.IsKeyPressed(.V) {
		if rl.IsKeyDown(.LEFT_CONTROL) {
			if test, ok := get_clipboard_image(); ok {
				img := rl.LoadImageFromMemory(".png", rawptr(raw_data(test)), i32(len(test)))
				texture = rl.LoadTextureFromImage(img)
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

	for rect in rects {
		switch rect.type {
		case .LINE:
			rl.DrawRectangleLinesEx(rect, 3, rect.color)
		case .FILLED:
			rl.DrawRectangleRec(rect, rect.color)
			rl.DrawRectangleLinesEx(rect, 3, rl.GRAY)
		}
	}

	rl.DrawTextureRec(texture, {0, 0, 1280, 720}, {0, 0}, rl.WHITE)

	rl.EndMode2D()
	rl.EndDrawing()
}

app_exit :: proc() {
	delete(rects)
	rl.CloseWindow()
}

app_should_run :: #force_inline proc() -> bool {
	return !rl.WindowShouldClose()
}
