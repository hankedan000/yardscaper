@tool
extends Gizmo
class_name EditorHandle

enum HandleType {
	None, Sharp, Add, ControlAnchor
}

enum LabelTextMode {
	UserId, UserText
}

enum LabelShowMode {
	Never,         # never visible
	Always,        # always visible
	Manual,        # let user control label visibility
	Hover,         # show when button is hovered
	Pressed,       # show while button is pressed
	HoverOrPressed # show while button is pressed or hovered
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
@export var label_text_mode : LabelTextMode = LabelTextMode.UserId
@export var label_show_mode : LabelShowMode = LabelShowMode.Never
@export var MagneticAreaScene : PackedScene = null
@export_flags_2d_physics var magnetic_physics_mask := 0:
	set(new_value):
		_update_magnetic_mask(new_value)
	get():
		if is_instance_valid(_magnet):
			return _magnet.magnetic_physics_mask
		return 0

@onready var tex_button : TextureButton = $TextureButton
@onready var user_label : Label = $UserLabel

# a user-definable identifier
var user_id : int = 0
var user_text : String = ""
var modulate_on_hover : Color = Color.WHITE
var modulate_on_pressed : Color = Color.WHITE

var _magnet : MagneticArea = null
var _is_hovered : bool = false

func _ready() -> void:
	super._ready()
	
func get_button() -> BaseButton:
	return tex_button

func is_magnetic() -> bool:
	return is_instance_valid(_magnet)

func get_magnet() -> MagneticArea:
	return _magnet

func try_position_change(new_global_position: Vector2) -> void:
	if is_instance_valid(_magnet):
		_magnet.try_position_change(new_global_position)
	else:
		global_position = new_global_position

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

func _update_magnetic_mask(new_physic_mask) -> void:
	if new_physic_mask == 0:
		_destroy_magnet()
	elif is_instance_valid(_magnet):
		_magnet.magnetic_physics_mask = new_physic_mask
	else:
		_create_magnet(new_physic_mask)

func _destroy_magnet() -> void:
	if is_instance_valid(_magnet):
		_magnet.queue_free()
	_magnet = null

func _create_magnet(new_physic_mask) -> void:
	_magnet = MagneticAreaScene.instantiate()
	_magnet.magnetic_physics_mask = new_physic_mask
	_magnet.position_change_request.connect(_on_magnet_position_change_request)
	add_child(_magnet)

func _get_label_text_by_mode() -> String:
	match label_text_mode:
		LabelTextMode.UserId:
			return str(user_id)
		LabelTextMode.UserText:
			return user_text
	push_warning("unsupported LabelTextMode")
	return ""

func _get_label_visible_by_mode() -> bool:
	match label_show_mode:
		LabelShowMode.Never:
			return false
		LabelShowMode.Always:
			return true
		LabelShowMode.Manual:
			return user_label.visible # keep existing state
		LabelShowMode.Hover:
			return _is_hovered
		LabelShowMode.Pressed:
			return tex_button.button_pressed
		LabelShowMode.HoverOrPressed:
			return tex_button.button_pressed || _is_hovered
	push_warning("unsupported LabelShowMode")
	return false

func _get_button_modulate_by_state() -> Color:
	if tex_button.button_pressed:
		return modulate_on_pressed
	elif _is_hovered:
		return modulate_on_hover
	return Color.WHITE

func _update_button_and_label() -> void:
	tex_button.modulate = _get_button_modulate_by_state()
	user_label.text = _get_label_text_by_mode()
	user_label.visible = _get_label_visible_by_mode()
	
	# resize the label to fit the text and center it above the handle
	var new_label_size := Utils.get_label_text_size(user_label, user_label.text)
	user_label.position.x = new_label_size.x / -2.0
	user_label.size = new_label_size

func _on_texture_button_mouse_entered() -> void:
	_is_hovered = true
	_update_button_and_label()

func _on_texture_button_mouse_exited() -> void:
	_is_hovered = false
	_update_button_and_label()

func _on_texture_button_button_down() -> void:
	_update_button_and_label()

func _on_texture_button_button_up() -> void:
	_update_button_and_label()

func _on_magnet_position_change_request(new_global_position: Vector2) -> void:
	global_position = new_global_position
