package asgard

// Built-in Asgard GUI widgets.
//
// Widgets are immediate-style calls backed by persistent per-frame interaction
// state in the context.

// Returns the next temporary widget ID for this frame.
//
// This is currently based on call order. A stable scoped ID system should
// replace this before dynamic UI becomes serious.
next_widget_id :: proc(ctx: ^Context) -> u64 {
	id := ctx.next_id
	ctx.next_id += 1
	return id
}

// Displays a normal text label inside the active layout.
label :: proc(ctx: ^Context, text: cstring) {
	r := next_rect(ctx, 20)
	text_at(ctx, {r.x, r.y + 3}, text, ctx.style.text)
}

// Displays a muted secondary text label inside the active layout.
muted_label :: proc(ctx: ^Context, text: cstring) {
	r := next_rect(ctx, 20)
	text_at(ctx, {r.x, r.y + 3}, text, ctx.style.text_muted)
}

// Draws a horizontal separator line inside the active layout.
separator :: proc(ctx: ^Context) {
	r := next_rect(ctx, 12)
	rect(ctx, {r.x, r.y + 6, r.w, 1}, ctx.style.border)
}

// Displays a checkbox bound to a boolean value.
//
// Returns true when the value changes.
checkbox :: proc(ctx: ^Context, text: cstring, value: ^bool) -> bool {
	id := next_widget_id(ctx)
	r := next_rect(ctx, 32)

	box := Rect {r.x, r.y + 5, 22, 22}

	hovered := rect_contains(r, ctx.input.mouse_pos)
	if hovered {
		ctx.hot = id
	}

	if hovered && ctx.input.mouse_pressed {
		ctx.active = id
	}

	changed := false
	if ctx.input.mouse_released {
		if hovered && ctx.active == id {
			value^ = !value^
			changed = true
		}
		if ctx.active == id {
			ctx.active = 0
		}
	}

	box_color := ctx.style.button
	if ctx.hot == id {
		box_color = ctx.style.button_hot
	}
	if ctx.active == id {
		box_color = ctx.style.button_active
	}

	rounded_rect(ctx, box, ctx.style.small_radius, box_color)
	outline_rounded_rect(ctx, box, ctx.style.small_radius, ctx.style.border)

	if value^ {
		inner := Rect {box.x + 5, box.y + 5, box.w - 10, box.h - 10}
		rounded_rect(ctx, inner, 4, ctx.style.accent)
	}

	text_at(ctx, {r.x + 34, r.y + 10}, text, ctx.style.text)

	return changed
}

// Displays a toggle switch bound to a boolean value.
//
// Returns true when the value changes.
toggle :: proc(ctx: ^Context, text: cstring, value: ^bool) -> bool {
	id := next_widget_id(ctx)
	r  := next_rect(ctx, 36)

	switch_rect := Rect {r.x, r.y + 5, 52, 26}

	hovered := rect_contains(r, ctx.input.mouse_pos)
	if hovered {
		ctx.hot = id
	}

	if hovered && ctx.input.mouse_pressed {
		ctx.active = id
	}

	changed := false
	if ctx.input.mouse_released {
		if hovered && ctx.active == id {
			value^ = !value^
			changed = true
		}
		if ctx.active == id {
			ctx.active = 0
		}
	}

	bg := ctx.style.button
	if value^ {
		bg = ctx.style.accent
	}
	if ctx.hot == id && !value^ {
		bg = ctx.style.button_hot
	}
	if ctx.active == id && !value^ {
		bg = ctx.style.button_active
	}

	rounded_rect(ctx, switch_rect, 13, bg)

	knob_x := switch_rect.x + 4
	if value^ {
		knob_x = switch_rect.x + switch_rect.w - 22
	}

	knob := Rect {knob_x, switch_rect.y + 4, 18, 18}
	rounded_rect(ctx, knob, 9, ctx.style.text)

	text_at(ctx, {r.x + 66, r.y + 11}, text, ctx.style.text)

	return changed
}

// Displays a horizontal floating-point slider.
//
// The value is clamped between `min_value` and `max_value`.
// Returns true while the value changes.
slider_f32 :: proc(ctx: ^Context, text: cstring, value: ^f32, min_value, max_value: f32) -> bool {
	id := next_widget_id(ctx)
	r  := next_rect(ctx, 54)

	label_pos := Vec2 {r.x, r.y + 2}
	text_at(ctx, label_pos, text, ctx.style.text)

	track := Rect {r.x, r.y + 32, r.w, 8}
	hitbox := Rect {r.x, r.y + 22, r.w, 28}

	hovered := rect_contains(hitbox, ctx.input.mouse_pos)
	if hovered {
		ctx.hot = id
	}

	if hovered && ctx.input.mouse_pressed {
		ctx.active = id
	}

	changed := false

	range := max_value - min_value
	t: f32 = 0

	if range != 0 {
		t = (value^ - min_value) / range
	}

	t = clamp_f32(t, 0, 1)

	if ctx.active == id && ctx.input.mouse_down {
		mouse_t := (ctx.input.mouse_pos.x - track.x) / track.w
		mouse_t = clamp_f32(mouse_t, 0, 1)

		new_value := min_value + mouse_t * range

		if new_value != value^ {
			value^ = new_value
			changed = true
		}

		t = mouse_t
	}

	rounded_rect(ctx, track, 4, ctx.style.button)

	fill := Rect {track.x, track.y, track.w * t, track.h}
	if fill.w > 0 {
		rounded_rect(ctx, fill, 4, ctx.style.accent)
	}

	knob_x := track.x + track.w * t
	knob := Rect {knob_x - 7, track.y - 5, 18, 18}

	knob_color := ctx.style.surface_3
	if ctx.hot == id || ctx.active == id {
		knob_color = ctx.style.accent_hot
	}

	rounded_rect(ctx, knob, 9, knob_color)

	if ctx.input.mouse_released && ctx.active == id {
		ctx.active = 0
	}

	return changed
}

// Displays a progress bar with a value from 0.0 to 1.0.
progress_bar :: proc(ctx: ^Context, value: f32, label: cstring = nil) {
	r := next_rect(ctx, 34)

	t := clamp_f32(value, 0, 1)

	track := Rect {r.x, r.y + 10, r.w, 12}
	rounded_rect(ctx, track, 6, ctx.style.button)

	fill := Rect {track.x, track.y, track.w * t, track.h}
	if fill.w > 0 {
		rounded_rect(ctx, fill, 6, ctx.style.accent)
	}

	if label != nil {
		text_at(ctx, {r.x + 10, r.y + 9}, label, ctx.style.text)
	}
}

// Displays a button with optional accent styling.
//
// Returns true when clicked.
button_ex :: proc(ctx: ^Context, text: cstring, accent: bool = false) -> bool {
	id := next_widget_id(ctx)
	r  := next_rect(ctx, ctx.style.widget_height)

	hovered := rect_contains(r, ctx.input.mouse_pos)
	if hovered {
		ctx.hot = id
	}

	if hovered && ctx.input.mouse_pressed {
		ctx.active = id
	}

	clicked := false
	if ctx.input.mouse_released {
		if hovered && ctx.active == id {
			clicked = true
		}
		if ctx.active == id {
			ctx.active = 0
		}
	}

	color := ctx.style.button
	if accent {
		color = ctx.style.accent
	}

	if ctx.active == id {
		color = ctx.style.button_active
		if accent {
			color = ctx.style.accent_active
		}
	} else if ctx.hot == id {
		color = ctx.style.button_hot
		if accent {
			color = ctx.style.accent_hot
		}
	}

	rounded_rect(ctx, r, ctx.style.medium_radius, color)
	text_at(ctx, {r.x + 14, r.y + 12}, text, ctx.style.text)

	return clicked
}

// Displays a standard button.
//
// Returns true when clicked.
button :: proc(ctx: ^Context, text: cstring) -> bool {
	return button_ex(ctx, text, false)
}

// Displays a primary/accent button.
//
// Returns true when clicked.
accent_button :: proc(ctx: ^Context, text: cstring) -> bool {
	return button_ex(ctx, text, true)
}

// Begins a rounded card container and starts an internal column layout.
card_begin :: proc(ctx: ^Context, bounds: Rect) {
	rounded_rect(ctx, {bounds.x + 4, bounds.y + 6, bounds.w, bounds.h}, ctx.style.large_radius, ctx.style.shadow)
	rounded_rect(ctx, bounds, ctx.style.large_radius, ctx.style.surface)
	outline_rounded_rect(ctx, bounds, ctx.style.large_radius, ctx.style.border)
	begin_column(ctx, bounds)
}

// Ends the current card container layout.
card_end :: proc(ctx: ^Context) {
	end_column(ctx)
}

// Draws a sidebar navigation item.
//
// This is currently a demo/helper widget and may change.
nav_item :: proc(ctx: ^Context, bounds: Rect, text: cstring, selected: bool) {
	if selected {
		rounded_rect(ctx, bounds, ctx.style.medium_radius, ctx.style.surface_3)
		rect(ctx, {bounds.x, bounds.y + 8, 3, bounds.h - 16}, ctx.style.accent)
	} else if rect_contains(bounds, ctx.input.mouse_pos) {
		rounded_rect(ctx, bounds, ctx.style.medium_radius, ctx.style.surface_2)
	}
	text_at(ctx, {bounds.x + 14, bounds.y + 12}, text, ctx.style.text)
}

// Draws a small card containing a title and value.
//
// This is currently a demo/helper widget and may change.
stat_card :: proc(ctx: ^Context, r: Rect, title: cstring, value: cstring) {
	rounded_rect(ctx, {r.x + 3, r.y + 5, r.w, r.h}, ctx.style.medium_radius, ctx.style.shadow)
	rounded_rect(ctx, r, ctx.style.medium_radius, ctx.style.surface_2)
	outline_rounded_rect(ctx, r, ctx.style.medium_radius, ctx.style.border)
	text_at(ctx, {r.x + 16, r.y + 16}, title, ctx.style.text_muted)
	text_at(ctx, {r.x + 16, r.y + 42}, value, ctx.style.text)
}