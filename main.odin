package main

import "core:fmt"
import rl "vendor:raylib"

Vec2i :: struct {
	x, y: i32,
}

Rect2i :: struct {
	x, y, w, h: i32,
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
	// draw outline border
	rl.DrawRectangleLines(
		c.pos_sc.x,
		c.pos_sc.y,
		c.size.width * c.scale / 100,
		c.size.height * c.scale / 100,
		rl.YELLOW,
	)


	for y in 0 ..< c.size.height {
		for x in 0 ..< c.size.width {
			color := c.data[y * c.size.width + x]
			sx, sy := c.pos_sc.x + x * c.scale / 100, c.pos_sc.y + y * c.scale / 100
			rl.DrawRectangle(sx, sy, c.scale / 100, c.scale / 100, color)
		}
	}
}

Canvas_clear :: proc(c: ^Canvas, color: rl.Color) {
	for y in 0 ..< c.size.height {
		for x in 0 ..< c.size.width {
			c.data[y * c.size.width + x] = color
		}
	}
}


get_mouse_pos :: proc() -> Vec2i {
	return Vec2i{rl.GetMouseX(), rl.GetMouseY()}
}


D_SC_W :: 800
D_SC_H :: 600
sc_w: i32
sc_h: i32

main :: proc() {
	rl.InitWindow(D_SC_W, D_SC_H, "Hello World")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	// get runtime screen size
	sc_w, sc_h = rl.GetScreenWidth(), rl.GetScreenHeight()


	canvas := Canvas{}
	Canvas_init(&canvas, CanvasSize{width = 32, height = 32}, 800)

	// set canvas position to center of screen
	canvas.pos_sc = Vec2i {
		x = (sc_w - canvas.size.width * canvas.scale / 100) / 2,
		y = (sc_h - canvas.size.height * canvas.scale / 100) / 2,
	}

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		rl.ClearBackground(rl.BLACK)

		// rl.DrawText("Debug", PADDING, PADDING + 32, 32, rl.GREEN)
		p := get_mouse_pos()

		if rl.IsMouseButtonDown(.LEFT) {

			cx := (p.x - canvas.pos_sc.x) * 100 / canvas.scale
			cy := (p.y - canvas.pos_sc.y) * 100 / canvas.scale

			Canvas_set_pixel(&canvas, cx, cy, rl.WHITE)

		}

		Canvas_draw_to_screen(&canvas)

		rl.EndDrawing()
	}
}
