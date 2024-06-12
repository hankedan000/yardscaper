extends Node2D

var pan_button = MOUSE_BUTTON_MIDDLE

var _dragging = false
var _drag_start = Vector2.ZERO
var _camera_original_position = Vector2.ZERO

const ZOOM_SPEED = 0.1
const MIN_ZOOM = 0.1
const MAX_ZOOM = 3.0

func _ready():
	# Connect mouse events
	set_process_input(true)

func get_xy_position_in_world(pos):
	var camera := get_viewport().get_camera_2d()
	var pos_rel_screen_center = pos - get_viewport_rect().size / 2.0
	var pos_in_world = camera.position
	pos_in_world.x += pos_rel_screen_center.x * (1.0 / camera.zoom.x)
	pos_in_world.y += pos_rel_screen_center.y * (1.0 / camera.zoom.y)
	return pos_in_world

func _input(event):
	var camera := get_viewport().get_camera_2d()
	if event is InputEventMouseButton:
		# Check if left mouse button is pressed
		match event.button_index:
			pan_button:
				if event.pressed:
					# Start dragging
					_dragging = true
					_drag_start = event.position
					_camera_original_position = camera.position
				else:
					# Stop dragging
					_dragging = false
			MOUSE_BUTTON_WHEEL_UP:
				zoom_in(event.position)
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom_out(event.position)

	elif event is InputEventMouseMotion:
		if _dragging:
			# Calculate drag distance and offset camera accordingly
			var drag_delta = (event.position - _drag_start) / camera.zoom.x
			camera.position = _camera_original_position - drag_delta

func zoom_in(mouse_pos: Vector2) -> void:
	_do_zoom(mouse_pos, ZOOM_SPEED)

func zoom_out(mouse_pos: Vector2) -> void:
	_do_zoom(mouse_pos, -ZOOM_SPEED)

func _do_zoom(mouse_pos, zoom_speed):
	var camera = get_viewport().get_camera_2d()
	var new_zoom = clamp(camera.zoom.x * (1 + zoom_speed), MIN_ZOOM, MAX_ZOOM)
	var mouse_pos_old = get_xy_position_in_world(mouse_pos)
	camera.zoom = Vector2(new_zoom, new_zoom)
	# Adjust camera position to keep the mouse position fixed
	var mouse_pos_new = get_xy_position_in_world(mouse_pos)
	var camera_offset = mouse_pos_old - mouse_pos_new
	camera.position += camera_offset
