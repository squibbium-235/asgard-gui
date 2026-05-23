package asgard

import "core:math"
import sdl "vendor:sdl3"

// SDL3 renderer backend.
//
// This file converts Asgard draw commands into SDL renderer calls. The current
// renderer is intentionally simple and should later be replaced or improved.

// Draws a filled rounded rectangle using SDL renderer primitives.
//
// This is a temporary software-style approximation, not a proper vector path.
render_filled_rounded_rect :: proc(renderer: ^sdl.Renderer, r: Rect, radius: f32) {
	if radius <= 0 {
		fr := sdl.FRect {r.x, r.y, r.w, r.h}
		sdl.RenderFillRect(renderer, &fr)
		return
	}

	rad := min(radius, min(r.w, r.h) * 0.5)
	ri  := i32(rad)

	middle := sdl.FRect {r.x + rad, r.y, r.w - rad * 2, r.h}
	sdl.RenderFillRect(renderer, &middle)

	vertical := sdl.FRect {r.x, r.y + rad, r.w, r.h - rad * 2}
	sdl.RenderFillRect(renderer, &vertical)

	for y in 0 ..= ri {
		dy := f32(y)
		dx := math.sqrt(rad * rad - dy * dy)
		strip_w := dx * 2

		top := sdl.FRect {
			r.x + rad - dx,
			r.y + rad - dy,
			strip_w + (r.w - rad * 2),
			1,
		}
		bottom := sdl.FRect {
			r.x + rad - dx,
			r.y + r.h - rad + dy,
			strip_w + (r.w - rad * 2),
			1,
		}

		sdl.RenderFillRect(renderer, &top)
		sdl.RenderFillRect(renderer, &bottom)
	}
}

// Draws a simple rounded rectangle outline.
//
// The current implementation uses simple edge rectangles and is not a perfect
// rounded stroke.
render_outline_rounded_rect :: proc(renderer: ^sdl.Renderer, r: Rect, radius: f32) {
	thickness: f32 = 1
	parts := [?]sdl.FRect {
		{r.x + radius, r.y, r.w - radius * 2, thickness},
		{r.x + radius, r.y + r.h - thickness, r.w - radius * 2, thickness},
		{r.x, r.y + radius, thickness, r.h - radius * 2},
		{r.x + r.w - thickness, r.y + radius, thickness, r.h - radius * 2},
	}

	for part in parts {
		p := part
		sdl.RenderFillRect(renderer, &p)
	}
}

// Renders all queued draw commands using the SDL3 renderer backend.
render_commands :: proc(renderer: ^sdl.Renderer, ctx: ^Context) {
	for i in 0 ..< ctx.command_count {
		cmd := ctx.commands[i]
		sdl.SetRenderDrawColorFloat(renderer, cmd.color.r, cmd.color.g, cmd.color.b, cmd.color.a)

		switch cmd.kind {
		case .Rect:
			r := sdl.FRect {cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h}
			sdl.RenderFillRect(renderer, &r)

		case .Rounded_Rect:
			render_filled_rounded_rect(renderer, cmd.rect, cmd.radius)

		case .Outline_Rounded_Rect:
			render_outline_rounded_rect(renderer, cmd.rect, cmd.radius)

		case .Text:
			sdl.RenderDebugText(renderer, cmd.pos.x, cmd.pos.y, cmd.text)
		}
	}
}
