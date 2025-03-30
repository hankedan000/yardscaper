extends MoveableNode2D
class_name Sprinkler

const ARC_POINTS = 32
const BODY_RADIUS_FT = 3.0 / 12.0
const DEFAULT_MIN_DIST_FT = 8.0
const DEFAULT_MAX_DIST_FT = 14.0
const DEFAULT_MIN_SWEEP_DEG = 0.0
const DEFAULT_MAX_SWEEP_DEG = 360.0

const PROP_KEY_ZONE = &"zone"
const PROP_MIN_SWEEP_DEG = &"min_sweep_deg"
const PROP_MAX_SWEEP_DEG = &"max_sweep_deg"

func is_set(value: float):
	return not is_nan(value)

var zone : int = 1 :
	set(value):
		var old_value = zone
		zone = value
		if old_value != zone:
			property_changed.emit(self, PROP_KEY_ZONE, old_value, zone)

var min_dist_ft : float = NAN :
	get:
		if is_set(min_dist_ft):
			return min_dist_ft
		if _head_info:
			return _head_info[PROP_KEY_MIN_DIST_FT]
		return DEFAULT_MIN_DIST_FT
	set(value):
		var old_value = min_dist_ft
		min_dist_ft = value
		if old_value != min_dist_ft:
			_cap_values()
			queue_redraw()
			property_changed.emit(self, PROP_KEY_MIN_DIST_FT, old_value, min_dist_ft)

var max_dist_ft : float = NAN :
	get:
		if is_set(max_dist_ft):
			return max_dist_ft
		if _head_info:
			return _head_info[PROP_KEY_MAX_DIST_FT]
		return DEFAULT_MAX_DIST_FT
	set(value):
		var old_value = max_dist_ft
		max_dist_ft = value
		if old_value != max_dist_ft:
			_cap_values()
			queue_redraw()
			property_changed.emit(self, PROP_KEY_MAX_DIST_FT, old_value, max_dist_ft)

var dist_ft : float = NAN :
	get:
		if is_set(dist_ft):
			return dist_ft
		return max_dist_ft
	set(value):
		var old_value = dist_ft
		dist_ft = value
		if old_value != dist_ft:
			_cap_values()
			queue_redraw()
			property_changed.emit(self, PROP_KEY_DIST_FT, old_value, dist_ft)

var min_sweep_deg : float = NAN :
	get:
		if is_set(min_sweep_deg):
			return min_sweep_deg
		if _head_info:
			return _head_info[PROP_MIN_SWEEP_DEG]
		return DEFAULT_MIN_SWEEP_DEG
	set(value):
		var old_value = min_sweep_deg
		min_sweep_deg = value
		if old_value != min_sweep_deg:
			_cap_values()
			queue_redraw()
			property_changed.emit(self, PROP_MIN_SWEEP_DEG, old_value, min_sweep_deg)

var max_sweep_deg : float = NAN :
	get:
		if is_set(max_sweep_deg):
			return max_sweep_deg
		if _head_info:
			return _head_info[PROP_MAX_SWEEP_DEG]
		return DEFAULT_MAX_SWEEP_DEG
	set(value):
		var old_value = max_sweep_deg
		max_sweep_deg = value
		if old_value != max_sweep_deg:
			_cap_values()
			queue_redraw()
			property_changed.emit(self, PROP_MAX_SWEEP_DEG, old_value, max_sweep_deg)

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
			_cap_values()
			queue_redraw()
			property_changed.emit(self, PROP_KEY_SWEEP_DEG, old_value, sweep_deg)

var manufacturer : String = "" :
	set(value):
		var old_value = manufacturer
		manufacturer = value
		_head_info = TheSprinklerDb.get_head_info(manufacturer, model)
		if old_value != manufacturer:
			_cap_values()
			queue_redraw()
			property_changed.emit(self, PROP_KEY_MANUFACTURER, old_value, manufacturer)

var model : String = "" :
	set(value):
		var old_value = model
		model = value
		_head_info = TheSprinklerDb.get_head_info(manufacturer, model)
		if old_value != model:
			_cap_values()
			queue_redraw()
			property_changed.emit(self, PROP_KEY_MODEL, old_value, model)

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

const PROP_KEY_DIST_FT = &"dist_ft"
const PROP_KEY_MIN_DIST_FT = &"min_dist_ft"
const PROP_KEY_MAX_DIST_FT = &"max_dist_ft"
const PROP_KEY_SWEEP_DEG = &"sweep_deg"
const PROP_KEY_MANUFACTURER = &"manufacturer"
const PROP_KEY_MODEL = &"model"

func serialize():
	var obj = super.serialize()
	obj[PROP_KEY_DIST_FT] = dist_ft
	obj[PROP_KEY_MIN_DIST_FT] = min_dist_ft
	obj[PROP_KEY_MAX_DIST_FT] = max_dist_ft
	obj[PROP_KEY_SWEEP_DEG] = int(sweep_deg)
	obj[PROP_KEY_MANUFACTURER] = manufacturer
	obj[PROP_KEY_MODEL] = model
	obj[PROP_KEY_ZONE] = zone
	return obj

func deserialize(obj):
	super.deserialize(obj)
	sweep_deg = obj[PROP_KEY_SWEEP_DEG]
	manufacturer = obj[PROP_KEY_MANUFACTURER]
	model = obj[PROP_KEY_MODEL]
	dist_ft = Utils.dict_get(obj, PROP_KEY_DIST_FT, max_dist_ft)
	min_dist_ft = Utils.dict_get(obj, PROP_KEY_MIN_DIST_FT, min_dist_ft)
	max_dist_ft = Utils.dict_get(obj, PROP_KEY_MAX_DIST_FT, max_dist_ft)
	zone = Utils.dict_get(obj, PROP_KEY_ZONE, 1)

func _draw():
	var stop_angle = deg_to_rad(sweep_deg)
	var water_color = Color.DODGER_BLUE
	water_color.a = 0.5
	var max_radius = Utils.ft_to_px(max_dist_ft)
	var min_radius = Utils.ft_to_px(min_dist_ft)
	var dist_radius = Utils.ft_to_px(dist_ft)
	var center = Vector2()
	if show_water:
		draw_sector(center, dist_radius, 0, stop_angle, ARC_POINTS, water_color)
	if show_min_dist:
		draw_arc(center, min_radius, 0, stop_angle, ARC_POINTS, Color.RED, 1.0)
	if show_max_dist:
		draw_arc(center, max_radius, 0, stop_angle, ARC_POINTS, Color.LIME_GREEN, 1.0)
	# draw indicator circle
	if picked or hovering:
		var indic_color = Globals.SELECT_COLOR if picked else Globals.HOVER_COLOR
		draw_circle(center, Utils.ft_to_px(BODY_RADIUS_FT * 2), indic_color)
	# draw body
	draw_circle(center, Utils.ft_to_px(BODY_RADIUS_FT), Color.BLACK)

func _cap_values():
	if dist_ft < min_dist_ft:
		dist_ft = min_dist_ft
	elif dist_ft > max_dist_ft:
		dist_ft = max_dist_ft
	
	if sweep_deg < min_sweep_deg:
		sweep_deg = min_sweep_deg
	elif sweep_deg > max_sweep_deg:
		sweep_deg = max_sweep_deg
