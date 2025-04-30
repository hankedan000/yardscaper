extends PanelContainer
class_name SprinklerPropertyEditor

@onready var user_label_lineedit      := $VBoxContainer/SprinklerPropertiesList/UserLabelLineEdit
@onready var zone_spinbox             := $VBoxContainer/SprinklerPropertiesList/ZoneSpinBox
@onready var rot_spinbox              := $VBoxContainer/SprinklerPropertiesList/RotationSpinBox
@onready var sweep_spinbox            := $VBoxContainer/SprinklerPropertiesList/SweepSpinBox
@onready var manu_option              := $VBoxContainer/SprinklerPropertiesList/ManufacturerOption
@onready var model_option             := $VBoxContainer/SprinklerPropertiesList/ModelOption
@onready var min_dist_spinbox         := $VBoxContainer/SprinklerPropertiesList/MinDistanceSpinBox
@onready var max_dist_spinbox         := $VBoxContainer/SprinklerPropertiesList/MaxDistanceSpinBox
@onready var dist_spinbox             := $VBoxContainer/SprinklerPropertiesList/DistanceSpinBox
@onready var body_color_picker        := $VBoxContainer/SprinklerPropertiesList/BodyColorPicker
@onready var multi_edit_warning       := $VBoxContainer/MultiEditWarning

var _layout_panel : LayoutPanel = null
var _sprinklers : Array[Sprinkler] = []
var _ui_needs_sync = false
var _ignore_internal_edits = false

func _ready():
	_update_ui_from_sprinkler_db()

func _process(_delta):
	if _ui_needs_sync:
		_sync_ui()

func set_layout_panel(layout_panel: LayoutPanel) -> void:
	_layout_panel = layout_panel

func add_sprinkler(s: Sprinkler) -> void:
	if s == null:
		return
	elif s in _sprinklers:
		return
	
	s.property_changed.connect(_on_sprinkler_property_changed)
	_sprinklers.push_back(s)
	queue_ui_sync()

func remove_sprinkler(s: Sprinkler) -> void:
	var idx := _sprinklers.find(s)
	if idx < 0:
		return
	
	s.property_changed.disconnect(_on_sprinkler_property_changed)
	_sprinklers.remove_at(idx)
	queue_ui_sync()

func clear_sprinklers() -> void:
	for s in _sprinklers.duplicate():
		remove_sprinkler(s)

func queue_ui_sync():
	_ui_needs_sync = true

# update manufactuer/model information from sprinkler database
func _update_ui_from_sprinkler_db():
	manu_option.clear()
	manu_option.add_item("") # default 'none' option
	for manu in TheSprinklerDb.get_manufacturers():
		manu_option.add_item(manu)
	_update_model_options(manu_option.get_item_text(manu_option.selected))
	queue_ui_sync()

# update model options based on the manufacturer
func _update_model_options(manufacturer: String):
	model_option.clear()
	model_option.add_item("") # default 'none' option
	for model in TheSprinklerDb.get_head_models(manufacturer):
		model_option.add_item(model)
	queue_ui_sync()

# synchronize UI elements to existing properties of the sprinkler
func _sync_ui():
	if _sprinklers.is_empty():
		_ui_needs_sync = false
		return
	
	var ref_sprink := _sprinklers[0]
	var single_edit := _sprinklers.size() == 1
	user_label_lineedit.editable = single_edit
	multi_edit_warning.visible = ! single_edit
	multi_edit_warning.text = "Editing %d sprinklers" % _sprinklers.size()
	
	_ignore_internal_edits = true
	user_label_lineedit.text = ref_sprink.user_label if single_edit else "---"
	zone_spinbox.value = ref_sprink.zone
	rot_spinbox.value = ref_sprink.rotation_degrees
	sweep_spinbox.value = ref_sprink.sweep_deg
	_sync_option_to_text(manu_option, ref_sprink.manufacturer)
	_update_model_options(ref_sprink.manufacturer)
	_sync_option_to_text(model_option, ref_sprink.model)
	min_dist_spinbox.value = ref_sprink.min_dist_ft
	max_dist_spinbox.value = ref_sprink.max_dist_ft
	dist_spinbox.min_value = min_dist_spinbox.value
	dist_spinbox.max_value = max_dist_spinbox.value
	dist_spinbox.value = ref_sprink.dist_ft
	body_color_picker.color = ref_sprink.body_color
	_ignore_internal_edits = false
	_ui_needs_sync = false

func _sync_option_to_text(option_button: OptionButton, text: String):
	for idx in range(option_button.item_count):
		if option_button.get_item_text(idx) == text:
			option_button.selected = idx
			return
	option_button.selected = 0

func _apply_prop_edit(prop_name: StringName, new_value: Variant) -> void:
	if _ignore_internal_edits:
		return
	_layout_panel.start_batch_edit(prop_name)
	for s in _sprinklers:
		s.set(prop_name, new_value)
	_layout_panel.stop_batch_edit()

func _on_user_label_line_edit_text_submitted(new_text):
	_apply_prop_edit(&"user_label", new_text)

func _on_zone_spin_box_value_changed(value):
	_apply_prop_edit(&"zone", value)

func _on_sweep_spin_box_value_changed(sweep_deg):
	_apply_prop_edit(&"sweep_deg", sweep_deg)

func _on_rotation_spin_box_value_changed(rot_deg):
	_apply_prop_edit(&"rotation_degrees", rot_deg)

func _on_manufacturer_option_item_selected(index):
	var manufacturer = manu_option.get_item_text(index)
	_update_model_options(manufacturer)
	_apply_prop_edit(&"manufacturer", manufacturer)

func _on_model_option_item_selected(index):
	_apply_prop_edit(&"model", model_option.get_item_text(index))

func _on_distance_spin_box_value_changed(value):
	_apply_prop_edit(&"dist_ft", value)

func _on_min_distance_spin_box_value_changed(value):
	_apply_prop_edit(&"min_dist_ft", value)

func _on_max_distance_spin_box_value_changed(value):
	_apply_prop_edit(&"max_dist_ft", value)

func _on_sprinkler_property_changed(_obj: WorldObject, _property: StringName, _from: Variant, _to: Variant) -> void:
	queue_ui_sync()

func _on_body_color_picker_color_changed(color: Color) -> void:
	_apply_prop_edit(&"body_color", color)

func _on_body_color_picker_pressed() -> void:
	for s in _sprinklers:
		s.deferred_prop_change.push(Sprinkler.PROP_KEY_BODY_COLOR)

func _on_body_color_picker_popup_closed() -> void:
	for s in _sprinklers:
		s.deferred_prop_change.pop(Sprinkler.PROP_KEY_BODY_COLOR)
