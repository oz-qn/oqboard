package main

import rl "vendor:raylib"

Editor :: struct {
	state: EditorState,
}

EditorState :: union {
	SelectState,
	TextEditState,
}

SelectState :: struct {
	using data: SelectionData,
}

TextEditState :: struct {}

editor_init :: proc(editor: ^Editor, state: EditorState) {
	editor.state = state
}

editor_update :: proc(editor: ^Editor) {
	mouse_pos := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)
	camera.offset = rl.GetMousePosition()
	camera.target = mouse_pos

	switch state in editor.state {
	case SelectState:
		hovered, index := get_hovered_frame(mouse_pos)
		is_hovering = index != -1

		if is_hovering {
			rl.SetMouseCursor(.POINTING_HAND)
		} else {
			rl.SetMouseCursor(.DEFAULT)
		}


		if rl.IsMouseButtonDown(.RIGHT) {
			if rl.IsMouseButtonPressed(.RIGHT) {
				if rl.IsKeyDown(.LEFT_SHIFT) {
					pos := to_grid(mouse_pos, 20)
					new_rect := Frame {
						{pos.x, pos.y, 300, 40},
						Text{"Lorem ipsum dolor samet.", rl.WHITE, 20},
					}
					append(&frames, new_rect)
				}
				if rl.IsKeyDown(.LEFT_CONTROL) {
					if index != -1 {
						delete_frame(hovered, index)
					}
				}
			}
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

		if s, ok := editor.state.(SelectState);
		   rl.IsKeyPressed(.ENTER) && selection.selected != nil && ok {
			editor.state = TextEditState{}
		}
	case TextEditState:
	}
}
