package main

import rl "vendor:raylib"

delete_frame :: proc(frame: ^Frame, index: int) {
	unordered_remove(&frames, index)
	switch type in frame.render {
	case Texture:
		rl.UnloadTexture(type.texture)
	case Rect:

	case Text:

	}
	selection.selected = nil
}
