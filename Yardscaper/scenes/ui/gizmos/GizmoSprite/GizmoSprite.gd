class_name GizmoSprite extends Gizmo

@export var initial_texture : Texture2D = null
@export var offset_on_zoom_change := false

# how much to offset the sprite's position by when the zoom changed.
# factor get's multiplied against the sprite's new size.
@export var position_offset_factor := Vector2()

@onready var sprite : Sprite2D = $Sprite

func _ready() -> void:
	super._ready()
	set_sprite_texture(initial_texture)

func set_sprite_texture(new_tex: Texture2D) -> void:
	if is_instance_valid(sprite):
		sprite.texture = new_tex
	else:
		# might not be 'ready' yet, so just buffer it until we are
		initial_texture = new_tex

# override's Gizmo::on_zoom_changed()
func on_zoom_changed(new_zoom: float, inv_scale: Vector2) -> void:
	super.on_zoom_changed(new_zoom, inv_scale)
	if offset_on_zoom_change:
		sprite.position.x = sprite.get_rect().size.x * position_offset_factor.x
		sprite.position.y = sprite.get_rect().size.y * position_offset_factor.y
