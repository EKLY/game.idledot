class_name ThemeHelper
extends Object

static func build_theme() -> Theme:
	var theme := Theme.new()

	theme.default_font_size = 22

	var text_primary = Color(0.95, 0.98, 1.0, 1.0)
	var text_muted = Color(0.8, 0.9, 1.0, 1.0)
	var accent = Color(0.1, 0.6, 1.0, 1.0)
	var accent_dark = Color(0.05, 0.35, 0.7, 1.0)
	var panel_bg = Color(0.05, 0.18, 0.35, 0.9)

	theme.set_color("font_color", "Label", text_primary)
	theme.set_color("font_color", "Button", text_primary)
	theme.set_color("font_color_disabled", "Button", text_muted)
	theme.set_font_size("font_size", "Label", 22)
	theme.set_font_size("font_size", "Button", 22)

	var button_normal := StyleBoxFlat.new()
	button_normal.bg_color = accent
	button_normal.corner_radius_top_left = 12
	button_normal.corner_radius_top_right = 12
	button_normal.corner_radius_bottom_left = 12
	button_normal.corner_radius_bottom_right = 12
	button_normal.content_margin_left = 16
	button_normal.content_margin_right = 16
	button_normal.content_margin_top = 8
	button_normal.content_margin_bottom = 8

	var button_hover := button_normal.duplicate()
	button_hover.bg_color = Color(0.2, 0.7, 1.0, 1.0)

	var button_pressed := button_normal.duplicate()
	button_pressed.bg_color = accent_dark

	var button_disabled := button_normal.duplicate()
	button_disabled.bg_color = Color(0.2, 0.3, 0.4, 0.6)

	theme.set_stylebox("normal", "Button", button_normal)
	theme.set_stylebox("hover", "Button", button_hover)
	theme.set_stylebox("pressed", "Button", button_pressed)
	theme.set_stylebox("disabled", "Button", button_disabled)

	var panel := StyleBoxFlat.new()
	panel.bg_color = panel_bg
	panel.corner_radius_top_left = 16
	panel.corner_radius_top_right = 16
	panel.content_margin_left = 16
	panel.content_margin_right = 16
	panel.content_margin_top = 12
	panel.content_margin_bottom = 12
	theme.set_stylebox("panel", "PanelContainer", panel)

	return theme
