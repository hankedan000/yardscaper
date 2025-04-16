@tool
extends Gizmo
class_name EditorHandle

enum HandleType {
	None, Sharp, Add, ControlAnchor
}

@export var SharpHandleTexture : Texture2D = null
@export var AddHandleTexture : Texture2D = null
@export var ControlAnchorTexture : Texture2D = null
@export var normal_type : HandleType = HandleType.Sharp:
	set(value):
		normal_type = value
		_set_button_texture(&"texture_normal", value)
@export var pressed_type : HandleType = HandleType.None:
	set(value):
		pressed_type = value
		_set_button_texture(&"texture_pressed", value)
@export var hover_type : HandleType = HandleType.None:
	set(value):
		hover_type = value
		_set_button_texture(&"texture_hover", value)
@export var show_label_on_hover : bool = true

@onready var tex_button : TextureButton = $TextureButton
@onready var user_id_label : Label = $UserIdLabel

# a user-definable identifier
var user_id : int = 0:
	set(value):
		user_id = value
		if ! is_inside_tree():
			await ready
		user_id_label.text = str(user_id)

var modulate_on_hover : Color = Color.WHITE

func get_button() -> BaseButton:
	return tex_button

func _get_texture_from_type(type: HandleType) -> Texture2D:
	match type:
		HandleType.Sharp:
			return SharpHandleTexture
		HandleType.Add:
			return AddHandleTexture
		HandleType.ControlAnchor:
			return ControlAnchorTexture
	return null

func _set_button_texture(tex_property: StringName, type: HandleType) -> void:
	if ! is_inside_tree():
		await ready
	var tex2d := _get_texture_from_type(type)
	tex_button.set(tex_property, tex2d)
	if tex2d:
		tex_button.size = tex2d.get_size()
		tex_button.position = Vector2() - (tex_button.size / 2.0)

func _on_texture_button_mouse_entered() -> void:
	tex_button.modulate = modulate_on_hover
	if show_label_on_hover:
		user_id_label.visible = true

func _on_texture_button_mouse_exited() -> void:
	tex_button.modulate = Color.WHITE
	if show_label_on_hover:
		user_id_label.visible = false
