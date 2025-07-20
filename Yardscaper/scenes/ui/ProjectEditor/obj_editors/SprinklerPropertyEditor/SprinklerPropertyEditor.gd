class_name SprinklerPropertyEditor extends BaseNodePropertyEditor

@onready var zone_spinbox             := $VBoxContainer/PropertiesList/ZoneSpinBox
@onready var rot_spinbox              := $VBoxContainer/PropertiesList/RotationSpinBox
@onready var sweep_spinbox            := $VBoxContainer/PropertiesList/SweepSpinBox
@onready var manu_option              := $VBoxContainer/PropertiesList/ManufacturerOption
@onready var model_option             := $VBoxContainer/PropertiesList/ModelOption
@onready var min_dist_spinbox         := $VBoxContainer/PropertiesList/MinDistanceSpinBox
@onready var max_dist_spinbox         := $VBoxContainer/PropertiesList/MaxDistanceSpinBox
@onready var dist_spinbox             := $VBoxContainer/PropertiesList/DistanceSpinBox
@onready var body_color_picker        := $VBoxContainer/PropertiesList/BodyColorPicker

var _layout_panel : LayoutPanel = null

func _ready():
	super._ready()
	_setup_long_length_spinbox(min_dist_spinbox)
	_setup_long_length_spinbox(max_dist_spinbox)
	_setup_long_length_spinbox(dist_spinbox)
	_update_ui_from_sprinkler_db()

func set_layout_panel(layout_panel: LayoutPanel) -> void:
	_layout_panel = layout_panel

# override so we can validate the type
func add_object(wobj: WorldObject) -> void:
	if wobj is Sprinkler:
		super.add_object(wobj)

func _sync_ui_from_obj() -> void:
	super._sync_ui_from_obj()
	
	var ref_sprink := _wobjs[0] as Sprinkler
	multi_edit_warning.text = "Editing %d sprinklers" % _wobjs.size()
	
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

func _sync_option_to_text(option_button: OptionButton, text: String):
	for idx in range(option_button.item_count):
		if option_button.get_item_text(idx) == text:
			option_button.selected = idx
			return
	option_button.selected = 0

func _on_zone_spin_box_value_changed(value):
	_apply_prop_edit(Sprinkler.PROP_KEY_ZONE, value)

func _on_sweep_spin_box_value_changed(sweep_deg):
	_apply_prop_edit(Sprinkler.PROP_KEY_SWEEP_DEG, sweep_deg)

func _on_rotation_spin_box_value_changed(rot_deg):
	_apply_prop_edit(Sprinkler.PROP_KEY_ROTATION_DEG, rot_deg)

func _on_manufacturer_option_item_selected(index):
	var manufacturer = manu_option.get_item_text(index)
	_update_model_options(manufacturer)
	_apply_prop_edit(Sprinkler.PROP_KEY_MANUFACTURER, manufacturer)

func _on_model_option_item_selected(index):
	_apply_prop_edit(Sprinkler.PROP_KEY_MODEL, model_option.get_item_text(index))

func _on_distance_spin_box_value_changed(value):
	_apply_prop_edit(Sprinkler.PROP_KEY_DIST_FT, value)

func _on_min_distance_spin_box_value_changed(value):
	_apply_prop_edit(Sprinkler.PROP_KEY_MIN_DIST_FT, value)

func _on_max_distance_spin_box_value_changed(value):
	_apply_prop_edit(Sprinkler.PROP_KEY_MAX_DIST_FT, value)

func _on_body_color_picker_color_changed(color: Color) -> void:
	_apply_prop_edit(Sprinkler.PROP_KEY_BODY_COLOR, color)

func _on_body_color_picker_pressed() -> void:
	for sprink: Sprinkler in _wobjs:
		sprink.deferred_prop_change.push(Sprinkler.PROP_KEY_BODY_COLOR)

func _on_body_color_picker_popup_closed() -> void:
	for sprink: Sprinkler in _wobjs:
		sprink.deferred_prop_change.pop(Sprinkler.PROP_KEY_BODY_COLOR)
