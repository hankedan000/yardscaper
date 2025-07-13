extends WorldObject
class_name PipeNode

const BODY_RADIUS_FT = 3.0 / 12.0 # 6in diameter

@onready var draw_layer := $ManualDrawLayer
@onready var magnet_area : MagneticArea = $MagneticArea

func _ready() -> void:
	super._ready()
	
	var body_radius_px := get_body_radius_px()
	var c_shape := pick_coll_shape.shape as CircleShape2D
	c_shape.radius = body_radius_px
	magnet_area.set_radius(body_radius_px)

func _draw() -> void:
	draw_layer.queue_redraw()

func get_subclass() -> String:
	return "PipeNode"

func get_body_radius_px() -> float:
	return Utils.ft_to_px(BODY_RADIUS_FT)

# Overriding the WorldObject's method so we can filter the request through the
# MagneticArea first. Actual position updates will occur via the
# _on_magnetic_area_position_change_request() signal handler.
func _apply_global_position(new_global_pos: Vector2) -> void:
	magnet_area.try_position_change(new_global_pos)

func _on_magnetic_area_position_change_request(new_global_position: Vector2) -> void:
	global_position = new_global_position
