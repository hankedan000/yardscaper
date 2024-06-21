extends MoveableNode2D
class_name Sprinkler

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
		var old_value = min_dist_ft
		min_dist_ft = value
		if old_value != min_dist_ft:
			emit_signal('property_changed', 'min_dist_ft', old_value, min_dist_ft)
		queue_redraw()

var max_dist_ft : float = NAN :
	get:
		if is_set(max_dist_ft):
			return max_dist_ft
		if _head_info:
			return _head_info['max_dist_ft']
		return DEFAULT_MAX_DIST_FT
	set(value):
		var old_value = max_dist_ft
		max_dist_ft = value
		if old_value != max_dist_ft:
			emit_signal('property_changed', 'max_dist_ft', old_value, max_dist_ft)
		queue_redraw()

var dist_ft : float = NAN :
	get:
		if is_set(dist_ft):
			return dist_ft
		return max_dist_ft
	set(value):
		var old_value = dist_ft
		dist_ft = value
		if old_value != dist_ft:
			emit_signal('property_changed', 'dist_ft', old_value, dist_ft)
		queue_redraw()

var min_sweep_deg : float = NAN :
	get:
		if is_set(min_sweep_deg):
			return min_sweep_deg
		if _head_info:
			return _head_info['min_sweep_deg']
		return DEFAULT_MIN_SWEEP_DEG
	set(value):
		var old_value = min_sweep_deg
		min_sweep_deg = value
		if old_value != min_sweep_deg:
			emit_signal('property_changed', 'min_sweep_deg', old_value, min_sweep_deg)
		queue_redraw()

var max_sweep_deg : float = NAN :
	get:
		if is_set(max_sweep_deg):
			return max_sweep_deg
		if _head_info:
			return _head_info['max_sweep_deg']
		return DEFAULT_MAX_SWEEP_DEG
	set(value):
		var old_value = max_sweep_deg
		max_sweep_deg = value
		if old_value != max_sweep_deg:
			emit_signal('property_changed', 'max_sweep_deg', old_value, max_sweep_deg)
		queue_redraw()

var sweep_deg : float = NAN :
	get:
		if is_set(sweep_deg):
			return sweep_deg
		return max_sweep_deg
	set(value):
		var old_value = sweep_deg
		sweep_deg = int(round(value)) % 361
		if sweep_deg < 0:
			sweep_deg = 360 - sweep_deg
		if old_value != sweep_deg:
			emit_signal('property_changed', 'sweep_deg', old_value, sweep_deg)
		queue_redraw()

var manufacturer : String = "" :
	set(value):
		manufacturer = value
		_head_info = TheSprinklerDb.get_head_info(manufacturer, model)

var model : String = "" :
	set(value):
		var old_value = model
		model = value
		if old_value != model:
			emit_signal('property_changed', 'model', old_value, model)
		_head_info = TheSprinklerDb.get_head_info(manufacturer, model)

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

var _head_info = null

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

func get_subclass() -> String:
	return "Sprinkler"

func serialize():
	var obj = super.serialize()
	obj['dist_ft'] = dist_ft
	obj['sweep_deg'] = int(sweep_deg)
	obj['manufacturer'] = manufacturer
	obj['model'] = model
	return obj

func deserialize(obj):
	super.deserialize(obj)
	sweep_deg = obj['sweep_deg']
	manufacturer = obj['manufacturer']
	model = obj['model']
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
