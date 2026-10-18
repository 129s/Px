package main

import "core:fmt"
import rl "vendor:raylib"


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

// use Brush to "Draw" Color to Canvas,
// in fact just write the data instead of drawing sth to screen
Canvas_Brush_draw :: proc(c: ^Canvas, x, y: i32, b: Brush) {
	s := b.size
	if s % 2 == 0 {
		for dy in -s / 2 ..< s / 2 {
			for dx in -s / 2 ..< s / 2 {
				Canvas_set_pixel(c, x + dx, y + dy, b.f_color)
			}
		}
	} else {
		for dy in -s / 2 ..< s / 2 + 1 {
			for dx in -s / 2 ..< s / 2 + 1 {
				Canvas_set_pixel(c, x + dx, y + dy, b.f_color)
			}
		}
	}
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

Palette :: struct {
	colors: []rl.Color,
}

Palette_init :: proc(p: ^Palette, colors: []rl.Color) {
	p.colors = colors
}

Palette_draw_to_screen :: proc(p: ^Palette) {
	pos := Vec2i{PADDING, PADDING}
	size: i32 = 32
	for i in 0 ..< len(p.colors) {
		rl.DrawRectangle(pos.x + i32(i) * size, pos.y, size, size, p.colors[i])
		rl.DrawRectangleLines(pos.x + i32(i) * size, pos.y, size, size, rl.YELLOW)
	}
}

Brush_draw_info :: proc(b: Brush, sc_w, sc_h: i32) {
	pos := Vec2i{PADDING, sc_h - PADDING} // 左下角
	size: i32 = 32

	// foreground and background color
	rl.DrawRectangle(pos.x, pos.y - size, size, size, brush.f_color)
	rl.DrawRectangleLines(pos.x, pos.y - size, size, size, rl.YELLOW)

	rl.DrawRectangle(pos.x, pos.y - size * 2 - PADDING, size, size, brush.b_color)
	rl.DrawRectangleLines(pos.x, pos.y - size * 2 - PADDING, size, size, rl.YELLOW)

	// brush size
	rl.DrawText(
		fmt.ctprintf("%d", brush.size),
		pos.x + PADDING + size + PADDING,
		pos.y - FONT_SIZE,
		FONT_SIZE,
		rl.WHITE,
	)

}

Tool :: enum {
	Pencil,
	Eraser,
	Picker,
}

Brush :: struct {
	f_color: rl.Color,
	b_color: rl.Color,
	size:    i32,
}

get_mouse_pos :: proc() -> Vec2i {
	return Vec2i{rl.GetMouseX(), rl.GetMouseY()}
}

tool := Tool.Pencil

canvas := Canvas{}
palette := Palette{}
brush := Brush {
	// foreground / background color
	f_color = rl.WHITE,
	b_color = rl.BLANK,
	size    = 1,
}

D_SC_W :: 800
D_SC_H :: 600
sc_w: i32
sc_h: i32
FONT_SIZE :: 32

main :: proc() {
	rl.InitWindow(D_SC_W, D_SC_H, "Hello World")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	// get runtime screen size
	sc_w, sc_h = rl.GetScreenWidth(), rl.GetScreenHeight()


	Canvas_init(&canvas, CanvasSize{width = 32, height = 32}, 800)
	Palette_init(
		&palette,
		{rl.RED, rl.GREEN, rl.BLUE, rl.YELLOW, rl.ORANGE, rl.PURPLE, rl.WHITE, rl.BLACK},
	)

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

		handle_input()

		switch tool {
		case .Pencil:
			rl.DrawText("Tool: Pencil", PADDING, PADDING + 32, FONT_SIZE, rl.GREEN)
		case .Eraser:
			rl.DrawText("Tool: Eraser", PADDING, PADDING + 32, FONT_SIZE, rl.GREEN)
		case .Picker:
			rl.DrawText("Tool: Picker", PADDING, PADDING + 32, FONT_SIZE, rl.GREEN)

		}

		// handle mouse input
		if rl.IsMouseButtonDown(.LEFT) {
			if tool == .Picker {
				cx := (p.x - canvas.pos_sc.x) * 100 / canvas.scale
				cy := (p.y - canvas.pos_sc.y) * 100 / canvas.scale

				if cx < 0 || cx >= canvas.size.width || cy < 0 || cy >= canvas.size.height {
					break
				}

				color := canvas.data[cy * canvas.size.width + cx]
				rl.DrawText(
					fmt.ctprintf("Picked color: ", color),
					sc_w / 2,
					0,
					FONT_SIZE,
					rl.WHITE,
				)
			}

			if p.x >= canvas.pos_sc.x &&
			   p.x <= canvas.pos_sc.x + canvas.size.width * canvas.scale / 100 &&
			   p.y >= canvas.pos_sc.y &&
			   p.y <= canvas.pos_sc.y + canvas.size.height * canvas.scale / 100 {
				rl.DrawText(
					fmt.ctprintf("inside"),
					PADDING,
					PADDING + FONT_SIZE * 2,
					FONT_SIZE,
					rl.YELLOW,
				)
			} else {
				rl.DrawText(
					fmt.ctprintf("outside"),
					PADDING,
					PADDING + FONT_SIZE * 2,
					FONT_SIZE,
					rl.YELLOW,
				)
			}


			cx := (p.x - canvas.pos_sc.x) * 100 / canvas.scale
			cy := (p.y - canvas.pos_sc.y) * 100 / canvas.scale

			Canvas_Brush_draw(&canvas, cx, cy, brush)

		}

		if rl.IsMouseButtonDown(.RIGHT) {

			cx := (p.x - canvas.pos_sc.x) * 100 / canvas.scale
			cy := (p.y - canvas.pos_sc.y) * 100 / canvas.scale

			Canvas_Brush_draw(&canvas, cx, cy, brush)
			// Canvas_set_pixel(&canvas, cx, cy, {0, 0, 0, 0})

		}

		Canvas_draw_to_screen(&canvas)
		Palette_draw_to_screen(&palette)
		Brush_draw_info(brush, sc_w, sc_h)
		draw_debug_info()

		rl.EndDrawing()
	}
}

handle_input :: proc() {
	// brush size increase/decrease
	if rl.IsKeyPressed(.Q) {
		if brush.size > 1 {
			brush.size -= 1
		}
	}
	if rl.IsKeyPressed(.E) {
		brush.size += 1
	}
	// color picker mode when alt is being pressed
	if rl.IsKeyDown(.LEFT_ALT) || rl.IsKeyDown(.RIGHT_ALT) {
		tool = .Picker
	} else {
		tool = .Pencil
	}
	#partial switch rl.GetKeyPressed() {
	case rl.KeyboardKey.TAB:
		// toggle foreground and background color
		brush.f_color, brush.b_color = brush.b_color, brush.f_color
	case:
	}
}

// its just a temp func lab
draw_debug_info :: proc() {

}
