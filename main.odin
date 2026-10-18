package main

import "core:fmt"
import rl "vendor:raylib"


PADDING :: 16

CanvasSize :: struct {
	width, height: i32,
}

Scale :: enum u8 {
	QUARTER,
	HALF,
	FULL,
	TWO,
	THREE,
	FOUR,
	FIVE,
	SIX,
	SEVEN,
	EIGHT,
}

Canvas :: struct {
	size:  CanvasSize,
	data:  []rl.Color,
	scale: Scale,
}

Canvas_init :: proc(c: ^Canvas, s: CanvasSize) {
	c.size = s
	c.data = make([]rl.Color, s.width * s.height)
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
	Canvas_init(&canvas, CanvasSize{width = D_SC_W, height = D_SC_H})

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		rl.ClearBackground(rl.RAYWHITE)

		rl.DrawText("Debug", PADDING, PADDING + 32, 32, rl.GREEN)
		p := rl.GetMousePosition()
		rl.DrawText(
			fmt.ctprintf("Mouse Position: %.1f, %.1f", p.x, p.y),
			PADDING,
			PADDING + 64,
			32,
			rl.BLACK,
		)

		if rl.IsMouseButtonDown(.LEFT) {

			rl.DrawText("MOUSE DOWN", PADDING, PADDING + 96, 32, rl.RED)

			Canvas_set_pixel(&canvas, i32(p.x), i32(p.y), rl.RED)

		}

		Canvas_draw_to_screen(&canvas)

		rl.DrawText("Hello, Px!", PADDING, PADDING + 0, 32, rl.BLACK)
		rl.EndDrawing()
	}
}
