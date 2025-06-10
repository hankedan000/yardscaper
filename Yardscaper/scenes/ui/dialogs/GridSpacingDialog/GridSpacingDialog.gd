extends Window
class_name GridSpacingDialog

signal apply(major_spacing_ft: Vector2)
signal spacing_changed(major_spacing_ft: Vector2)
signal cancel(original_major_spacing_ft: Vector2)

@onready var major_x_spinbox := $PanelContainer/VBoxContainer/GridContainer/MajorX_SpinBox
@onready var major_y_spinbox := $PanelContainer/VBoxContainer/GridContainer/MajorY_SpinBox

var _orig_major_spacing_ft := Vector2()

func setup(curr_major_spacing_ft: Vector2) -> void:
	_orig_major_spacing_ft = curr_major_spacing_ft
	major_x_spinbox.value = curr_major_spacing_ft.x
	major_y_spinbox.value = curr_major_spacing_ft.y

func get_major_spacing_ft() -> Vector2:
	return Vector2(major_x_spinbox.value, major_y_spinbox.value)

func _on_apply_button_pressed() -> void:
	hide()
	apply.emit(get_major_spacing_ft())

func _on_cancel_button_pressed() -> void:
	hide()
	cancel.emit(_orig_major_spacing_ft)

func _on_major_x_spin_box_value_changed(_value: float) -> void:
	spacing_changed.emit(get_major_spacing_ft())

func _on_major_y_spin_box_value_changed(_value: float) -> void:
	spacing_changed.emit(get_major_spacing_ft())

func _on_close_requested() -> void:
	_on_cancel_button_pressed()
