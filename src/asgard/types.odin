package asgard

// Core data types shared across Asgard GUI.
//
// This file should stay mostly dependency-free. It defines the small value types,
// style data, draw command data, input state, layout state, and the main UI context.

MAX_DRAW_COMMANDS :: 4096
MAX_LAYOUT_STACK  :: 32

// A two-dimensional position or size value.
Vec2 :: struct {
	x, y: f32,
}

// A rectangle using top-left position and width/height.
Rect :: struct {
	x, y, w, h: f32,
}

// RGBA colour stored as floats in the range 0.0 to 1.0.
Color :: struct {
	r, g, b, a: f32,
}

// The type of draw command queued by the UI.
Draw_Kind :: enum {
	Rect,
	Rounded_Rect,
	Outline_Rounded_Rect,
	Text,
}

// A single renderer-independent drawing operation.
//
// Widgets add draw commands during the UI frame. The active backend later
// converts these into SDL draw calls.
Draw_Command :: struct {
	kind:   Draw_Kind,
	rect:   Rect,
	pos:    Vec2,
	color:  Color,
	text:   cstring,
	radius: f32,
}

// Per-frame input state used by widgets.
//
// `mouse_pressed` and `mouse_released` are true for one frame only.
// `mouse_down` stays true while the left mouse button is held.
Input :: struct {
	mouse_pos:      Vec2,
	mouse_down:     bool,
	mouse_pressed:  bool,
	mouse_released: bool,
	quit_requested: bool,
}

// The layout mode used by a layout stack entry.
Layout_Kind :: enum {
	Column,
	Row,
}

// A single layout stack entry.
//
// Layouts are pushed by containers such as columns, rows, and cards.
// Widgets consume space from the active layout using `next_rect`.
Layout :: struct {
	kind:       Layout_Kind,
	cursor:     Vec2,
	width:      f32,
	height:     f32,
	spacing:    f32,
	item_width: f32,
}

// Visual style values used by built-in widgets.
Style :: struct {
	background:       Color,
	surface:          Color,
	surface_2:        Color,
	surface_3:        Color,
	border:           Color,
	text:             Color,
	text_muted:       Color,
	accent:           Color,
	accent_hot:       Color,
	accent_active:    Color,
	button:           Color,
	button_hot:       Color,
	button_active:    Color,
	shadow:           Color,
	padding:          f32,
	spacing:          f32,
	widget_height:    f32,
	large_radius:     f32,
	medium_radius:    f32,
	small_radius:      f32,
}


// Main Asgard GUI state for one UI instance.
//
// A context owns input state, layout state, widget interaction state, style,
// and the draw command buffer for the current frame.
Context :: struct {
	input: Input,

	// Temporary bootstrap ID system. Later this needs scopes and stable IDs.
	next_id: u64,
	hot:     u64,
	active:  u64,

	style: Style,

	commands:      [MAX_DRAW_COMMANDS]Draw_Command,
	command_count: int,

	layout_stack: [MAX_LAYOUT_STACK]Layout,
	layout_count: int,
}