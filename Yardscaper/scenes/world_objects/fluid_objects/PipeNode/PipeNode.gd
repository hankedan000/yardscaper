class_name PipeNode extends BaseNode

const BODY_RADIUS_FT = 3.0 / 12.0 # 6in diameter

@onready var draw_layer := $ManualDrawLayer

func _ready() -> void:
	super._ready()
	
	var body_radius_px := get_body_radius_px()
	magnet_area.set_radius(body_radius_px)

func _draw() -> void:
	draw_layer.queue_redraw()

func get_type_name() -> StringName:
	return TypeNames.PIPE_NODE

func get_body_radius_px() -> float:
	return Utils.ft_to_px(BODY_RADIUS_FT)
