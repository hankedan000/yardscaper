class_name LockIndicator
extends Gizmo

@onready var sprite : Sprite2D = $Sprite

# override's Gizmo::on_zoom_changed()
func on_zoom_changed(new_zoom: float, inv_scale: Vector2) -> void:
	super.on_zoom_changed(new_zoom, inv_scale)
	sprite.position = Vector2(0, sprite.get_rect().size.y * -0.8)
