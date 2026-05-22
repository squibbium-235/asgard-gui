package asgard

import "core:fmt"
import "core:math"
import sdl "vendor:sdl3"

MAX_DRAW_COMMANDS :: 4096
MAX_LAYOUT_STACK  :: 32

Vec2 :: struct {
	x, y: f32,
}

Rect :: struct {
	x, y, w, h: f32,
}

Color :: struct {
	r, g, b, a: f32,
}

Draw_Kind :: enum {
	Rect,
	Rounded_Rect,
	Outline_Rounded_Rect,
	Text,
}

Draw_Command :: struct {
	kind:   Draw_Kind,
	rect:   Rect,
	pos:    Vec2,
	color:  Color,
	text:   cstring,
	radius: f32,
}

Input :: struct {
	mouse_pos:      Vec2,
	mouse_down:     bool,
	mouse_pressed:  bool,
	mouse_released: bool,
	quit_requested: bool,
}

Layout :: struct {
	cursor:  Vec2,
	width:   f32,
	spacing: f32,
}

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

App :: struct {
	window:   ^sdl.Window,
	renderer: ^sdl.Renderer,
	ctx:      ^Context,
	running:  bool,
}

// -----------------------------------------------------------------------------
// App lifecycle
// -----------------------------------------------------------------------------

app_create :: proc(title: cstring, width, height: i32) -> (^App, bool) {
	if !sdl.SetAppMetadata("Asgard GUI", "0.0.1", "https://example.invalid/asgard-gui") {
		fmt.eprintln("Warning: failed to set SDL app metadata")
	}

	if !sdl.Init({.VIDEO}) {
		fmt.eprintln("SDL init failed:", sdl.GetError())
		return nil, false
	}

	window := sdl.CreateWindow(title, width, height, {.RESIZABLE})
	if window == nil {
		fmt.eprintln("Window creation failed:", sdl.GetError())
		sdl.Quit()
		return nil, false
	}

	renderer := sdl.CreateRenderer(window, nil)
	if renderer == nil {
		fmt.eprintln("Renderer creation failed:", sdl.GetError())
		sdl.DestroyWindow(window)
		sdl.Quit()
		return nil, false
	}

	sdl.SetRenderVSync(renderer, 1)

	ctx := context_create()
	if ctx == nil {
		sdl.DestroyRenderer(renderer)
		sdl.DestroyWindow(window)
		sdl.Quit()
		return nil, false
	}

	app := new(App)
	app.window = window
	app.renderer = renderer
	app.ctx = ctx
	app.running = true

	return app, true
}

app_destroy :: proc(app: ^App) {
	if app == nil {
		return
	}

	if app.ctx != nil {
		context_destroy(app.ctx)
	}

	if app.renderer != nil {
		sdl.DestroyRenderer(app.renderer)
	}

	if app.window != nil {
		sdl.DestroyWindow(app.window)
	}

	sdl.Quit()
	free(app)
}

app_context :: proc(app: ^App) -> ^Context {
	return app.ctx
}

app_running :: proc(app: ^App) -> bool {
	return app != nil && app.running && !app.ctx.input.quit_requested
}

app_begin_frame :: proc(app: ^App) {
	ctx := app.ctx
	input_begin_frame(ctx)
	poll_sdl_events(ctx)
	ui_begin_frame(ctx)
}

app_end_frame :: proc(app: ^App) {
	ctx := app.ctx
	s := ctx.style

	sdl.SetRenderDrawColorFloat(app.renderer, s.background.r, s.background.g, s.background.b, s.background.a)
	sdl.RenderClear(app.renderer)

	render_commands(app.renderer, ctx)
	sdl.RenderPresent(app.renderer)

	ui_end_frame(ctx)

	// Clear temp allocations used by fmt.ctprintf in demos/widgets.
	free_all(context.temp_allocator)
}

app_quit :: proc(app: ^App) {
	if app != nil {
		app.running = false
	}
}

// -----------------------------------------------------------------------------
// Context/style
// -----------------------------------------------------------------------------

context_create :: proc() -> ^Context {
	ctx := new(Context)
	ctx.style = default_style()
	return ctx
}

context_destroy :: proc(ctx: ^Context) {
	if ctx != nil {
		free(ctx)
	}
}

default_style :: proc() -> Style {
	return Style {
		background    = {0.045, 0.050, 0.065, 1.0},
		surface       = {0.075, 0.083, 0.105, 1.0},
		surface_2     = {0.100, 0.110, 0.138, 1.0},
		surface_3     = {0.135, 0.150, 0.185, 1.0},
		border        = {0.200, 0.220, 0.270, 1.0},
		text          = {0.925, 0.940, 0.970, 1.0},
		text_muted    = {0.570, 0.610, 0.680, 1.0},
		accent        = {0.365, 0.525, 0.980, 1.0},
		accent_hot    = {0.450, 0.605, 1.000, 1.0},
		accent_active = {0.245, 0.395, 0.820, 1.0},
		button        = {0.145, 0.160, 0.200, 1.0},
		button_hot    = {0.185, 0.205, 0.255, 1.0},
		button_active = {0.115, 0.130, 0.165, 1.0},
		shadow        = {0.000, 0.000, 0.000, 0.240},
		padding       = 18,
		spacing       = 12,
		widget_height = 38,
		large_radius  = 18,
		medium_radius = 12,
		small_radius  = 8,
	}
}

// -----------------------------------------------------------------------------
// Frame/input internals
// -----------------------------------------------------------------------------

input_begin_frame :: proc(ctx: ^Context) {
	ctx.input.mouse_pressed  = false
	ctx.input.mouse_released = false
	ctx.input.quit_requested = false
}

ui_begin_frame :: proc(ctx: ^Context) {
	ctx.hot           = 0
	ctx.next_id       = 1
	ctx.command_count = 0
	ctx.layout_count  = 0
}

ui_end_frame :: proc(ctx: ^Context) {
	if ctx.input.mouse_released {
		ctx.active = 0
	}
}

poll_sdl_events :: proc(ctx: ^Context) {
	for e: sdl.Event; sdl.PollEvent(&e); {
		#partial switch e.type {
		case .QUIT, .WINDOW_CLOSE_REQUESTED:
			ctx.input.quit_requested = true

		case .KEY_DOWN:
			if e.key.key == sdl.K_ESCAPE {
				ctx.input.quit_requested = true
			}

		case .MOUSE_MOTION:
			ctx.input.mouse_pos = {e.motion.x, e.motion.y}

		case .MOUSE_BUTTON_DOWN:
			if e.button.button == sdl.BUTTON_LEFT {
				ctx.input.mouse_down    = true
				ctx.input.mouse_pressed = true
				ctx.input.mouse_pos     = {e.button.x, e.button.y}
			}

		case .MOUSE_BUTTON_UP:
			if e.button.button == sdl.BUTTON_LEFT {
				ctx.input.mouse_down     = false
				ctx.input.mouse_released = true
				ctx.input.mouse_pos      = {e.button.x, e.button.y}
			}
		}
	}
}

// -----------------------------------------------------------------------------
// Draw command API
// -----------------------------------------------------------------------------

rect_contains :: proc(r: Rect, p: Vec2) -> bool {
	return p.x >= r.x && p.x <= r.x + r.w && p.y >= r.y && p.y <= r.y + r.h
}

push_command :: proc(ctx: ^Context, cmd: Draw_Command) {
	if ctx.command_count >= MAX_DRAW_COMMANDS {
		return
	}
	ctx.commands[ctx.command_count] = cmd
	ctx.command_count += 1
}

rect :: proc(ctx: ^Context, r: Rect, color: Color) {
	push_command(ctx, Draw_Command {kind = .Rect, rect = r, color = color})
}

rounded_rect :: proc(ctx: ^Context, r: Rect, radius: f32, color: Color) {
	push_command(ctx, Draw_Command {kind = .Rounded_Rect, rect = r, radius = radius, color = color})
}

outline_rounded_rect :: proc(ctx: ^Context, r: Rect, radius: f32, color: Color) {
	push_command(ctx, Draw_Command {kind = .Outline_Rounded_Rect, rect = r, radius = radius, color = color})
}

text_at :: proc(ctx: ^Context, pos: Vec2, text: cstring, color: Color) {
	push_command(ctx, Draw_Command {kind = .Text, pos = pos, text = text, color = color})
}

// -----------------------------------------------------------------------------
// Layout
// -----------------------------------------------------------------------------

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

end_column :: proc(ctx: ^Context) {
	if ctx.layout_count > 0 {
		ctx.layout_count -= 1
	}
}

next_rect :: proc(ctx: ^Context, height: f32) -> Rect {
	if ctx.layout_count <= 0 {
		return {0, 0, 0, 0}
	}

	layout := &ctx.layout_stack[ctx.layout_count - 1]
	r := Rect {layout.cursor.x, layout.cursor.y, layout.width, height}
	layout.cursor.y += height + layout.spacing
	return r
}

spacer :: proc(ctx: ^Context, height: f32) {
	_ = next_rect(ctx, height)
}

// -----------------------------------------------------------------------------
// Widgets
// -----------------------------------------------------------------------------

next_widget_id :: proc(ctx: ^Context) -> u64 {
	id := ctx.next_id
	ctx.next_id += 1
	return id
}

label :: proc(ctx: ^Context, text: cstring) {
	r := next_rect(ctx, 20)
	text_at(ctx, {r.x, r.y + 3}, text, ctx.style.text)
}

muted_label :: proc(ctx: ^Context, text: cstring) {
	r := next_rect(ctx, 20)
	text_at(ctx, {r.x, r.y + 3}, text, ctx.style.text_muted)
}

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

button :: proc(ctx: ^Context, text: cstring) -> bool {
	return button_ex(ctx, text, false)
}

accent_button :: proc(ctx: ^Context, text: cstring) -> bool {
	return button_ex(ctx, text, true)
}

card_begin :: proc(ctx: ^Context, bounds: Rect) {
	rounded_rect(ctx, {bounds.x + 4, bounds.y + 6, bounds.w, bounds.h}, ctx.style.large_radius, ctx.style.shadow)
	rounded_rect(ctx, bounds, ctx.style.large_radius, ctx.style.surface)
	outline_rounded_rect(ctx, bounds, ctx.style.large_radius, ctx.style.border)
	begin_column(ctx, bounds)
}

card_end :: proc(ctx: ^Context) {
	end_column(ctx)
}

nav_item :: proc(ctx: ^Context, bounds: Rect, text: cstring, selected: bool) {
	if selected {
		rounded_rect(ctx, bounds, ctx.style.medium_radius, ctx.style.surface_3)
		rect(ctx, {bounds.x, bounds.y + 8, 3, bounds.h - 16}, ctx.style.accent)
	} else if rect_contains(bounds, ctx.input.mouse_pos) {
		rounded_rect(ctx, bounds, ctx.style.medium_radius, ctx.style.surface_2)
	}
	text_at(ctx, {bounds.x + 14, bounds.y + 12}, text, ctx.style.text)
}

stat_card :: proc(ctx: ^Context, r: Rect, title: cstring, value: cstring) {
	rounded_rect(ctx, {r.x + 3, r.y + 5, r.w, r.h}, ctx.style.medium_radius, ctx.style.shadow)
	rounded_rect(ctx, r, ctx.style.medium_radius, ctx.style.surface_2)
	outline_rounded_rect(ctx, r, ctx.style.medium_radius, ctx.style.border)
	text_at(ctx, {r.x + 16, r.y + 16}, title, ctx.style.text_muted)
	text_at(ctx, {r.x + 16, r.y + 42}, value, ctx.style.text)
}

// -----------------------------------------------------------------------------
// SDL3 renderer backend
// -----------------------------------------------------------------------------

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
