package main

import rl "vendor:raylib"

on_left_mouse_pressed :: proc(mouse_pos: rl.Vector2) {
	selected: ^Frame = nil
	mouse_offset: rl.Vector2
	for &rect in frames {
		switch &r in rect.render {
		case Rect:
			if rl.CheckCollisionPointRec(mouse_pos, rect.bounds) {
				selected = &rect
				mouse_offset = mouse_pos - {rect.bounds.x, rect.bounds.y}
			}
		case Texture:
			if rl.CheckCollisionPointRec(mouse_pos, rect.bounds) {
				selected = &rect
				mouse_offset = mouse_pos - {rect.bounds.x, rect.bounds.y}
			}
		}
	}
	selection = SelectionData{selected, mouse_offset}
}

on_left_mouse_held :: proc(mouse_pos: rl.Vector2) {
	pos := to_grid(mouse_pos - selection.offset, 20)
	selection.selected.bounds.x = pos.x
	selection.selected.bounds.y = pos.y
}

delete_frame :: proc(frame: ^Frame, index: int) {
	unordered_remove(&frames, index)
	switch type in frame.render {
	case Texture:
		rl.UnloadTexture(type.texture)
	case Rect:

	}
}
