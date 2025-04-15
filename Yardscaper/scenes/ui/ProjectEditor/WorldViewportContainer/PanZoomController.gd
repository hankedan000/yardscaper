extends Node2D
class_name PanZoomController

signal pan_state_changed(panning: bool)
signal zoom_changed(old_zoom: float, new_zoom: float)

var _panning : bool = false:
	set(value):
		var old_value := _panning
		_panning = value
		if _panning != old_value:
			pan_state_changed.emit(_panning)
var _drag_start = Vector2.ZERO
var _camera_original_position = Vector2.ZERO

const ZOOM_SPEED = 0.1
const MIN_ZOOM = 0.1
const MAX_ZOOM = 3.0

# local position within viwport to world position
func local_pos_to_world(pos_local: Vector2) -> Vector2:
	var camera := get_viewport().get_camera_2d()
	var pos_rel_screen_center = pos_local - get_viewport_rect().size / 2.0
	return camera.position + Utils.global_to_world_size_px(pos_rel_screen_center, camera.zoom)

# world position within viwport to local position
func world_pos_to_local(pos_world: Vector2) -> Vector2:
	var camera := get_viewport().get_camera_2d()
	var offset_from_camera_world = pos_world - camera.position
	var viewport_rect_size = get_viewport().get_visible_rect().size
	return viewport_rect_size / 2.0 + Utils.world_to_global_size_px(offset_from_camera_world, camera.zoom)

func is_panning() -> bool:
	return _panning

func _do_pan_logic(event: InputEventMouseButton, camera_pos: Vector2) -> void:
	if event.pressed:
		# Start dragging
		_panning = true
		_drag_start = event.position
		_camera_original_position = camera_pos
	else:
		# Stop dragging
		_panning = false

func _input(event: InputEvent):
	var camera := get_viewport().get_camera_2d()
	if event is InputEventMouseButton:
		# Check if left mouse button is pressed
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				_do_pan_logic(event, camera.position)
			MOUSE_BUTTON_LEFT:
				if event.alt_pressed:
					_do_pan_logic(event, camera.position)
			MOUSE_BUTTON_WHEEL_UP:
				zoom_in(event.position)
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom_out(event.position)
	elif event is InputEventMouseMotion:
		if _panning:
			# Calculate drag distance and offset camera accordingly
			var drag_delta = (event.position - _drag_start) / camera.zoom.x
			camera.position = _camera_original_position - drag_delta

func zoom_in(mouse_pos: Vector2) -> void:
	_do_zoom(mouse_pos, ZOOM_SPEED)

func zoom_out(mouse_pos: Vector2) -> void:
	_do_zoom(mouse_pos, -ZOOM_SPEED)

# @param[in] mouse_pos - position to ceneter zoom operation around
# @param[in] zoom_speed - positive zooms in, negative zooms out
func _do_zoom(mouse_pos: Vector2, zoom_speed: float) -> void:
	var camera = get_viewport().get_camera_2d()
	var new_zoom := clamp(camera.zoom.x * (1 + zoom_speed), MIN_ZOOM, MAX_ZOOM) as float
	var mouse_pos_old = local_pos_to_world(mouse_pos)
	var old_zoom := camera.zoom.x as float
	camera.zoom = Vector2(1.0, 1.0) * new_zoom
	# Adjust camera position to keep the mouse position fixed
	var mouse_pos_new = local_pos_to_world(mouse_pos)
	var camera_offset = mouse_pos_old - mouse_pos_new
	camera.position += camera_offset
	zoom_changed.emit(old_zoom, camera.zoom.x)
