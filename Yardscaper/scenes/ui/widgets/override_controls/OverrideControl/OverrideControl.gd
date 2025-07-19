class_name OverrideControl extends HBoxContainer

signal override_changed(new_overriden: bool)
signal value_changed(new_value: Variant)

@export var override_tooltip_text : String = "Check to override the value"
@export_node_path("Control") var control_path : NodePath = ""

@onready var _checkbox : CheckBox = $CheckBox

var control : Control = null

func _ready() -> void:
	_checkbox.tooltip_text = override_tooltip_text
	if ! control_path.is_empty():
		control = get_node(control_path)
	
	if ! is_instance_valid(control):
		push_warning("control is null")
	else:
		if control is SpinBox:
			control.value_changed.connect(_on_spin_box_value_changed)
		elif control is LineEdit:
			control.text_submitted.connect(_on_line_edit_text_submitted)
		_sync_checkbox_to_control()

func set_control_value(value: Variant) -> void:
	if ! is_instance_valid(control):
		return
	
	if control is SpinBox:
		control.value = value as float
	elif control is LineEdit:
		control.text = value as String
	else:
		push_warning("unsupported control type")

func get_control_value() -> Variant:
	if ! is_instance_valid(control):
		return null
	
	if control is SpinBox:
		return control.value
	elif control is LineEdit:
		return control.text
	else:
		push_warning("unsupported control type")
	return null

func set_overriden(new_overriden: bool) -> void:
	if new_overriden == is_overriden():
		return # no change
	_checkbox.button_pressed = new_overriden
	_handle_override_change(new_overriden)

func is_overriden() -> bool:
	return _checkbox.button_pressed

func _sync_checkbox_to_control() -> void:
	if ! is_instance_valid(control):
		return
	
	var overriden := is_overriden()
	if overriden:
		control.tooltip_text = ""
	else:
		control.tooltip_text = "Check the box to enable editing"
	
	if control is SpinBox:
		control.editable = overriden
	elif control is LineEdit:
		control.editable = overriden
	else:
		push_warning("unsupported control type")

func _handle_override_change(new_overriden: bool) -> void:
	_sync_checkbox_to_control()
	override_changed.emit(new_overriden)

func _on_check_box_toggled(toggled_on: bool) -> void:
	_handle_override_change(toggled_on)

func _on_spin_box_value_changed(value: float) -> void:
	value_changed.emit(value)

func _on_line_edit_text_submitted(new_text: String) -> void:
	value_changed.emit(new_text)
