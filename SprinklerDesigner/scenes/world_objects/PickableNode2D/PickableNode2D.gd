extends WorldObject
class_name PickableNode2D

@onready var pick_area := $PickArea
@onready var pick_coll_shape := $PickArea/CollisionShape2D

var hovering : bool = false : set = set_hovering
var picked : bool = false : set = set_picked

func set_hovering(value: bool):
	hovering = value
	queue_redraw()

func set_picked(value: bool):
	picked = value
	queue_redraw()

func get_subclass() -> String:
	return "PickableNode2D"
