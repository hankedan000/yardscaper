extends SubViewportContainer

const MAJOR_LINE_WIDTH := 1
const ORIGIN_VERT_COLOR := Color.LIME_GREEN
const ORIGIN_HORZ_COLOR := Color.INDIAN_RED

@onready var viewport      : Viewport = $Viewport
@onready var pan_zoom_ctrl := $Viewport/PanZoomController
@onready var camera2d      : Camera2D = $Viewport/Camera2D

var show_grid = true:
	set(value):
		show_grid = value
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

func _draw():
	if show_grid:
		_draw_grid(major_spacing_ft, major_line_color, MAJOR_LINE_WIDTH)
		_draw_origin()

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
			0.0,                 # step,
			visible_rect_size.x, # width
			1,                   # n_lines,
			ORIGIN_HORZ_COLOR,   # color
			MAJOR_LINE_WIDTH)    # line_width

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

func _process(delta):
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
