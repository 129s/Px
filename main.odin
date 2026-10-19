package main

import "core:fmt"
import rl "vendor:raylib"


PADDING :: 16

MIN_CANVAS_SCALE :: 100
MAX_CANVAS_SCALE :: -1
D_CANVAS_SCALE :: 400

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
		c.pos_sc.x - 1,
		c.pos_sc.y - 1,
		c.size.width * c.scale / 100 + 2,
		c.size.height * c.scale / 100 + 2,
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

PALETTE_WIDTH :: 8 // 8 colors per row, not screen width

Palette :: struct {
	colors: []rl.Color,
}

Palette_init :: proc(p: ^Palette, colors: []rl.Color) {
	p.colors = colors
}

Palette_draw_to_screen :: proc(p: ^Palette) {
	pos := Vec2i{PADDING, PADDING}
	size: i32 = 32
	for i in 0 ..< len(p.colors) / PALETTE_WIDTH {
		rl.DrawRectangle(pos.x + i32(i) * size, pos.y, size, size, p.colors[i])
		rl.DrawRectangleLines(pos.x + i32(i) * size - 1, pos.y - 1, size + 2, size + 2, rl.YELLOW)
	}
}

Brush_draw_info :: proc(b: Brush, sc_w, sc_h: i32) {
	pos := Vec2i{PADDING, sc_h - PADDING} // 左下角
	size: i32 = 32

	// foreground and background color
	rl.DrawRectangle(pos.x, pos.y - size, size, size, brush.f_color)
	rl.DrawRectangleLines(pos.x - 1, pos.y - size - 1, size + 2, size + 2, rl.YELLOW)

	rl.DrawRectangle(pos.x, pos.y - size * 2 - PADDING, size, size, brush.b_color)
	rl.DrawRectangleLines(pos.x - 1, pos.y - size * 2 - PADDING - 1, size + 2, size + 2, rl.YELLOW)

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
	Hand,
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

		// handle mouse input

		if rl.IsMouseButtonDown(.RIGHT) {
		}


		Canvas_draw_to_screen(&canvas)
		Palette_draw_to_screen(&palette)
		Brush_draw_info(brush, sc_w, sc_h)
		draw_debug_info()

		rl.EndDrawing()

		switch tool {
		case .Pencil:
			rl.DrawText("Tool: Pencil", PADDING, PADDING + 32, FONT_SIZE, rl.GREEN)
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
				// only in canvas area can draw
				cx := (p.x - canvas.pos_sc.x) * 100 / canvas.scale
				cy := (p.y - canvas.pos_sc.y) * 100 / canvas.scale
				if rl.IsMouseButtonDown(.LEFT) {
					Canvas_Brush_draw(&canvas, cx, cy, brush)
				} else if rl.IsMouseButtonDown(.RIGHT) {
					Canvas_Brush_draw(
						&canvas,
						cx,
						cy,
						Brush{f_color = brush.b_color, b_color = brush.f_color, size = brush.size},
					)
				}
			}
		case .Hand:
			rl.DrawText("Tool: Hand", PADDING, PADDING + 32, FONT_SIZE, rl.GREEN)
			if rl.IsMouseButtonDown(.LEFT) {
				canvas.pos_sc.x += i32(rl.GetMouseDelta().x)
				canvas.pos_sc.y += i32(rl.GetMouseDelta().y)
			}
			d := rl.GetMouseWheelMove()
			if canvas.scale > MIN_CANVAS_SCALE && d < 0 {
				canvas.scale += i32(d * 100)
			} else if (MAX_CANVAS_SCALE < 0 || canvas.scale < MAX_CANVAS_SCALE) && d > 0 {
				canvas.scale += i32(d * 100)
			}

		case .Picker:
			rl.DrawText("Tool: Picker", PADDING, PADDING + 32, FONT_SIZE, rl.GREEN)
			if rl.IsMouseButtonDown(.LEFT) {
				rl.DrawText(
					fmt.ctprintf("Picker: %d, %d", p.x, p.y),
					PADDING,
					PADDING + FONT_SIZE * 2,
					FONT_SIZE,
					rl.YELLOW,
				)
				brush.f_color = rl.GetImageColor(rl.LoadImageFromScreen(), p.x, p.y)
			}
		case:
			rl.DrawText("Tool: Unknown", PADDING, PADDING + 32, FONT_SIZE, rl.RED)
		}


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
	} else if rl.IsKeyDown(.LEFT_CONTROL) || rl.IsKeyDown(.RIGHT_CONTROL) {
		tool = .Hand

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

	rl.DrawText(
		fmt.ctprintf("Canvas Scale: %d%%", canvas.scale),
		PADDING,
		PADDING + FONT_SIZE * 3,
		FONT_SIZE,
		rl.YELLOW,
	)

}
