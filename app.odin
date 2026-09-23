package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

editor: Editor

frames: [dynamic]Frame
selection: SelectionData
camera: rl.Camera2D
is_hovering: bool = false
font: rl.Font

app_init :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE})
	rl.InitWindow(1280, 720, "oqboard")
	rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))

	editor_init(&editor, SelectState{})

	font = rl.LoadFontEx("resources/Iosevka-Term-Extended.ttf", 96, nil, 0)
	rl.SetTextureFilter(font.texture, .TRILINEAR)

	camera = rl.Camera2D {
		zoom = 1,
	}
}

app_update :: proc() {
	mouse_wheel: f32 = rl.GetMouseWheelMove() * 0.25
	scale := 0.2 * mouse_wheel
	camera.zoom = math.clamp(math.exp(math.log(camera.zoom, 2.71828) + scale), 0.125, 64)

	editor_update(&editor)
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
		case Text:
			rl.DrawRectangleRec(rect, {0, 0, 0, 120})
			draw_text_wrapped(r.text, rect, font, r.size, 2, 10)
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

	update_cursor()

	rl.EndMode2D()
	text := fmt.ctprintf("fps: {}", rl.GetFPS())
	rl.DrawText(text, 10, 10, 40, rl.RAYWHITE)
	rl.EndDrawing()
}

app_exit :: proc() {
	delete(frames)
	rl.CloseWindow()
}

app_should_run :: #force_inline proc() -> bool {
	return !rl.WindowShouldClose()
}
