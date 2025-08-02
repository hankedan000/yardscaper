class_name WorldObject extends Node2D

enum EditorHandleState {
	ButtonDown, ButtonUp, MoveStart, MoveStop
}

## Emitted when a property on the object has changed.
signal property_changed(obj: WorldObject, prop_key: StringName, from, to)
## Emitted when a property on the object's [FEntity] has changed that would
## impact the result of the [FSystem] simulation.
signal fluid_property_changed(obj: WorldObject, prop_key: StringName, from, to)
signal picked_state_changed(obj: WorldObject, new_picked: bool)
signal moved(obj: WorldObject, from_xy: Vector2, to_xy: Vector2)
@warning_ignore("unused_signal")
signal editor_handle_state_change(obj: WorldObject, handle: EditorHandle, new_state: EditorHandleState)
@warning_ignore("unused_signal") # subclasses will emit this
signal undoable_edit(undo_op: UndoController.UndoOperation)

const PROP_KEY_SUBCLASS = &"subclass"
const PROP_KEY_POSITION_FT = &"position_ft"
const PROP_KEY_USER_LABEL = &"user_label"
const PROP_KEY_ROTATION_DEG = &"rotation_deg"
const PROP_KEY_INFO_LABEL_VISIBLE = &"info_label.visible"
const PROP_KEY_POSITION_LOCKED = &"position_locked"

@onready var info_label      : GizmoLabel = $InfoLabel
@onready var lock_indicator  : LockIndicator = $LockIndicator
@onready var pick_area       : Area2D = $PickArea
@onready var pick_coll_shape : CollisionShape2D = $PickArea/CollisionShape2D

var world : WorldViewportContainer = null
var parent_project : Project = null

var user_label : String = "" :
	set(value):
		var old_value = name
		name = value
		_check_and_emit_prop_change(PROP_KEY_USER_LABEL, old_value)
	get():
		return name

var position_locked : bool = false:
	set(value):
		var old_value = position_locked
		position_locked = value
		lock_indicator.visible = position_locked
		_check_and_emit_prop_change(PROP_KEY_POSITION_LOCKED, old_value)

var hovering : bool = false:
	set(value):
		hovering = value
		queue_redraw()

var picked : bool = false:
	set(value):
		var old_picked = picked
		picked = value
		if old_picked != picked:
			picked_state_changed.emit(self, picked)
			queue_redraw()

# this property basically mirrors the built-in `rotation_degrees` property.
# we needed this user-defined version so we can generate signals correctly
# as well as handle undo/redo operations correctly.
var rotation_deg : float = 0.0:
	set(value):
		var old_value = rotation_degrees
		rotation_degrees = value
		if _check_and_emit_prop_change(PROP_KEY_ROTATION_DEG, old_value):
			queue_redraw()
	get():
		return rotation_degrees

var short_term_position_locked : bool = false

var deferred_prop_change : DeferredPropertyChange = DeferredPropertyChange.new(self)

class WObjPropsFromSave extends RefCounted:
	var global_position = null
	var info_label_visible = null
	var positon_locked = null

var _wobj_props_from_save : WObjPropsFromSave = WObjPropsFromSave.new()
var _global_pos_at_move_start = null

func _ready():
	# locate our parent WorldViewportContainer
	var parent = get_parent()
	while parent != null:
		if parent is WorldViewportContainer:
			world = parent
			break
		parent = parent.get_parent()
	
	# restore items from deserialize() that needed to wait for _ready()
	if _wobj_props_from_save.global_position is Vector2:
		apply_global_position(_wobj_props_from_save.global_position)
		_wobj_props_from_save.global_position = null
	if _wobj_props_from_save.info_label_visible is bool:
		info_label.visible = _wobj_props_from_save.info_label_visible
		_wobj_props_from_save.info_label_visible = null
	if _wobj_props_from_save.positon_locked is bool:
		position_locked = _wobj_props_from_save.positon_locked
		_wobj_props_from_save.positon_locked = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_predelete()

func get_type_name() -> StringName:
	return TypeNames.WORLD_OBJ

func get_order_in_world() -> int:
	if ! is_instance_valid(world):
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
	_check_and_emit_prop_change(PROP_KEY_INFO_LABEL_VISIBLE, old_value)

func get_visual_center() -> Vector2:
	return global_position

# @returns a bounding box around the object in global pixel space
func get_bounding_box() -> Rect2:
	return Rect2(get_visual_center(), Vector2(1,1))

func is_movable() -> bool:
	if position_locked || short_term_position_locked:
		return false
	return true

func moving() -> bool:
	return _global_pos_at_move_start != null

# moves the object within the world immediately without producing any undo
# history. if you wish to get undo history, use the start/update/finish methods.
#
# Subclasses can override this if they wish. For example, nodes that can
# magnetize might want to pass this request through the MagneticArea node.
func apply_global_position(new_global_pos: Vector2) -> void:
	global_position = new_global_pos

func start_move() -> void:
	if moving():
		push_warning("move was already started. starting another one.")
	_global_pos_at_move_start = global_position

func update_move(delta: Vector2) -> bool:
	if ! moving():
		push_warning("can't update_move() when not moving")
		return false
	apply_global_position(_global_pos_at_move_start + delta)
	return true

func finish_move(cancel: bool = false) -> bool:
	if not moving():
		push_warning("move was never started")
		return false
	
	if cancel:
		apply_global_position(_global_pos_at_move_start)
	else:
		moved.emit(self, _global_pos_at_move_start, global_position)
	_global_pos_at_move_start = null
	return true

func get_tooltip_text() -> String:
	return user_label

func get_fluid_entity() -> FEntity:
	return null

func set_fluid_property(prop_key: StringName, new_value: Variant) -> void:
	var res := Utils.get_property_w_path(self, prop_key)
	if ! res.found:
		push_error("fluid property '%s' doesn't exist" % prop_key)
		return
	elif res.value is Var:
		_do_fluid_fvar_set(prop_key, res.value, new_value)
	elif res.value is float:
		var old_value := res.value as float
		res.parent_obj.set(res.last_prop_key, new_value)
		if old_value != new_value:
			fluid_property_changed.emit(self, prop_key, old_value, new_value)
	else:
		push_error("unsupported set on prop_key '%s'" % prop_key)

func serialize() -> Dictionary:
	return {
		PROP_KEY_SUBCLASS : get_type_name(),
		PROP_KEY_POSITION_FT : Utils.vect2_to_pair(Utils.px_to_ft_vec(global_position)),
		PROP_KEY_ROTATION_DEG : int(rotation_degrees),
		PROP_KEY_USER_LABEL : user_label,
		PROP_KEY_INFO_LABEL_VISIBLE : info_label.visible,
		PROP_KEY_POSITION_LOCKED : position_locked
	}

func deserialize(obj: Dictionary) -> void:
	_wobj_props_from_save.global_position = Utils.ft_to_px_vec(
		Utils.pair_to_vect2(DictUtils.get_w_default(obj, PROP_KEY_POSITION_FT, [0.0, 0.0])))
	rotation_degrees = DictUtils.get_w_default(obj, PROP_KEY_ROTATION_DEG, 0.0)
	user_label = obj[PROP_KEY_USER_LABEL]
	_wobj_props_from_save.info_label_visible = DictUtils.get_w_default(obj, PROP_KEY_INFO_LABEL_VISIBLE, false)
	_wobj_props_from_save.positon_locked = DictUtils.get_w_default(obj, PROP_KEY_POSITION_LOCKED, false)

# a method for the WorldObject to perform any necessary initialization logic
# after the Project has instantiated, but before it has deserialized it
func _init_world_obj() -> void:
	pass

func _predelete() -> void:
	parent_project._remove_object(self)

# @return true if the value changed, false if not (does not indicate if change
# event was fired or not)
func _check_and_emit_prop_change(prop_name: StringName, old_value: Variant, force_change: bool = false) -> bool:
	var new_value = get(prop_name)
	var changed : bool = force_change || (old_value != new_value)
	if changed && ! deferred_prop_change.matches(prop_name):
		property_changed.emit(self, prop_name, old_value, new_value)
	return changed

func _do_fluid_fvar_set(prop_key: StringName, fvar: Var, new_value: Variant) -> void:
	var old_value = null
	if new_value is float:
		old_value = fvar.value
		fvar.value = new_value
	elif new_value is Var.State:
		old_value = fvar.state
		fvar.state = new_value
	else:
		push_warning("type of 'new_value' (%s) must be float or Var.State" % new_value)
		return
	
	if old_value != new_value:
		fluid_property_changed.emit(self, prop_key, old_value, new_value)
