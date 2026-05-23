package asgard

// Simple stack-based layout system.
//
// Layouts are intentionally basic for now: columns and rows. Widgets ask the
// active layout for their rectangle using `next_rect`.

// Begins a vertical column layout inside the given bounds.
begin_column :: proc(ctx: ^Context, bounds: Rect) {
	if ctx.layout_count >= MAX_LAYOUT_STACK {
		return
	}

	pad := ctx.style.padding
	ctx.layout_stack[ctx.layout_count] = Layout {
		cursor  = {bounds.x + pad, bounds.y + pad},
		width   = bounds.w - pad * 2,
		spacing = ctx.style.spacing,
	}
	ctx.layout_count += 1
}

// Ends the current column layout.
end_column :: proc(ctx: ^Context) {
	if ctx.layout_count > 0 {
		ctx.layout_count -= 1
	}
}

// Returns the next widget rectangle from the active layout.
//
// In a column layout, this advances downward. In a row layout, this advances
// to the right.
next_rect :: proc(ctx: ^Context, height: f32) -> Rect {
	if ctx.layout_count <= 0 {
		return {0, 0, 0, 0}
	}

	layout := &ctx.layout_stack[ctx.layout_count - 1]
	r := Rect {layout.cursor.x, layout.cursor.y, layout.width, height}
	layout.cursor.y += height + layout.spacing
	return r
}

// Consumes vertical layout space without drawing anything.
spacer :: proc(ctx: ^Context, height: f32) {
	_ = next_rect(ctx, height)
}