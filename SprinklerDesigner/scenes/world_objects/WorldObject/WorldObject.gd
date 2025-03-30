extends Node2D
class_name WorldObject

signal property_changed(obj, property, from, to)

@onready var info_label : Label = $InfoLabel

var world : WorldViewportContainer = null
var _is_ready = false

var user_label : String = "" :
	set(value):
		var old_value = user_label
		user_label = value
		if old_value != user_label:
			property_changed.emit('user_label', old_value, user_label)

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
	if ! _is_ready:
		await ready
	if ! world:
		push_error("object isn't in a world")
		return -1
	return world.get_object_order_idx(self)

func set_order_in_world(to_idx: int):
	var from_idx = await get_order_in_world()
	if from_idx < 0:
		push_error("unable to get object's from_idx")
		return
	world.reorder_world_object(from_idx, to_idx)

func get_info_label_visible() -> bool:
	return info_label.visible

func set_info_label_visible(new_visible: bool) -> void:
	var old_value = info_label.visible
	info_label.visible = new_visible
	if old_value != new_visible:
		property_changed.emit('info_label.visible', old_value, new_visible)

func serialize():
	return {
		'subclass' : get_subclass(),
		'position_ft' : Utils.vect2_to_pair(Utils.px_to_ft_vec(position)),
		'rotation_deg' : int(rotation_degrees),
		'user_label' : user_label,
		'info_label.visible': info_label.visible
	}

func deserialize(obj):
	if ! _is_ready:
		await ready
	position = Utils.ft_to_px_vec(Utils.pair_to_vect2(obj['position_ft']))
	rotation_degrees = obj['rotation_deg']
	user_label = obj['user_label']
	info_label.visible = Utils.dict_get(obj, 'info_label.visible', false)
