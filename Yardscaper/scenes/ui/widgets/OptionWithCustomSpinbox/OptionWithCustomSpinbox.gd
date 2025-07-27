class_name OptionWithCustomSpinbox extends VBoxContainer

signal option_changed(option_text: String, option_id: int)
signal custom_value_changed(new_value: float)

@onready var option_button : OptionButton = $OptionButton
@onready var spinbox_label : Label = $CustomContainer/Label
@onready var spinbox       : SpinBox = $CustomContainer/SpinBox

@onready var _custom_container := $CustomContainer

var _custom_option_id = null

func get_selected_option_id() -> int:
	return option_button.get_item_id(option_button.selected)

func set_custom_option_id(id: int) -> void:
	_custom_option_id = id
	_custom_container.show()
	_update_spinbox_editable()

func select_option_by_id(id: int) -> void:
	for idx in range(option_button.item_count):
		if id == option_button.get_item_id(idx):
			option_button.selected = idx
			return

func disable_custom_option() -> void:
	_custom_option_id = null
	_custom_container.hide()

func clear() -> void:
	option_button.clear()
	disable_custom_option()

func add_option(label: String, id: int, icon: Texture2D, is_custom_option: bool) -> void:
	var item_idx := option_button.item_count
	option_button.add_item(label, id)
	option_button.set_item_icon(item_idx, icon)
	if is_custom_option:
		set_custom_option_id(id)

func _update_spinbox_editable() -> void:
	if _custom_option_id == null:
		return
	spinbox.editable = _custom_option_id == get_selected_option_id()

func _on_spin_box_value_changed(value: float) -> void:
	if _custom_option_id == null:
		return
	elif _custom_option_id == get_selected_option_id():
		custom_value_changed.emit(value)

func _on_option_button_item_selected(index: int) -> void:
	var option_text := option_button.get_item_text(index)
	var option_id := option_button.get_item_id(index)
	_update_spinbox_editable()
	option_changed.emit(option_text, option_id)
