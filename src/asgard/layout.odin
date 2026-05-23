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
		kind    = .Column,
		cursor  = {bounds.x + pad, bounds.y + pad},
		width   = bounds.w - pad * 2,
		height  = bounds.h - pad * 2,
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

// Begins a horizontal row layout with equally sized items.
begin_row :: proc(ctx: ^Context, bounds: Rect, item_count: int) {
	if ctx.layout_count >= MAX_LAYOUT_STACK || item_count <= 0 {
		return
	}

	pad := ctx.style.padding

	available_width := bounds.w - pad * 2
	total_spacing := ctx.style.spacing * f32(item_count - 1)
	item_width := (available_width - total_spacing) / f32(item_count)

	ctx.layout_stack[ctx.layout_count] = Layout {
		kind       = .Row,
		cursor     = {bounds.x + pad, bounds.y + pad},
		width      = available_width,
		height     = bounds.h - pad * 2,
		spacing    = ctx.style.spacing,
		item_width = item_width,
	}

	ctx.layout_count += 1
}

// Ends the current row layout.
end_row :: proc(ctx: ^Context) {
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

	switch layout.kind {
	case .Column:
		r := Rect {layout.cursor.x, layout.cursor.y, layout.width, height}
		layout.cursor.y += height + layout.spacing
		return r

	case .Row:
		r := Rect {layout.cursor.x, layout.cursor.y, layout.item_width, layout.height}
		layout.cursor.x += layout.item_width + layout.spacing
		return r
	}

	return {0, 0, 0, 0}
}

// Consumes vertical layout space without drawing anything.
spacer :: proc(ctx: ^Context, height: f32) {
	_ = next_rect(ctx, height)
}