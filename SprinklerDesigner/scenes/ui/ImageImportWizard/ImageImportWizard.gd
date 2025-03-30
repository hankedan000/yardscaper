extends Window
class_name ImageImportWizard

signal accepted(img_path: String, size_ft: Vector2)

enum SetMode {Idle, RefA, RefB, RealDist}

@onready var world : WorldViewportContainer = $PanelContainer/HSplitContainer/ViewportContainer
@onready var real_dist_spinbox : SpinBox = $PanelContainer/HSplitContainer/PanelContainer/VBoxContainer/RealDistHBox/RealDistanceSpinBox
@onready var help_label := $PanelContainer/HSplitContainer/PanelContainer/VBoxContainer/HelpLabel
@onready var ref_node_a := $PanelContainer/HSplitContainer/ViewportContainer/RefNodeA
@onready var ref_node_b := $PanelContainer/HSplitContainer/ViewportContainer/RefNodeB
@onready var accept_button := $PanelContainer/HSplitContainer/PanelContainer/VBoxContainer/HBoxContainer/AcceptButton

var texture_rect : TextureRect = TextureRect.new()

var _img_path : String = ""
var _img_original_size_px : Vector2 = Vector2()
var _set_mode : SetMode = SetMode.Idle:
	set(value):
		_set_mode = value
		match _set_mode:
			SetMode.RefA:
				help_label.text = "You'll define 2 reference points, and then specify the real-world distance between them. Click to define the 1st reference point."
			SetMode.RefB:
				help_label.text = "Click to define the 2nd reference point."
			SetMode.RealDist:
				help_label.text = "Specify the real-world distance between the two reference points, then click 'Accept'."
				real_dist_spinbox.editable = true

func _ready() -> void:
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world.objects.add_child(texture_rect)
	ref_node_a.reparent(world.objects)
	ref_node_b.reparent(world.objects)
	reset()

func reset() -> void:
	_img_path = ""
	texture_rect.texture = null
	ref_node_a.visible = false
	ref_node_b.visible = false
	real_dist_spinbox.value = 1.0
	real_dist_spinbox.editable = false
	accept_button.disabled = true

func load_img(img_path: String) -> bool:
	reset()
	var img := Image.load_from_file(img_path)
	if img == null:
		return false
	
	_img_path = img_path
	_img_original_size_px = Vector2(img.get_width(), img.get_height())
	texture_rect.texture = ImageTexture.create_from_image(img)
	texture_rect.size = _img_original_size_px
	world.camera2d.position = _img_original_size_px / 2.0
	_set_mode = SetMode.RefA
	return true

func _on_close_requested() -> void:
	hide()

func _on_viewport_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var world_pos_px := world.global_xy_to_pos_in_world(event.global_position)
		match _set_mode:
			SetMode.RefA:
				ref_node_a.visible = true
				ref_node_a.position = world_pos_px
			SetMode.RefB:
				ref_node_b.visible = true
				ref_node_b.position = world_pos_px
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			match _set_mode:
				SetMode.RefA:
					_set_mode = SetMode.RefB
				SetMode.RefB:
					_set_mode = SetMode.RealDist
					ref_node_a.visible = false
					ref_node_b.visible = false
					real_dist_spinbox.editable = true
					accept_button.disabled = false
					var ref_vec_px := (ref_node_b.position - ref_node_a.position) as Vector2
					var dist_px := ref_vec_px.length()
					real_dist_spinbox.value = Utils.px_to_ft(dist_px)

func _on_cancel_button_pressed() -> void:
	hide()

func _on_reset_button_pressed() -> void:
	texture_rect.size = _img_original_size_px
	ref_node_a.visible = false
	ref_node_b.visible = false
	real_dist_spinbox.editable = false
	accept_button.disabled = true
	real_dist_spinbox.value = 1.0
	_set_mode = SetMode.RefA

func _calc_img_size_ft(ref_dist_ft: float) -> Vector2:
	var ref_vec_px := (ref_node_b.position - ref_node_a.position) as Vector2
	var dist_px := ref_vec_px.length()
	if dist_px > 0.0:
		var ft_per_px := ref_dist_ft / ref_vec_px.length()
		var img_size_ft := _img_original_size_px * ft_per_px
		return img_size_ft
	# return default conversion
	return Vector2(
		Utils.px_to_ft(_img_original_size_px.x),
		Utils.px_to_ft(_img_original_size_px.y))

func _on_accept_button_pressed() -> void:
	accepted.emit(_img_path, _calc_img_size_ft(real_dist_spinbox.value))
	hide()

func _on_real_distance_spin_box_value_changed(value: float) -> void:
	var img_size_ft := _calc_img_size_ft(value)
	texture_rect.size.x = Utils.ft_to_px(img_size_ft.x)
	texture_rect.size.y = Utils.ft_to_px(img_size_ft.y)
