extends WorldObject
class_name PickableNode2D

signal picked_state_changed()

@onready var pick_area := $PickArea
@onready var pick_coll_shape := $PickArea/CollisionShape2D

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

func get_global_center() -> Vector2:
	return global_position

func get_subclass() -> String:
	return "PickableNode2D"
