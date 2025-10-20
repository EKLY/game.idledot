extends Camera2D
class_name CameraController

# Camera controller for mobile touch input
# Handles touch pan, pinch zoom, and keyboard controls

# Camera properties
var zoom_min: float = 0.3
var zoom_max: float = 2.0
var zoom_speed: float = 0.1
var pan_speed: float = 1.0

# Touch/Pan state
var is_panning: bool = false
var pan_start_position: Vector2 = Vector2.ZERO
var camera_start_position: Vector2 = Vector2.ZERO

# Pinch zoom state
var is_pinch_zooming: bool = false
var pinch_start_distance: float = 0.0
var pinch_start_zoom: Vector2 = Vector2.ONE
var pinch_center: Vector2 = Vector2.ZERO

# Active touches
var active_touches: Dictionary = {}  # {index: position}

# Bounds (optional)
var use_bounds: bool = false
var bounds_min: Vector2 = Vector2(-2000, -2000)
var bounds_max: Vector2 = Vector2(2000, 2000)

func _ready():
	# Set initial zoom
	zoom = Vector2(0.8, 0.8)

func _input(event):
	# Handle touch input
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

	# Mouse input (for desktop testing)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_start_pan(event.position)
			else:
				_end_pan()

	elif event is InputEventMouseMotion and is_panning:
		_update_pan(event.position)

func _process(_delta):
	# Keyboard pan (for desktop testing)
	var pan_direction = Vector2.ZERO

	if Input.is_action_pressed("ui_left"):
		pan_direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		pan_direction.x += 1
	if Input.is_action_pressed("ui_up"):
		pan_direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		pan_direction.y += 1

	if pan_direction.length() > 0:
		position += pan_direction.normalized() * pan_speed * 10.0 / zoom.x
		_apply_bounds()

# Handle touch events
func _handle_touch(event: InputEventScreenTouch):
	if event.pressed:
		active_touches[event.index] = event.position

		# Single touch - start panning
		if active_touches.size() == 1:
			_start_pan(event.position)
			is_pinch_zooming = false

		# Two touches - start pinch zoom
		elif active_touches.size() == 2:
			_end_pan()
			_start_pinch_zoom()
	else:
		active_touches.erase(event.index)

		# Release pinch zoom
		if active_touches.size() < 2:
			is_pinch_zooming = false

		# Continue panning if one touch remains
		if active_touches.size() == 1:
			var remaining_touch = active_touches.values()[0]
			_start_pan(remaining_touch)
		else:
			_end_pan()

# Handle drag events
func _handle_drag(event: InputEventScreenDrag):
	active_touches[event.index] = event.position

	if is_pinch_zooming and active_touches.size() >= 2:
		_update_pinch_zoom()
	elif is_panning and active_touches.size() == 1:
		_update_pan(event.position)

# Start pinch zoom
func _start_pinch_zoom():
	if active_touches.size() != 2:
		return

	is_pinch_zooming = true
	var touches = active_touches.values()
	pinch_start_distance = touches[0].distance_to(touches[1])
	pinch_start_zoom = zoom
	pinch_center = (touches[0] + touches[1]) / 2.0

# Update pinch zoom
func _update_pinch_zoom():
	if active_touches.size() != 2:
		return

	var touches = active_touches.values()
	var current_distance = touches[0].distance_to(touches[1])

	if pinch_start_distance > 0:
		var zoom_factor = current_distance / pinch_start_distance
		var new_zoom_value = pinch_start_zoom.x * zoom_factor
		new_zoom_value = clamp(new_zoom_value, zoom_min, zoom_max)
		zoom = Vector2(new_zoom_value, new_zoom_value)
		_apply_bounds()  # Apply bounds after zoom change

# Zoom camera by delta
func _zoom_camera(delta: float):
	var new_zoom = zoom.x + delta
	new_zoom = clamp(new_zoom, zoom_min, zoom_max)
	zoom = Vector2(new_zoom, new_zoom)
	_apply_bounds()  # Apply bounds after zoom change

# Start panning
func _start_pan(touch_pos: Vector2):
	is_panning = true
	pan_start_position = touch_pos
	camera_start_position = position

# Update panning
func _update_pan(touch_pos: Vector2):
	var delta = (pan_start_position - touch_pos) / zoom.x
	position = camera_start_position + delta
	_apply_bounds()

# End panning
func _end_pan():
	is_panning = false

# Apply camera bounds (accounting for viewport and zoom)
func _apply_bounds():
	if use_bounds:
		# Get viewport size
		var viewport_size = get_viewport_rect().size

		# Calculate visible area at current zoom
		var visible_width = viewport_size.x / zoom.x / 2.0
		var visible_height = viewport_size.y / zoom.y / 2.0

		# Adjust bounds based on visible area
		var adjusted_min_x = bounds_min.x + visible_width
		var adjusted_max_x = bounds_max.x - visible_width
		var adjusted_min_y = bounds_min.y + visible_height
		var adjusted_max_y = bounds_max.y - visible_height

		# Ensure min < max (in case viewport is larger than bounds)
		if adjusted_min_x > adjusted_max_x:
			adjusted_min_x = (bounds_min.x + bounds_max.x) / 2.0
			adjusted_max_x = adjusted_min_x
		if adjusted_min_y > adjusted_max_y:
			adjusted_min_y = (bounds_min.y + bounds_max.y) / 2.0
			adjusted_max_y = adjusted_min_y

		position.x = clamp(position.x, adjusted_min_x, adjusted_max_x)
		position.y = clamp(position.y, adjusted_min_y, adjusted_max_y)

# Set camera bounds
func set_bounds(min_pos: Vector2, max_pos: Vector2):
	bounds_min = min_pos
	bounds_max = max_pos
	use_bounds = true

# Disable bounds
func disable_bounds():
	use_bounds = false

# Move camera to position with animation
func move_to(target_pos: Vector2, duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

# Center camera on position
func center_on(target_pos: Vector2):
	position = target_pos
	_apply_bounds()
