package main

import rl "vendor:raylib"

RectType :: enum {
	FILLED,
	LINE,
}

SelectionData :: struct {
	selected: ^Frame,
	offset:   rl.Vector2,
}

Frame :: struct {
	using bounds: rl.Rectangle,
	render:       Render,
}

Render :: union {
	Rect,
	Texture,
}

Rect :: struct {
	color: rl.Color,
	type:  RectType,
}

Texture :: struct {
	src:     rl.Rectangle,
	texture: rl.Texture,
	tint:    rl.Color,
}
