package main

import rl "vendor:raylib"

RectType :: enum {
	FILLED,
	LINE,
}

RenderObject :: union {
	RenderRect,
	RenderTexture,
}

RenderRect :: struct {
	using rect: rl.Rectangle,
	color:      rl.Color,
	type:       RectType,
}

RenderTexture :: struct {
	using rect: rl.Rectangle,
	src:        rl.Rectangle,
	texture:    rl.Texture2D,
	tint:       rl.Color,
}

SelectionData :: struct {
	selected: ^RenderObject,
	offset:   rl.Vector2,
}
