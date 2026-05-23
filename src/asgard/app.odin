package asgard

import "core:fmt"
import sdl "vendor:sdl3"

// SDL3 application wrapper for Asgard GUI.
//
// This layer owns the window, renderer, context, event polling, frame lifecycle,
// and shutdown. Higher-level apps should mostly interact with this file rather
// than calling SDL directly.

// A running Asgard GUI application backed by SDL3.
App :: struct {
	window:   ^sdl.Window,
	renderer: ^sdl.Renderer,
	ctx:      ^Context,
	running:  bool,
}

// Creates an SDL3 window, renderer, and Asgard GUI context.
//
// Returns the app and `true` on success. On failure, returns `nil` and `false`.
// The returned app must be destroyed with `app_destroy`.
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

// Destroys an app created with `app_create`.
//
// This frees the Asgard context, destroys the SDL renderer/window, and quits SDL.
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

// Returns the UI context owned by the app.
app_context :: proc(app: ^App) -> ^Context {
	return app.ctx
}

// Returns true while the app should continue running.
app_running :: proc(app: ^App) -> bool {
	return app != nil && app.running && !app.ctx.input.quit_requested
}

// Starts a new UI frame.
//
// This resets per-frame input state, polls SDL events, and prepares the UI
// context for building widgets.
app_begin_frame :: proc(app: ^App) {
	ctx := app.ctx
	input_begin_frame(ctx)
	poll_sdl_events(ctx)
	ui_begin_frame(ctx)
}

// Finishes the current UI frame.
//
// This clears the renderer, draws queued commands, presents the frame, and
// clears temporary allocations.
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

// Requests that the app stop running.
app_quit :: proc(app: ^App) {
	if app != nil {
		app.running = false
	}
}