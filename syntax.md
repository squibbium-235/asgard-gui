# Asgard GUI Syntax Reference

Current API reference for the early Asgard GUI bootstrap.

Import the library from the demo like this:

```odin
import gui "../../src/asgard"
```

Later, once this becomes a proper installed/shared package, the import path should become cleaner.

---

## Basic App Structure

```odin
package main

import gui "../../src/asgard"

main :: proc() {
    app, ok := gui.app_create("Asgard GUI Demo", 960, 600)
    if !ok {
        return
    }
    defer gui.app_destroy(app)

    for gui.app_running(app) {
        gui.app_begin_frame(app)

        ctx := gui.app_context(app)

        // Build UI here.

        gui.app_end_frame(app)
    }
}
```

---

## App Lifecycle

### `app_create`

Creates the SDL3 window, renderer, and Asgard context.

```odin
app, ok := gui.app_create("Window Title", 960, 600)
```

Signature:

```odin
app_create :: proc(title: cstring, width, height: i32) -> (^App, bool)
```

---

### `app_destroy`

Destroys the app, SDL renderer, SDL window, context, and quits SDL.

```odin
defer gui.app_destroy(app)
```

Signature:

```odin
app_destroy :: proc(app: ^App)
```

---

### `app_running`

Checks whether the app should keep running.

```odin
for gui.app_running(app) {
    // frame loop
}
```

Signature:

```odin
app_running :: proc(app: ^App) -> bool
```

---

### `app_begin_frame`

Polls SDL events and resets frame UI state.

```odin
gui.app_begin_frame(app)
```

Signature:

```odin
app_begin_frame :: proc(app: ^App)
```

---

### `app_end_frame`

Renders queued draw commands and presents the frame.

```odin
gui.app_end_frame(app)
```

Signature:

```odin
app_end_frame :: proc(app: ^App)
```

---

### `app_context`

Gets the current Asgard UI context.

```odin
ctx := gui.app_context(app)
```

Signature:

```odin
app_context :: proc(app: ^App) -> ^Context
```

---

### `app_quit`

Manually requests the app to stop running.

```odin
gui.app_quit(app)
```

Signature:

```odin
app_quit :: proc(app: ^App)
```

---

## Core Types

### `Vec2`

```odin
pos := gui.Vec2 {20, 40}
```

Fields:

```odin
Vec2 :: struct {
    x, y: f32,
}
```

---

### `Rect`

```odin
bounds := gui.Rect {20, 20, 300, 200}
```

Fields:

```odin
Rect :: struct {
    x, y, w, h: f32,
}
```

---

### `Color`

```odin
red := gui.Color {1.0, 0.0, 0.0, 1.0}
```

Fields:

```odin
Color :: struct {
    r, g, b, a: f32,
}
```

Values are floats from `0.0` to `1.0`.

---

### `Style`

Access through the context:

```odin
s := ctx.style
```

Useful fields:

```odin
s.background
s.surface
s.surface_2
s.surface_3
s.border
s.text
s.text_muted
s.accent
s.accent_hot
s.accent_active
s.button
s.button_hot
s.button_active
s.shadow

s.padding
s.spacing
s.widget_height
s.large_radius
s.medium_radius
s.small_radius
```

Example:

```odin
ctx.style.accent = gui.Color {0.8, 0.2, 0.9, 1.0}
```

---

## Drawing Primitives

These queue draw commands. They do not draw immediately.

### `rect`

Draws a filled rectangle.

```odin
gui.rect(ctx, gui.Rect {20, 20, 100, 60}, ctx.style.surface)
```

Signature:

```odin
rect :: proc(ctx: ^Context, r: Rect, color: Color)
```

---

### `rounded_rect`

Draws a filled rounded rectangle.

```odin
gui.rounded_rect(ctx, gui.Rect {20, 20, 160, 80}, 12, ctx.style.surface)
```

Signature:

```odin
rounded_rect :: proc(ctx: ^Context, r: Rect, radius: f32, color: Color)
```

---

### `outline_rounded_rect`

Draws a simple rounded rectangle outline.

```odin
gui.outline_rounded_rect(ctx, gui.Rect {20, 20, 160, 80}, 12, ctx.style.border)
```

Signature:

```odin
outline_rounded_rect :: proc(ctx: ^Context, r: Rect, radius: f32, color: Color)
```

---

### `text_at`

Draws text at a fixed position.

```odin
gui.text_at(ctx, gui.Vec2 {32, 48}, "Hello Asgard", ctx.style.text)
```

Signature:

```odin
text_at :: proc(ctx: ^Context, pos: Vec2, text: cstring, color: Color)
```

Note: this currently uses SDL debug text internally, so it is temporary and not proper font rendering yet.

---

## Layout

### `begin_column`

Starts a vertical layout column inside a rectangle.

```odin
gui.begin_column(ctx, gui.Rect {20, 20, 300, 400})
```

Signature:

```odin
begin_column :: proc(ctx: ^Context, bounds: Rect)
```

---

### `end_column`

Ends the current column.

```odin
gui.end_column(ctx)
```

Signature:

```odin
end_column :: proc(ctx: ^Context)
```

---

### `spacer`

Adds vertical spacing inside a column.

```odin
gui.spacer(ctx, 12)
```

Signature:

```odin
spacer :: proc(ctx: ^Context, height: f32)
```

---

## Text Widgets

These must be used inside a column/card layout.

### `label`

```odin
gui.label(ctx, "Asgard GUI")
```

Signature:

```odin
label :: proc(ctx: ^Context, text: cstring)
```

---

### `muted_label`

```odin
gui.muted_label(ctx, "A lightweight Odin GUI toolkit")
```

Signature:

```odin
muted_label :: proc(ctx: ^Context, text: cstring)
```

---

## Buttons

Buttons must be used inside a column/card layout.

### `button`

```odin
if gui.button(ctx, "Click me") {
    // clicked
}
```

Signature:

```odin
button :: proc(ctx: ^Context, text: cstring) -> bool
```

---

### `accent_button`

```odin
if gui.accent_button(ctx, "Primary action") {
    // clicked
}
```

Signature:

```odin
accent_button :: proc(ctx: ^Context, text: cstring) -> bool
```

---

### `button_ex`

Lower-level button call with an accent toggle.

```odin
if gui.button_ex(ctx, "Save", true) {
    // clicked
}
```

Signature:

```odin
button_ex :: proc(ctx: ^Context, text: cstring, accent: bool = false) -> bool
```

---

## Cards and Panels

### `card_begin`

Starts a rounded card and begins an internal column layout.

```odin
gui.card_begin(ctx, gui.Rect {260, 112, 680, 468})
defer gui.card_end(ctx)
```

Signature:

```odin
card_begin :: proc(ctx: ^Context, bounds: Rect)
```

---

### `card_end`

Ends the card layout.

```odin
gui.card_end(ctx)
```

Signature:

```odin
card_end :: proc(ctx: ^Context)
```

---

## Demo/Utility Widgets

These are currently useful for demos, but may later move or change.

### `nav_item`

Draws a sidebar navigation item.

```odin
gui.nav_item(ctx, gui.Rect {34, 116, 192, 42}, "Dashboard", true)
```

Signature:

```odin
nav_item :: proc(ctx: ^Context, bounds: Rect, text: cstring, selected: bool)
```

---

### `stat_card`

Draws a small card with a title and value.

```odin
gui.stat_card(ctx, gui.Rect {282, 342, 190, 92}, "Clicks", "5")
```

Signature:

```odin
stat_card :: proc(ctx: ^Context, r: Rect, title: cstring, value: cstring)
```

With formatted values:

```odin
gui.stat_card(ctx, bounds, "Clicks", fmt.ctprintf("%i", click_count))
```

---

## Example UI

```odin
build_ui :: proc(ctx: ^gui.Context, count: ^int) {
    main := gui.Rect {260, 112, 680, 468}

    gui.card_begin(ctx, main)
    defer gui.card_end(ctx)

    gui.label(ctx, "Asgard GUI")
    gui.muted_label(ctx, "Reusable Odin GUI package")
    gui.spacer(ctx, 8)

    if gui.accent_button(ctx, "Primary action") {
        count^ += 1
    }

    if gui.button(ctx, "Secondary action") {
        // clicked
    }

    gui.stat_card(
        ctx,
        gui.Rect {main.x + 22, main.y + 230, 190, 92},
        "Clicks",
        fmt.ctprintf("%i", count^),
    )
}
```

---

## Current Limitations

- Text rendering uses `SDL_RenderDebugText`.
- No real font loading yet.
- No text input widget yet.
- No checkboxes/sliders yet.
- No proper flex/grid layout yet.
- No clipping or scroll views yet.
- Widget IDs are generated from call order, so dynamic UI will need a better ID system.
- Rendering is still SDL renderer based and intentionally simple.

---

## Likely Next API Additions

```odin
gui.textbox(ctx, &text)
gui.checkbox(ctx, "Enabled", &enabled)
gui.slider_f32(ctx, "Volume", &value, 0.0, 1.0)
gui.begin_row(ctx, bounds)
gui.end_row(ctx)
gui.scroll_area_begin(ctx, bounds)
gui.scroll_area_end(ctx)
gui.set_theme(ctx, theme)
```
