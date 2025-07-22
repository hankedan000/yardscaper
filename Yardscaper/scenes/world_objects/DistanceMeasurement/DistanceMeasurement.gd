extends WorldObject
class_name DistanceMeasurement

const PROP_KEY_POINT_A := &'point_a'
const PROP_KEY_POINT_B := &'point_b'

var color := Color.BLACK

# point is relative to the distance measurement's root node
var point_a := Vector2():
	set(value):
		_set_point_position(point_a_handle, value)
	get():
		return point_a_handle.position

# point is relative to the distance measurement's root node
var point_b := Vector2():
	set(value):
		_set_point_position(point_b_handle, value)
	get():
		return point_b_handle.position

@onready var point_a_handle : EditorHandle = $PointA_Handle
@onready var point_b_handle : EditorHandle = $PointB_Handle

var _point_a_from_save := Vector2()
var _point_b_from_save := Vector2()
var _coll_rect := RectangleShape2D.new()
var _handle_being_moved : EditorHandle = null
var _handle_init_pos : Vector2 = Vector2() # init position when starting move
var _mouse_init_pos : Vector2 = Vector2() # init position when starting move

func _ready():
	super._ready()
	point_a = _point_a_from_save
	point_b = _point_b_from_save
	
	# change pick shape to a rectangle (default is ellipse)
	pick_coll_shape.shape = _coll_rect
	
	_setup_dist_handle(point_a_handle, 1)
	_setup_dist_handle(point_b_handle, 2)
	set_process(false)

func _draw():
	if dist_px() < 1.0:
		return # nothing to draw
	
	# update position/shape of the collision rectangle
	# probably not the best place to do this, but convenient and efficient
	var midpoint := mid_point()
	var delta_vec := point_b - point_a
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

func get_type_name() -> StringName:
	return TypeNames.DIST_MEASUREMENT

func get_visual_center() -> Vector2:
	return global_position + mid_point()

func get_bounding_box() -> Rect2:
	var box := Rect2(point_a, Vector2(1,1))
	return box.expand(point_b)

func serialize() -> Dictionary:
	var obj = super.serialize()
	obj[&'point_a_ft'] = Utils.vect2_to_pair(Utils.px_to_ft_vec(point_a))
	obj[&'point_b_ft'] = Utils.vect2_to_pair(Utils.px_to_ft_vec(point_b))
	return obj

func deserialize(obj: Dictionary) -> void:
	super.deserialize(obj)
	_point_a_from_save = Utils.ft_to_px_vec(
		Utils.pair_to_vect2(DictUtils.get_w_default(obj, &'point_a_ft', [0.0, 0.0])))
	_point_b_from_save = Utils.ft_to_px_vec(
		Utils.pair_to_vect2(DictUtils.get_w_default(obj, &'point_b_ft', [0.0, 0.0])))

func start_handle_move(handle: EditorHandle) -> void:
	if ! (handle == point_a_handle || handle == point_b_handle):
		push_warning("handle must be owned by this node")
		return
	
	_handle_being_moved = handle
	var prop_key := _handle_to_prop_key(handle)
	deferred_prop_change.push(prop_key)

func stop_handle_move() -> void:
	if ! is_instance_valid(_handle_being_moved):
		return
	
	var prop_key := _handle_to_prop_key(_handle_being_moved)
	deferred_prop_change.pop(prop_key)
	_handle_being_moved = null

func _bias_text_rotation_upright(angle_rad: float) -> float:
	var angle_deg := rad_to_deg(angle_rad)
	if angle_deg >= 90.0 || angle_deg < -90.0:
		return angle_rad + PI
	return angle_rad
	

func _setup_dist_handle(handle: EditorHandle, user_id: int) -> void:
	handle.user_id = user_id
	handle.get_button().button_down.connect(_on_handle_button_down.bind(handle))
	handle.get_button().button_up.connect(_on_handle_button_up)

func _set_point_position(handle: EditorHandle, new_position: Vector2, force_change:= false):
	var old_value := handle.position
	handle.try_position_change(global_position + new_position)
	var prop_key : StringName = PROP_KEY_POINT_A if handle == point_a_handle else PROP_KEY_POINT_B
	if _check_and_emit_prop_change(prop_key, old_value, force_change):
		_update_info_label()
		queue_redraw()

func _update_info_label() -> void:
	_update_info_label_text()
	_update_info_label_position()

func _update_info_label_text() -> void:
	var pretty_dist = Utils.pretty_dist(dist_ft())
	info_label.text = "L=%s" % pretty_dist

# update the rotation and position of the label so the text runs along the
# length of the line and always resides above (upwards)
func _update_info_label_position() -> void:
	var midpoint := mid_point()
	var delta_vec := point_b - point_a
	var baseline_angle := _bias_text_rotation_upright(delta_vec.angle())
	info_label.hide_if_wider_than = delta_vec.length()
	info_label.position = midpoint
	info_label.rotation = baseline_angle

func _update_handles() -> void:
	lock_indicator.position = point_a
	point_a_handle.visible = picked && ! position_locked
	point_b_handle.visible = picked && ! position_locked

func _handle_to_prop_key(handle: EditorHandle) -> StringName:
	if handle.user_id == 1:
		return PROP_KEY_POINT_A
	return PROP_KEY_POINT_B

func _on_handle_button_down(handle: EditorHandle) -> void:
	_handle_init_pos = handle.position
	_mouse_init_pos = get_global_mouse_position()
	start_handle_move(handle)
	set_process(true)

func _on_handle_button_up() -> void:
	stop_handle_move()
	set_process(false)

func _on_property_changed(_obj: WorldObject, property_key: StringName, _from: Variant, _to: Variant) -> void:
	if property_key == PROP_KEY_POSITION_LOCKED:
		_update_handles()
