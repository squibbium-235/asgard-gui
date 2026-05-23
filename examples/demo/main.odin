// initial Asgard/Odin Demo

package main

import "core:fmt"
import gui "../../src/asgard"

build_demo_ui :: proc(ctx: ^gui.Context, click_count: ^int, enabled: ^bool, volume: ^f32, progress: ^f32) {
	s := ctx.style

	sidebar := gui.Rect {20, 20, 220, 560}
	topbar  := gui.Rect {260, 20, 680, 72}
	main    := gui.Rect {260, 112, 680, 468}

	gui.rounded_rect(ctx, sidebar, s.large_radius, s.surface)
	gui.outline_rounded_rect(ctx, sidebar, s.large_radius, s.border)
	gui.text_at(ctx, {sidebar.x + 22, sidebar.y + 24}, "Asgard GUI", s.text)
	gui.text_at(ctx, {sidebar.x + 22, sidebar.y + 48}, "Odin + SDL3", s.text_muted)

	nav_y := sidebar.y + 96
	gui.nav_item(ctx, {sidebar.x + 14, nav_y,       sidebar.w - 28, 42}, "Dashboard", true)
	gui.nav_item(ctx, {sidebar.x + 14, nav_y + 50,  sidebar.w - 28, 42}, "Widgets", false)
	gui.nav_item(ctx, {sidebar.x + 14, nav_y + 100, sidebar.w - 28, 42}, "Themes", false)
	gui.nav_item(ctx, {sidebar.x + 14, nav_y + 150, sidebar.w - 28, 42}, "Examples", false)
	gui.text_at(ctx, {sidebar.x + 22, sidebar.y + sidebar.h - 44}, "v0.0.1 bootstrap", s.text_muted)

	gui.rounded_rect(ctx, topbar, s.large_radius, s.surface)
	gui.outline_rounded_rect(ctx, topbar, s.large_radius, s.border)
	gui.text_at(ctx, {topbar.x + 22, topbar.y + 18}, "Reusable package demo", s.text)
	gui.text_at(ctx, {topbar.x + 22, topbar.y + 43}, "This app imports Asgard GUI from src/asgard.", s.text_muted)
	gui.rounded_rect(ctx, {topbar.x + topbar.w - 144, topbar.y + 18, 116, 36}, s.medium_radius, s.accent)
	gui.text_at(ctx, {topbar.x + topbar.w - 119, topbar.y + 30}, "Library", s.text)

	gui.card_begin(ctx, main)
	defer gui.card_end(ctx)

	gui.label(ctx, "Asgard GUI is now an importable Odin package")
	gui.muted_label(ctx, "The demo app lives separately from the library code. Shocking discipline.")
	gui.spacer(ctx, 8)

	if gui.accent_button(ctx, "Primary action") {
		click_count^ += 1
	}

	if gui.button(ctx, "Secondary action") {
		fmt.println("Secondary action clicked")
	}

	gui.separator(ctx)

	if gui.checkbox(ctx, "Enable very serious option", enabled) {
		fmt.println("Checkbox changed")
	}

	if gui.slider_f32(ctx, "Volume", volume, 0, 1) {
		fmt.println("Slider changed")
	}

	gui.progress_bar(ctx, progress^, "Progress")

	gui.spacer(ctx, 10)

	gui.spacer(ctx, 10)

	stat_y := main.y + 230
	gui.stat_card(ctx, {main.x + 22,  stat_y, 190, 92}, "Clicks", fmt.ctprintf("%i", click_count^))
	gui.stat_card(ctx, {main.x + 236, stat_y, 190, 92}, "Backend", "SDL3")
	gui.stat_card(ctx, {main.x + 450, stat_y, 190, 92}, "Mode", "Package")

}

main :: proc() {
	app, ok := gui.app_create("Asgard GUI Demo", 960, 600)
	if !ok {
		return
	}
	defer gui.app_destroy(app)

	click_count := 0
	enabled := true
	volume: f32 = 0.35
	progress: f32 = 0.62

	for gui.app_running(app) {
		gui.app_begin_frame(app)
		build_demo_ui(gui.app_context(app), &click_count, &enabled, &volume, &progress)
		gui.app_end_frame(app)
	}
}
