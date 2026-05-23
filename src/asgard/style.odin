package asgard

// Context creation and default styling.
//
// The default theme is intentionally modern, dark, and tool-focused. Theme
// customisation should grow from this file later.

// Allocates and initialises a new Asgard GUI context.
context_create :: proc() -> ^Context {
	ctx := new(Context)
	ctx.style = default_style()
	return ctx
}

// Frees a context created with `context_create`.
context_destroy :: proc(ctx: ^Context) {
	if ctx != nil {
		free(ctx)
	}
}

// Returns the default Asgard GUI style.
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