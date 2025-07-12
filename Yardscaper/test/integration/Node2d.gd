extends Node2D

@onready var magnet : MagneticArea = $MagneticArea

func _draw() -> void:
	draw_circle(Vector2(), magnet.get_radius(), Color.RED)
