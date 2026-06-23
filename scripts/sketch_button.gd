@tool
extends Button
class_name SketchButton

## A bright, "juicy" rounded button that matches the game's hand-sketched look:
## a coloured face sitting on a darker base (a 3D lip), a wobbly pencil outline,
## and bold outlined text. Reusable anywhere — just set `color` per button.
## Pressing sinks the face down onto the base; toggling (toggle_mode) keeps it sunk.

@export var color: Color = Color("d9534f"):
	set(v):
		color = v
		queue_redraw()
@export var corner_radius: float = 16.0
# Height of the darker base peeking out below the face — the 3D depth.
@export var lip: float = 7.0
@export var text_color: Color = Color("fdf3e3")
@export var text_outline_color: Color = Color(0.34, 0.13, 0.1)
@export var text_outline_size: int = 6
# Label font for the button (display font). Falls back to the theme font if null.
@export var font: Font = preload("res://assets/fonts/slackey.ttf")
# Scales the drawn label size only — the button's own size is unchanged.
@export var font_scale: float = 1.5:
	set(v):
		font_scale = v
		queue_redraw()
@export var line_color: Color = Color(0.3, 0.12, 0.1, 0.9)
@export var line_width: float = 2.0
@export_range(0.0, 8.0) var wobble_amp: float = 2.0

var _noise := FastNoiseLite.new()

func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 1.0
	_noise.seed = 9
	# Hide the Button's own background + text so only our _draw shows (the Button
	# still handles clicks, hover, toggle and disabled states underneath).
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(s, StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		add_theme_color_override(c, Color.TRANSPARENT)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	toggled.connect(func(_p): queue_redraw())

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 4.0 or h < 4.0:
		return
	var face_h := h - lip
	var sunk := is_pressed()
	var face_y := lip if sunk else 0.0
	var base_col := color.darkened(0.4)
	var face_col := color
	if is_hovered() and not disabled and not sunk:
		face_col = color.lightened(0.06)
	if disabled:
		base_col = Color(0.46, 0.45, 0.42)
		face_col = Color(0.66, 0.64, 0.6)
	# Base fills the whole rect; the face covers all but the exposed lip.
	_round_fill(Rect2(0.0, 0.0, w, h), base_col)
	var face := Rect2(0.0, face_y, w, face_h)
	_round_fill(face, face_col)
	# Soft top sheen for the "candy" highlight.
	_round_fill(Rect2(face.position.x + 5.0, face.position.y + 5.0, face.size.x - 10.0, face.size.y * 0.34), Color(1, 1, 1, 0.16))
	_round_stroke(face, line_color)
	_draw_label(face)

func _draw_label(face: Rect2) -> void:
	if text == "":
		return
	var f: Font = font if font != null else get_theme_font("font")
	if f == null:
		return
	var fs := get_theme_font_size("font_size")
	if fs <= 0:
		fs = 20
	fs = int(round(fs * font_scale))
	var ts := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var pos := Vector2(
		face.position.x + (face.size.x - ts.x) * 0.5,
		face.position.y + face.size.y * 0.5 + (f.get_ascent(fs) - f.get_descent(fs)) * 0.5)
	var tc := text_color
	var oc := text_outline_color
	if disabled:
		tc = Color(0.52, 0.5, 0.47)
		oc = Color(0.4, 0.39, 0.36)
	var ci := get_canvas_item()
	if text_outline_size > 0:
		f.draw_string_outline(ci, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_outline_size, oc)
	f.draw_string(ci, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tc)

# --- rounded-rect helpers (wobbly, to match the sketch theme) --------------------

func _round_fill(rect: Rect2, col: Color) -> void:
	draw_colored_polygon(_round_pts(rect), col)

func _round_stroke(rect: Rect2, col: Color) -> void:
	var pts := _round_pts(rect)
	pts.append(pts[0])
	draw_polyline(pts, col, line_width, true)

# Rounded-rect outline, optionally resampled with a perpendicular pencil wobble.
func _round_pts(rect: Rect2) -> PackedVector2Array:
	var raw := _round_rect(rect, corner_radius)
	if wobble_amp <= 0.0:
		return raw
	var out := PackedVector2Array()
	var n := raw.size()
	var dist := 0.0
	for i in range(n):
		var a: Vector2 = raw[i]
		var b: Vector2 = raw[(i + 1) % n]
		var seg := a.distance_to(b)
		var steps := maxi(1, int(seg / 6.0))
		var tangent := (b - a).normalized()
		var perp := Vector2(-tangent.y, tangent.x)
		for k in range(steps):
			var p: Vector2 = a.lerp(b, float(k) / float(steps))
			out.append(p + perp * _noise.get_noise_2d(dist, rect.position.y) * wobble_amp)
			dist += seg / float(steps)
	return out

func _round_rect(rect: Rect2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var rad := clampf(radius, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
	if rad <= 0.5:
		pts.append(rect.position)
		pts.append(Vector2(rect.end.x, rect.position.y))
		pts.append(rect.end)
		pts.append(Vector2(rect.position.x, rect.end.y))
		return pts
	var c_tl := rect.position + Vector2(rad, rad)
	var c_tr := Vector2(rect.end.x - rad, rect.position.y + rad)
	var c_br := rect.end - Vector2(rad, rad)
	var c_bl := Vector2(rect.position.x + rad, rect.end.y - rad)
	_arc(pts, c_tl, rad, PI, PI * 1.5)
	_arc(pts, c_tr, rad, PI * 1.5, TAU)
	_arc(pts, c_br, rad, 0.0, PI * 0.5)
	_arc(pts, c_bl, rad, PI * 0.5, PI)
	return pts

func _arc(pts: PackedVector2Array, center: Vector2, radius: float, from_a: float, to_a: float) -> void:
	for i in range(6):
		var a := lerpf(from_a, to_a, float(i) / 5.0)
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
