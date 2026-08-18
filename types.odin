package main

import rl "vendor:raylib"

SelectionData :: struct {
	selected:      ^Frame,
	offset:        rl.Vector2,
	selected_edge: EdgeType,
	edge_found:    bool,
}

Frame :: struct {
	using bounds: rl.Rectangle,
	render:       Render,
}

Render :: union {
	Rect,
	Texture,
	Text,
}

RectType :: enum {
	FILLED,
	LINE,
}

EdgeType :: enum {
	NONE,
	LEFT,
	RIGHT,
	UP,
	DOWN,
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

Text :: struct {
	text:  string,
	color: rl.Color,
}
