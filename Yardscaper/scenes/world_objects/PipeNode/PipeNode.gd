extends WorldObject
class_name PipeNode

const BODY_RADIUS_FT = 3.0 / 12.0 # 6in diameter

func _ready() -> void:
	super._ready()
	
	var c_shape := pick_coll_shape.shape as CircleShape2D
	c_shape.radius = Utils.ft_to_px(BODY_RADIUS_FT)

func get_subclass() -> String:
	return "PipeNode"
