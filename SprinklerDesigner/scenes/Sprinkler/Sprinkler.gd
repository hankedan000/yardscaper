extends Node2D
class_name Sprinkler

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

@export var sweep_deg : int = 270 :
	set(value):
		sweep_deg = int(round(value)) % 361
		if sweep_deg < 0:
			sweep_deg = 360 - sweep_deg
		queue_redraw()

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

func _draw():
	var stop_angle = rotation + deg_to_rad(sweep_deg)
	var water_color = Color.AQUA
	water_color.a = 0.7
	var max_radius = Utils.ft_to_px(max_dist_ft)
	var min_radius = Utils.ft_to_px(min_dist_ft)
	if show_water:
		draw_sector(global_position, max_radius, rotation, stop_angle, ARC_POINTS, water_color)
	if show_min_dist:
		draw_arc(global_position, min_radius, rotation, stop_angle, ARC_POINTS, Color.BLUE, 1.0)
	if show_max_dist:
		draw_arc(global_position, max_radius, rotation, stop_angle, ARC_POINTS, Color.RED, 1.0)
	if show_indicator:
		draw_circle(global_position, Utils.ft_to_px(BODY_RADIUS_FT * 2), Color.YELLOW)
	# draw body
	draw_circle(global_position, Utils.ft_to_px(BODY_RADIUS_FT), Color.BLACK)
