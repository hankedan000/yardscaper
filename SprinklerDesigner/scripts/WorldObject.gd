extends Node2D
class_name WorldObject

signal property_changed(obj, property, from, to)

var user_label : String = "" :
	set(value):
		var old_value = user_label
		user_label = value
		if old_value != user_label:
			emit_signal('property_changed', 'user_label', old_value, user_label)

func get_subclass() -> String:
	return "WorldObject"

func serialize():
	var position_ft = Utils.px_to_ft_vec(position)
	return {
		'subclass' : get_subclass(),
		'position_ft' : [position_ft.x, position_ft.y],
		'rotation_deg' : int(rotation_degrees),
		'user_label' : user_label
	}

func deserialize(obj):
	var pos_ft = obj['position_ft']
	position = Vector2(Utils.ft_to_px(pos_ft[0]), Utils.ft_to_px(pos_ft[1]))
	rotation_degrees = obj['rotation_deg']
	user_label = obj['user_label']
