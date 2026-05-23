package asgard

// Renderer-independent drawing helpers.
//
// Widgets call these functions to queue draw commands. Backend-specific code
// later consumes the command buffer.

// Returns true when a point lies inside a rectangle.
rect_contains :: proc(r: Rect, p: Vec2) -> bool {
	return p.x >= r.x && p.x <= r.x + r.w && p.y >= r.y && p.y <= r.y + r.h
}

// Clamps a `f32` value between a lower and upper bound.
clamp_f32 :: proc(v, lo, hi: f32) -> f32 {
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}

// Adds a draw command to the current frame command buffer.
push_command :: proc(ctx: ^Context, cmd: Draw_Command) {
	if ctx.command_count >= MAX_DRAW_COMMANDS {
		return
	}
	ctx.commands[ctx.command_count] = cmd
	ctx.command_count += 1
}

// Queues a filled rectangle draw command.
rect :: proc(ctx: ^Context, r: Rect, color: Color) {
	push_command(ctx, Draw_Command {kind = .Rect, rect = r, color = color})
}

// Queues a filled rounded rectangle draw command.
rounded_rect :: proc(ctx: ^Context, r: Rect, radius: f32, color: Color) {
	push_command(ctx, Draw_Command {kind = .Rounded_Rect, rect = r, radius = radius, color = color})
}

// Queues a rounded rectangle outline draw command.
outline_rounded_rect :: proc(ctx: ^Context, r: Rect, radius: f32, color: Color) {
	push_command(ctx, Draw_Command {kind = .Outline_Rounded_Rect, rect = r, radius = radius, color = color})
}

// Queues text at an absolute position.
//
// Text rendering currently uses SDL debug text internally and should be replaced
// with real font rendering later.
text_at :: proc(ctx: ^Context, pos: Vec2, text: cstring, color: Color) {
	push_command(ctx, Draw_Command {kind = .Text, pos = pos, text = text, color = color})
}