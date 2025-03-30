extends Control
class_name WorldViewportContainer

signal world_object_reordered(from_idx: int, to_idx: int)
signal pan_state_changed(panning: bool)

const MAJOR_LINE_WIDTH := 1
const ORIGIN_VERT_COLOR := Color.LIME_GREEN
const ORIGIN_HORZ_COLOR := Color.INDIAN_RED

@onready var viewport         : Viewport = $ViewportContainer/Viewport
@onready var objects          := $ViewportContainer/Viewport/Objects
@onready var pan_zoom_ctrl    := $ViewportContainer/Viewport/PanZoomController
@onready var camera2d         : Camera2D = $ViewportContainer/Viewport/Camera2D
@onready var cursor           := $ViewportContainer/Viewport/Cursor
@onready var cursor_pos_label : Label = $CursorPositionLabel

var show_grid = true:
	set(value):
		show_grid = value
		queue_redraw()

var show_cursor_position_label = true:
	set(value):
		show_cursor_position_label = value
		cursor_pos_label.visible = value

var show_cursor_crosshairs = false:
	set(value):
		show_cursor_crosshairs = value
		queue_redraw()

var major_spacing_ft : float = 5:
	set(value):
		major_spacing_ft = float(value)
		queue_redraw()

var major_line_color : Color = Color.LIGHT_SLATE_GRAY:
	set(value):
		major_line_color = value
		queue_redraw()

var _prev_zoom := Vector2()
var _prev_global_pos := Vector2()

# move a world object from one position to another
# @return true if move was applied, false otherwise
func reorder_world_object(from_idx: int, to_idx: int) -> bool:
	var object_count = objects.get_child_count()
	if from_idx < 0 or from_idx >= object_count:
		push_error("from_idx (%d) out of range. object_count = %d" % [from_idx, object_count])
		return false
	elif to_idx < 0 or to_idx >= object_count:
		push_error("to_idx (%d) out of range. object_count = %d" % [to_idx, object_count])
		return false
	elif from_idx == to_idx:
		push_warning("move request does nothing")
		return false
	var obj = objects.get_child(from_idx)
	objects.move_child(obj, to_idx)
	world_object_reordered.emit(from_idx, to_idx)
	return true

# move a world object to another draw order index
# @return -1 if obj doesn't exist, else the object's order index
func get_object_order_idx(obj: WorldObject) -> int:
	var children = objects.get_children()
	return children.find(obj, 0)

func get_image_of_current_view() -> Image:
	return viewport.get_texture().get_image()

func global_xy_to_pos_in_world(global_pos: Vector2) -> Vector2:
	var pos_rel_to_world := global_pos - self.global_position
	return pan_zoom_ctrl.local_pos_to_world(pos_rel_to_world)

func _draw():
	if show_grid:
		_draw_grid(major_spacing_ft, major_line_color, MAJOR_LINE_WIDTH)
		_draw_origin()
	if show_cursor_crosshairs:
		_draw_cursor_crosshairs()

func _draw_origin():
	var origin_pos_local = pan_zoom_ctrl.world_pos_to_local(Vector2(0, 0))
	var visible_rect_size := viewport.get_visible_rect().size
	if origin_pos_local.x >= 0 and origin_pos_local.x < visible_rect_size.x:
		_draw_vert_lines(
			origin_pos_local.x,  # start_x
			0.0,                 # step,
			visible_rect_size.y, # height
			1,                   # n_lines,
			ORIGIN_VERT_COLOR,   # color
			MAJOR_LINE_WIDTH)    # line_width
	if origin_pos_local.y >= 0 and origin_pos_local.y < visible_rect_size.y:
		_draw_horz_lines(
			origin_pos_local.y,  # start_y
			0.0,                 # step
			visible_rect_size.x, # width
			1,                   # n_lines
			ORIGIN_HORZ_COLOR,   # color
			MAJOR_LINE_WIDTH)    # line_width

func _draw_cursor_crosshairs() -> void:
	var cursor_pos_local := pan_zoom_ctrl.world_pos_to_local(cursor.position) as Vector2
	var visible_rect_size := viewport.get_visible_rect().size
	_draw_horz_lines(
		cursor_pos_local.y, # start_y
		0.0,                # step
		visible_rect_size.x,# width
		1,                  # n_lines
		Color.WHITE,        # color
		1)                  # line_width
	_draw_vert_lines(
		cursor_pos_local.x, # start_x
		0.0,                # step
		visible_rect_size.y,# width
		1,                  # n_lines
		Color.WHITE,        # color
		1)                  # line_width

func _draw_grid(grid_spacing_ft: float, color: Color, line_width: int):
	var visible_rect_size := viewport.get_visible_rect().size
	var visible_world_size := Utils.global_to_world_size_px(
		visible_rect_size, camera2d.zoom)
	
	var spacing_world = Utils.ft_to_px(grid_spacing_ft)
	var vert_spacing_global = Utils.world_to_global_px(
		spacing_world, camera2d.zoom.x)
	var horz_spacing_global = Utils.world_to_global_px(
		spacing_world, camera2d.zoom.y)
	var n_vert_lines = ceil(visible_world_size.x / spacing_world)
	var n_horz_lines = ceil(visible_world_size.y / spacing_world)
	
	var upper_left_pos_world = pan_zoom_ctrl.local_pos_to_world(Vector2(0, 0))
	var first_major_grid_pos_world = Vector2(
		ceil(upper_left_pos_world.x / spacing_world) * spacing_world,
		ceil(upper_left_pos_world.y / spacing_world) * spacing_world)
	var first_major_grid_pos_local = Vector2(
		(first_major_grid_pos_world.x - upper_left_pos_world.x) * camera2d.zoom.x,
		(first_major_grid_pos_world.y - upper_left_pos_world.y) * camera2d.zoom.y)
	_draw_vert_lines(
		first_major_grid_pos_local.x,
		vert_spacing_global, # step (px)
		visible_rect_size.y, # height (px)
		n_vert_lines, # n_lines
		color,
		line_width);
	_draw_horz_lines(
		first_major_grid_pos_local.y,
		horz_spacing_global, # step (px)
		visible_rect_size.x, # width (px)
		n_horz_lines, # n_lines
		color,
		line_width);

func _draw_vert_lines(start_x: float, step: float, height: float, n_lines: int, color: Color, line_width: int):
	for i in range(n_lines):
		var x_pos = start_x + step * i
		draw_line(
			Vector2(x_pos, 0),
			Vector2(x_pos, height),
			color,
			line_width)

func _draw_horz_lines(start_y: float, step: float, width: float, n_lines: int, color: Color, line_width: int):
	for i in range(n_lines):
		var y_pos = start_y + step * i
		draw_line(
			Vector2(0, y_pos),
			Vector2(width, y_pos),
			color,
			line_width)

func _process(_delta):
	var curr_pos := camera2d.global_position
	var curr_zoom := camera2d.zoom
	var delta_pos := curr_pos - _prev_global_pos
	var delta_zoom := curr_zoom - _prev_zoom
	if delta_pos.length() > 0.5:
		queue_redraw()
	if delta_zoom.length() > 0.00001:
		queue_redraw()
	_prev_global_pos = curr_pos
	_prev_zoom = curr_zoom
	
	var mouse_pos = get_local_mouse_position()
	var pos_in_world = pan_zoom_ctrl.local_pos_to_world(mouse_pos)
	cursor.position = pos_in_world

func _on_pan_zoom_controller_pan_state_changed(panning: bool) -> void:
	pan_state_changed.emit(panning)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var pos_in_world_px = global_xy_to_pos_in_world(event.global_position)
		var pos_in_world_ft = Utils.px_to_ft_vec(pos_in_world_px)
		var x_pretty = Utils.pretty_dist(pos_in_world_ft.x)
		var y_pretty = Utils.pretty_dist(pos_in_world_ft.y)
		cursor_pos_label.text = "%s, %s" % [x_pretty, y_pretty]
		
		if show_cursor_crosshairs:
			queue_redraw()
