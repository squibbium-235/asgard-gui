package asgard

import sdl "vendor:sdl3"

// Per-frame state and SDL event processing.
//
// This file turns SDL input events into Asgard's simpler input state.

// Resets one-frame input flags before polling events.
input_begin_frame :: proc(ctx: ^Context) {
	ctx.input.mouse_pressed  = false
	ctx.input.mouse_released = false
	ctx.input.quit_requested = false
}

// Resets UI state for a new frame.
ui_begin_frame :: proc(ctx: ^Context) {
	ctx.hot           = 0
	ctx.next_id       = 1
	ctx.command_count = 0
	ctx.layout_count  = 0
}

// Finalises widget interaction state at the end of a frame.
ui_end_frame :: proc(ctx: ^Context) {
	if ctx.input.mouse_released {
		ctx.active = 0
	}
}

// Polls SDL events and updates the context input state.
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