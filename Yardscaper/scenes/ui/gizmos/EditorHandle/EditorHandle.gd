@tool
extends Node2D
class_name EditorHandle

@export var SharpHandleTexture : Texture2D = null
@export var AddHandleTexture : Texture2D = null

enum HandleType {
	Sharp, Add
}

@onready var tex_button : TextureButton = $TextureButton

var type : HandleType = HandleType.Sharp:
	set(value):
		if ! is_inside_tree():
			await ready
		type = value
		match type:
			HandleType.Sharp:
				_setup_button(tex_button, SharpHandleTexture)
				modulate_on_hover = Color.YELLOW
			HandleType.Add:
				_setup_button(tex_button, AddHandleTexture)
				modulate_on_hover = Color.WHITE

# a user-definable identifier
var user_id : int = 0

var modulate_on_hover : Color = Color.WHITE

func _ready() -> void:
	type = HandleType.Sharp

func base_button() -> BaseButton:
	return tex_button

func _on_texture_button_mouse_entered() -> void:
	tex_button.modulate = modulate_on_hover

func _on_texture_button_mouse_exited() -> void:
	tex_button.modulate = Color.WHITE

func _setup_button(button: TextureButton, tex: Texture2D) -> void:
	button.texture_normal = tex
	button.size = tex.get_size()
	button.position = Vector2() - (button.size / 2.0) # center button on handle origin
