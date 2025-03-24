@tool
extends Control
class_name StatusIcon

enum StatusType {Success, Warning, Error}

@export var status : StatusType = StatusType.Success :
	set(value):
		status = value
		match status:
			StatusType.Success:
				tex_rect.texture = SuccessTexture
			StatusType.Warning:
				tex_rect.texture = WarningTexture
			StatusType.Error:
				tex_rect.texture = ErrorTexture

@export_category("Status Textures")
@export var SuccessTexture : Texture2D = null
@export var WarningTexture : Texture2D = null
@export var ErrorTexture   : Texture2D = null
				
@onready var tex_rect := $TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
