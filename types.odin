package main

import rl "vendor:raylib"

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

RectType :: enum {
	FILLED,
	LINE,
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
