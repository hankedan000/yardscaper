class_name GizmoSprite extends Gizmo

@onready var sprite : Sprite2D = $Sprite

# how much to offset the sprite's position by when the zoom changed.
# factor get's multiplied against the sprite's new size.
@export var position_offset_factor := Vector2()

# override's Gizmo::on_zoom_changed()
func on_zoom_changed(new_zoom: float, inv_scale: Vector2) -> void:
	super.on_zoom_changed(new_zoom, inv_scale)
	sprite.position.x = sprite.get_rect().size.x * position_offset_factor.x
	sprite.position.y = sprite.get_rect().size.y * position_offset_factor.y
