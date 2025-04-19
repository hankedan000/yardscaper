extends Node2D
class_name Gizmo

func _ready() -> void:
	var zoom := get_viewport().get_camera_2d().zoom.x
	var inv_scale := Vector2(1.0, 1.0) * (1.0 / zoom)
	on_zoom_changed(zoom, inv_scale)

func on_zoom_changed(_new_zoom: float, inv_scale: Vector2) -> void:
	scale = inv_scale
