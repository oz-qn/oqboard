package main

import rl "vendor:raylib"

on_left_mouse_pressed :: proc(mouse_pos: rl.Vector2) {
	selected: ^RenderObject = nil
	mouse_offset: rl.Vector2
	for &rect in rects {
		switch &r in rect {
		case RenderRect:
			if rl.CheckCollisionPointRec(mouse_pos, r) {
				selected = &rect
				mouse_offset = mouse_pos - {r.x, r.y}
			}
		case RenderTexture:
			if rl.CheckCollisionPointRec(mouse_pos, r) {
				selected = &rect
				mouse_offset = mouse_pos - {r.x, r.y}
			}
		}
	}
	selection = SelectionData{selected, mouse_offset}
}

on_left_mouse_held :: proc(mouse_pos: rl.Vector2) {
	pos := to_grid(mouse_pos - selection.offset, 20)

	switch &r in selection.selected {
	case RenderRect:
		r.x = pos.x
		r.y = pos.y
	case RenderTexture:
		r.x = pos.x
		r.y = pos.y
	}
}
