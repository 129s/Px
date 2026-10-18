package main

import "core:fmt"
import rl "vendor:raylib"

Vec2i :: struct {
	x, y: i32,
}

PADDING :: 16

CanvasSize :: struct {
	width, height: i32,
}

Canvas :: struct {
	pos_sc: Vec2i,
	size:   CanvasSize,
	data:   []rl.Color,
	scale:  i32, // percentage unit
}

Canvas_init :: proc(c: ^Canvas, size: CanvasSize, scale: i32) {
	c.pos_sc = Vec2i{0, 0}
	c.size = size
	c.data = make([]rl.Color, size.width * size.height)
	c.scale = scale
}

Canvas_set_pixel :: proc(c: ^Canvas, x, y: i32, color: rl.Color) {
	if x < 0 || x >= c.size.width || y < 0 || y >= c.size.height {
		return
	}
	c.data[y * c.size.width + x] = color
}

Canvas_draw_to_screen :: proc(c: ^Canvas) {
	for y in 0 ..< c.size.height {
		for x in 0 ..< c.size.width {
			color := c.data[y * c.size.width + x]
			rl.DrawPixel(x, y, color)
		}
	}
}


D_SC_W :: 800
D_SC_H :: 600

main :: proc() {
	rl.InitWindow(D_SC_W, D_SC_H, "Hello World")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	canvas := Canvas{}
	Canvas_init(&canvas, CanvasSize{width = 32, height = 32}, 400)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		rl.ClearBackground(rl.RAYWHITE)

		rl.DrawText("Debug", PADDING, PADDING + 32, 32, rl.GREEN)
		p := rl.GetMousePosition()

		if rl.IsMouseButtonDown(.LEFT) {


			Canvas_set_pixel(&canvas, i32(p.x), i32(p.y), rl.RED)

		}

		Canvas_draw_to_screen(&canvas)

		rl.EndDrawing()
	}
}
