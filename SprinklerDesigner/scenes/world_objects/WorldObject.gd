extends Node2D
class_name WorldObject

signal property_changed(obj, property, from, to)

var world : WorldViewportContainer = null

var user_label : String = "" :
	set(value):
		var old_value = user_label
		user_label = value
		if old_value != user_label:
			emit_signal('property_changed', 'user_label', old_value, user_label)

func _ready():
	# locate our parent WorldViewportContainer
	var parent = get_parent()
	while parent != null:
		if parent is WorldViewportContainer:
			world = parent
			break
		parent = parent.get_parent()

func get_subclass() -> String:
	return "WorldObject"

func serialize():
	return {
		'subclass' : get_subclass(),
		'position_ft' : Utils.vect2_to_pair(Utils.px_to_ft_vec(position)),
		'rotation_deg' : int(rotation_degrees),
		'user_label' : user_label
	}

func deserialize(obj):
	position = Utils.ft_to_px_vec(Utils.pair_to_vect2(obj['position_ft']))
	rotation_degrees = obj['rotation_deg']
	user_label = obj['user_label']
