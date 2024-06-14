extends Node2D
class_name Sprinkler

signal moved(sprink, from_xy, to_xy)

const ARC_POINTS = 32
const BODY_RADIUS_FT = 3.0 / 12.0
const DEFAULT_MIN_DIST_FT = 8.0
const DEFAULT_MAX_DIST_FT = 14.0
const DEFAULT_MIN_SWEEP_DEG = 0.0
const DEFAULT_MAX_SWEEP_DEG = 360.0

func is_set(value: float):
	return not is_nan(value)

var min_dist_ft : float = NAN :
	get:
		if is_set(min_dist_ft):
			return min_dist_ft
		if _head_info:
			return _head_info['min_dist_ft']
		return DEFAULT_MIN_DIST_FT
	set(value):
		min_dist_ft = value
		queue_redraw()

var max_dist_ft : float = NAN :
	get:
		if is_set(max_dist_ft):
			return max_dist_ft
		if _head_info:
			return _head_info['max_dist_ft']
		return DEFAULT_MAX_DIST_FT
	set(value):
		max_dist_ft = value
		queue_redraw()

var dist_ft : float = NAN :
	get:
		if is_set(dist_ft):
			return dist_ft
		return max_dist_ft
	set(value):
		dist_ft = value
		queue_redraw()

var min_sweep_deg : float = NAN :
	get:
		if is_set(min_sweep_deg):
			return min_sweep_deg
		if _head_info:
			return _head_info['min_sweep_deg']
		return DEFAULT_MIN_SWEEP_DEG
	set(value):
		min_sweep_deg = value
		queue_redraw()

var max_sweep_deg : float = NAN :
	get:
		if is_set(max_sweep_deg):
			return max_sweep_deg
		if _head_info:
			return _head_info['max_sweep_deg']
		return DEFAULT_MAX_SWEEP_DEG
	set(value):
		max_sweep_deg = value
		queue_redraw()

var sweep_deg : float = NAN :
	get:
		if is_set(sweep_deg):
			return sweep_deg
		return max_sweep_deg
	set(value):
		sweep_deg = int(round(value)) % 361
		if sweep_deg < 0:
			sweep_deg = 360 - sweep_deg
		queue_redraw()

var manufacturer : String = "" :
	set(value):
		manufacturer = value
		_head_info = TheSprinklerDb.get_head_info(manufacturer, model)

var model : String = "" :
	set(value):
		model = value
		_head_info = TheSprinklerDb.get_head_info(manufacturer, model)

var user_label : String = "" :
	set(value):
		user_label = value

var show_min_dist := false :
	set(value):
		show_min_dist = value
		queue_redraw()

var show_max_dist := false :
	set(value):
		show_max_dist = value
		queue_redraw()

var show_water := true :
	set(value):
		show_water = value
		queue_redraw()

var show_indicator := false :
	set(value):
		show_indicator = value
		queue_redraw()

var _pos_at_move_start_xy = null
var _head_info = null

func moving() -> bool:
	return _pos_at_move_start_xy != null

func start_move():
	if moving():
		push_warning("sprinkler move was already started. starting another one.")
	_pos_at_move_start_xy = position

func finish_move():
	if not moving():
		push_warning("sprinkler move was never started")
		return
	
	emit_signal("moved", self, _pos_at_move_start_xy, position)
	_pos_at_move_start_xy = null

func cancel_move():
	if not moving:
		push_warning("sprinkler move was never started")
		return
	
	position = _pos_at_move_start_xy
	_pos_at_move_start_xy = null

func draw_sector(center: Vector2, radius: float, angle_from: float, angle_to: float, n_points: int, color: Color):
	if n_points <= 2:
		printerr("n_points must be > 2. n_points = %d" % [n_points])
		return

	var angle_step = (angle_to - angle_from) / (n_points - 1)
	var points = PackedVector2Array()
	points.push_back(center)
	for i in range(n_points):
		var angle_point = angle_from + i * angle_step
		points.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)

	draw_polygon(points, [color])

func serialize():
	var position_ft = Utils.px_to_ft_vec(position)
	return {
		'position_ft' : [position_ft.x, position_ft.y],
		'rotation_deg' : int(rotation_degrees),
		'dist_ft' : dist_ft,
		'sweep_deg' : int(sweep_deg),
		'manufacturer' : manufacturer,
		'model' : model,
		'user_label' : user_label
	}

func deserialize(obj):
	var pos_ft = obj['position_ft']
	position = Vector2(Utils.ft_to_px(pos_ft[0]), Utils.ft_to_px(pos_ft[1]))
	rotation_degrees = obj['rotation_deg']
	sweep_deg = obj['sweep_deg']
	manufacturer = obj['manufacturer']
	model = obj['model']
	user_label = obj['user_label']
	dist_ft = Utils.dict_get(obj, 'dist_ft', max_dist_ft)

func _draw():
	var stop_angle = deg_to_rad(sweep_deg)
	var water_color = Color.AQUA
	water_color.a = 0.7
	var max_radius = Utils.ft_to_px(max_dist_ft)
	var min_radius = Utils.ft_to_px(min_dist_ft)
	var dist_radius = Utils.ft_to_px(dist_ft)
	var center = Vector2()
	if show_water:
		draw_sector(center, dist_radius, 0, stop_angle, ARC_POINTS, water_color)
	if show_min_dist:
		draw_arc(center, min_radius, 0, stop_angle, ARC_POINTS, Color.BLUE, 1.0)
	if show_max_dist:
		draw_arc(center, max_radius, 0, stop_angle, ARC_POINTS, Color.RED, 1.0)
	if show_indicator:
		draw_circle(center, Utils.ft_to_px(BODY_RADIUS_FT * 2), Color.YELLOW)
	# draw body
	draw_circle(center, Utils.ft_to_px(BODY_RADIUS_FT), Color.BLACK)
