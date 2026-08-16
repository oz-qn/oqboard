package main

import rl "vendor:raylib"

RectType :: enum {
	FILLED,
	LINE,
}

RenderRect :: struct {
	using rect: rl.Rectangle,
	color:      rl.Color,
	type:       RectType,
}

SelectionData :: struct {
	selected: ^RenderRect,
	offset:   rl.Vector2,
}
