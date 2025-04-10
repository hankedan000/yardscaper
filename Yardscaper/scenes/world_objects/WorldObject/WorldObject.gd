extends Node2D
class_name WorldObject

signal property_changed(obj: WorldObject, property_key: StringName, from, to)
signal picked_state_changed()
signal moved(obj: WorldObject, from_xy: Vector2, to_xy: Vector2)

const PROP_KEY_POSITION_FT = &"position_ft"
const PROP_KEY_USER_LABEL = &"user_label"
const PROP_KEY_ROTATION_DEG = &"rotation_deg"
const PROP_KEY_INFO_LABEL_VISIBLE = &"info_label.visible"
const PROP_KEY_POSITION_LOCKED = &"position_locked"

@onready var info_label      : Label = $InfoLabel
@onready var lock_indicator  : Sprite2D = $LockIndicator
@onready var pick_area       : Area2D = $PickArea
@onready var pick_coll_shape : CollisionShape2D = $PickArea/CollisionShape2D

var world : WorldViewportContainer = null

var user_label : String = "" :
	set(value):
		var old_value = user_label
		user_label = value
		if old_value != user_label:
			property_changed.emit(self, PROP_KEY_USER_LABEL, old_value, user_label)

var position_locked : bool = false:
	set(value):
		var old_value = position_locked
		position_locked = value
		lock_indicator.visible = position_locked
		if old_value != position_locked:
			property_changed.emit(self, PROP_KEY_POSITION_LOCKED, old_value, position_locked)

var hovering : bool = false:
	set(value):
		hovering = value
		queue_redraw()

var picked : bool = false:
	set(value):
		var old_picked = picked
		picked = value
		if old_picked != picked:
			picked_state_changed.emit()
			queue_redraw()

var _is_ready = false
var _pos_at_move_start = null

func _ready():
	# locate our parent WorldViewportContainer
	var parent = get_parent()
	while parent != null:
		if parent is WorldViewportContainer:
			world = parent
			break
		parent = parent.get_parent()
	_is_ready = true

func get_subclass() -> String:
	return "WorldObject"

func get_order_in_world() -> int:
	if ! world:
		push_warning("object isn't in a world")
		return -1
	return world.get_object_order_idx(self)

func set_order_in_world(to_idx: int):
	var from_idx = get_order_in_world()
	if from_idx < 0:
		push_warning("unable to get object's from_idx")
		return
	world.reorder_world_object(from_idx, to_idx)

func get_info_label_visible() -> bool:
	return info_label.visible

func set_info_label_visible(new_visible: bool) -> void:
	var old_value = info_label.visible
	info_label.visible = new_visible
	if old_value != new_visible:
		property_changed.emit(self, PROP_KEY_INFO_LABEL_VISIBLE, old_value, new_visible)

func get_visual_center() -> Vector2:
	return global_position

func moving() -> bool:
	return _pos_at_move_start != null

func start_move():
	if moving():
		push_warning("move was already started. starting another one.")
	_pos_at_move_start = position

func update_move(delta):
	if ! moving():
		push_warning("can't update_move() when not moving")
		return
	position = _pos_at_move_start + delta

func finish_move(cancel=false):
	if not moving():
		push_warning("move was never started")
		return
	
	if cancel:
		position = _pos_at_move_start
	else:
		moved.emit(self, _pos_at_move_start, position)
	_pos_at_move_start = null

func serialize():
	return {
		'subclass' : get_subclass(),
		PROP_KEY_POSITION_FT : Utils.vect2_to_pair(Utils.px_to_ft_vec(position)),
		PROP_KEY_ROTATION_DEG : int(rotation_degrees),
		PROP_KEY_USER_LABEL : user_label,
		PROP_KEY_INFO_LABEL_VISIBLE : info_label.visible,
		PROP_KEY_POSITION_LOCKED : position_locked
	}

func deserialize(obj):
	if ! _is_ready:
		await ready
	position = Utils.ft_to_px_vec(Utils.pair_to_vect2(obj[PROP_KEY_POSITION_FT]))
	rotation_degrees = obj[PROP_KEY_ROTATION_DEG]
	user_label = obj[PROP_KEY_USER_LABEL]
	info_label.visible = Utils.dict_get(obj, PROP_KEY_INFO_LABEL_VISIBLE, false)
	position_locked = Utils.dict_get(obj, PROP_KEY_POSITION_LOCKED, false)

func on_zoom_changed(_new_zoom: Vector2, inv_new_zoom: Vector2) -> void:
	info_label.scale = inv_new_zoom
	lock_indicator.scale = inv_new_zoom
