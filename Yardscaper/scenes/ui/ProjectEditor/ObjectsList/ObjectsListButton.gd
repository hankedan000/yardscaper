extends Button
class_name ObjectsListButton

var world_object : WorldObject = null:
	set(value):
		if is_instance_valid(world_object):
			world_object.picked_state_changed.disconnect(_on_object_picked_state_changed)
		
		world_object = value
		
		text = world_object.user_label if world_object else "Null Object"
		disabled = world_object == null
		toggle_mode = true
		button_pressed = world_object.picked
		world_object.picked_state_changed.connect(_on_object_picked_state_changed)

func _on_toggled(toggled_on: bool) -> void:
	world_object.picked = toggled_on

func _on_object_picked_state_changed():
	button_pressed = world_object.picked
