extends WorldObject
class_name DistanceMeasurement

const PROP_KEY_POINT_A := &'point_a'
const PROP_KEY_POINT_B := &'point_b'

var color := Color.BLACK

var point_a := Vector2():
	set(value):
		var old_value := point_a
		point_a = value
		if _check_and_emit_prop_change(PROP_KEY_POINT_A, old_value):
			queue_redraw()

var point_b := Vector2():
	set(value):
		var old_value := point_b
		point_b = value
		if _check_and_emit_prop_change(PROP_KEY_POINT_B, old_value):
			queue_redraw()

@onready var point_a_handle : EditorHandle = $PointA_Handle
@onready var point_b_handle : EditorHandle = $PointB_Handle

var _coll_rect := RectangleShape2D.new()
var _handle_being_moved : EditorHandle = null
var _handle_init_pos : Vector2 = Vector2() # init position when starting move
var _mouse_init_pos : Vector2 = Vector2() # init position when starting move

func _ready():
	super._ready()
	# change pick shape to a rectangle (default is ellipse)
	pick_coll_shape.shape = _coll_rect
	
	# setup editor handles
	point_a_handle.user_id = 1
	point_b_handle.user_id = 2
	point_a_handle.get_button().button_down.connect(_on_handle_button_down.bind(point_a_handle))
	point_b_handle.get_button().button_down.connect(_on_handle_button_down.bind(point_b_handle))
	point_a_handle.get_button().button_up.connect(_on_handle_button_up)
	point_b_handle.get_button().button_up.connect(_on_handle_button_up)
	
	set_process(false)

func _draw():
	if dist_px() < 1.0:
		return # nothing to draw
	
	# update position/shape of the collision rectangle
	# probably not the best place to do this, but convenient and efficient
	var midpoint = mid_point()
	var delta_vec = point_b - point_a
	_coll_rect.size.x = delta_vec.length()
	_coll_rect.size.y = 10
	pick_area.rotation = delta_vec.angle()
	pick_area.position = midpoint
	
	# draw indicator outline
	if picked or hovering:
		var indic_color = Globals.SELECT_COLOR if picked else Globals.HOVER_COLOR
		draw_line(point_a, point_b, indic_color, 5)
	_update_handles()
	
	# draw measurement line
	draw_line(point_a, point_b, color, 1)
	
	# draw distance label at midpoint of line
	var font : Font = ThemeDB.fallback_font
	var pretty_dist = Utils.pretty_dist(dist_ft())
	draw_string(
		font,
		midpoint,
		pretty_dist,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1, # width
		16, # font_size
		color)

func _process(_delta: float) -> void:
	if _handle_being_moved:
		# even though the getter says 'global', it seems to return a position
		# within the world. regardless, it works for what we need in here.
		var world_mouse_pos := get_global_mouse_position()
		var mouse_delta_pos := world_mouse_pos - _mouse_init_pos
		if _handle_being_moved.user_id == 1:
			point_a = _handle_init_pos + mouse_delta_pos
		else:
			point_b = _handle_init_pos + mouse_delta_pos

func mid_point() -> Vector2:
	return point_a + ((point_b - point_a) / 2.0)

func dist_px() -> float:
	return point_a.distance_to(point_b)

func dist_ft() -> float:
	return Utils.px_to_ft(dist_px())

func get_subclass() -> String:
	return "DistanceMeasurement"

func serialize():
	var obj = super.serialize()
	obj['point_a_ft'] = Utils.vect2_to_pair(Utils.px_to_ft_vec(point_a))
	obj['point_b_ft'] = Utils.vect2_to_pair(Utils.px_to_ft_vec(point_b))
	return obj

func deserialize(obj):
	super.deserialize(obj)
	point_a = Utils.ft_to_px_vec(Utils.pair_to_vect2(obj['point_a_ft']))
	point_b = Utils.ft_to_px_vec(Utils.pair_to_vect2(obj['point_b_ft']))

func _update_handles() -> void:
	lock_indicator.position = point_a
	point_a_handle.position = point_a
	point_b_handle.position = point_b
	point_a_handle.visible = picked && ! position_locked
	point_b_handle.visible = picked && ! position_locked

func _handle_to_prop_key(handle: EditorHandle) -> StringName:
	if handle.user_id == 1:
		return PROP_KEY_POINT_A
	return PROP_KEY_POINT_B

func _on_handle_button_down(handle: EditorHandle) -> void:
	_handle_being_moved = handle
	_handle_init_pos = handle.position
	_mouse_init_pos = get_global_mouse_position()
	var prop_key := _handle_to_prop_key(_handle_being_moved)
	deferred_prop_change.push(prop_key)
	set_process(true)

func _on_handle_button_up() -> void:
	var prop_key := _handle_to_prop_key(_handle_being_moved)
	deferred_prop_change.pop(prop_key)
	_handle_being_moved = null
	set_process(false)

func _on_property_changed(_obj: WorldObject, property_key: StringName, _from: Variant, _to: Variant) -> void:
	if property_key == PROP_KEY_POSITION_LOCKED:
		_update_handles()
