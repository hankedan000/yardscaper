extends Node2D
class_name Sprinkler

signal moved(sprink, from_xy, to_xy)

const ARC_POINTS = 32
const BODY_RADIUS_FT = 3.0 / 12.0

@export var min_dist_ft := 7.0 :
	set(value):
		min_dist_ft = value
		queue_redraw()

@export var max_dist_ft := 14.0 :
	set(value):
		max_dist_ft = value
		queue_redraw()

@export var dist_ft := max_dist_ft :
	set(value):
		dist_ft = value
		queue_redraw()

@export var sweep_deg : int = 360 :
	set(value):
		sweep_deg = int(round(value)) % 361
		if sweep_deg < 0:
			sweep_deg = 360 - sweep_deg
		queue_redraw()

@export var manufacturer : String = "" :
	set(value):
		manufacturer = value

@export var model : String = "" :
	set(value):
		model = value

@export var user_label : String = "" :
	set(value):
		user_label = value

var show_min_dist := true :
	set(value):
		show_min_dist = value
		queue_redraw()

var show_max_dist := true :
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
