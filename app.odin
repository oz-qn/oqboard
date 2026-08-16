package main

import "core:math"
import rl "vendor:raylib"

rects: [dynamic]RenderObject
selection: SelectionData
camera: rl.Camera2D

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
			new_rect := RenderRect{{pos.x, pos.y, 100, 60}, rl.DARKGRAY, .FILLED}
			append(&rects, new_rect)
		}
	}

	if rl.IsMouseButtonDown(.RIGHT) {
		delta := rl.GetMouseDelta()
		delta = delta * (-1 / camera.zoom)
		camera.target += delta
	}

	if rl.IsMouseButtonPressed(.LEFT) {
		on_left_mouse_pressed(mouse_pos)
	}

	if rl.IsMouseButtonDown(.LEFT) && selection.selected != nil {
		on_left_mouse_held(mouse_pos)
	}

	if rl.IsKeyPressed(.V) {
		if rl.IsKeyDown(.LEFT_CONTROL) {
			if test, ok := get_clipboard_image(); ok {
				img := rl.LoadImageFromMemory(".png", rawptr(raw_data(test)), i32(len(test)))
				texture := rl.LoadTextureFromImage(img)
				src := rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)}
				pos := to_grid(mouse_pos, 20)
				new_rect := RenderTexture {
					{pos.x, pos.y, src.width, src.height},
					src,
					texture,
					rl.WHITE,
				}
				append(&rects, new_rect)
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
		switch r in rect {
		case RenderRect:
			rl.DrawRectangleRec(r.rect, r.color)
		case RenderTexture:
			rl.DrawTexturePro(r.texture, r.src, r.rect, {0, 0}, 0, r.tint)
		}
	}

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
