class_name SprinklerPropertyEditor extends BaseNodePropertyEditor

@onready var zone_spinbox             := $VBoxContainer/PropertiesList/ZoneSpinBox
@onready var rot_spinbox              := $VBoxContainer/PropertiesList/RotationSpinBox
@onready var sweep_spinbox            := $VBoxContainer/PropertiesList/SweepSpinBox
@onready var manu_option              := $VBoxContainer/PropertiesList/ManufacturerOption
@onready var head_option              := $VBoxContainer/PropertiesList/HeadOption
@onready var nozzle_label             := $VBoxContainer/PropertiesList/NozzleLabel
@onready var nozzle_option            := $VBoxContainer/PropertiesList/NozzleOption
@onready var dist_spinbox             := $VBoxContainer/PropertiesList/DistanceSpinBox
@onready var body_color_picker        := $VBoxContainer/PropertiesList/BodyColorPicker

var _layout_panel : LayoutPanel = null

func _ready():
	super._ready()
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
	_update_head_options(ref_sprink.manufacturer)
	_sync_option_to_text(head_option, ref_sprink.head_model)
	_update_nozzle_options(ref_sprink.get_head_data())
	_sync_option_to_text(nozzle_option, ref_sprink.nozzle_option)
	dist_spinbox.min_value = ref_sprink.min_dist_ft()
	dist_spinbox.max_value = ref_sprink.max_dist_ft()
	dist_spinbox.value = ref_sprink.dist_ft
	body_color_picker.color = ref_sprink.body_color

# update manufactuer/model information from sprinkler database
func _update_ui_from_sprinkler_db():
	manu_option.clear()
	var item_idx := 0
	for manu_name in TheSprinklerDB.get_manufacturer_names():
		manu_option.add_item(manu_name)
		var manu_data := TheSprinklerDB.get_manufacturer(manu_name)
		if manu_data.get_head_count() == 0:
			manu_option.set_item_disabled(item_idx, true)
			manu_option.set_item_tooltip(item_idx, "doesn't have any head options")
		item_idx += 1
	_update_head_options(manu_option.get_item_text(manu_option.selected))
	queue_ui_sync()

# update model options based on the manufacturer
func _update_head_options(manu_name: String) -> void:
	head_option.clear()
	var manu_data := TheSprinklerDB.get_manufacturer(manu_name)
	if ! is_instance_valid(manu_data):
		return
	
	for head_model in manu_data.get_head_models():
		head_option.add_item(head_model)
	queue_ui_sync()

# update nozzle options based on the head_data
func _update_nozzle_options(head_data: SprinklerHeadData) -> void:
	nozzle_option.clear()
	nozzle_option.visible = false
	nozzle_label.visible = false
	if ! is_instance_valid(head_data):
		return
	
	var nozzle_opts := head_data.flow_model.get_nozzle_options()
	if nozzle_opts.is_empty():
		return
	
	nozzle_option.visible = true
	nozzle_label.visible = true
	for option in nozzle_opts:
		nozzle_option.add_item(option)
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
	_update_head_options(manufacturer)
	_apply_prop_edit(Sprinkler.PROP_KEY_MANUFACTURER, manufacturer)

func _on_head_option_item_selected(index: int) -> void:
	_apply_prop_edit(Sprinkler.PROP_KEY_HEAD_MODEL, head_option.get_item_text(index))

func _on_nozzle_option_item_selected(index: int) -> void:
	_apply_prop_edit(Sprinkler.PROP_KEY_NOZZLE_OPTION, nozzle_option.get_item_text(index))

func _on_distance_spin_box_value_changed(value):
	_apply_prop_edit(Sprinkler.PROP_KEY_DIST_FT, value)

func _on_body_color_picker_color_changed(color: Color) -> void:
	_apply_prop_edit(Sprinkler.PROP_KEY_BODY_COLOR, color)

func _on_body_color_picker_pressed() -> void:
	for sprink: Sprinkler in _wobjs:
		sprink.deferred_prop_change.push(Sprinkler.PROP_KEY_BODY_COLOR)

func _on_body_color_picker_popup_closed() -> void:
	for sprink: Sprinkler in _wobjs:
		sprink.deferred_prop_change.pop(Sprinkler.PROP_KEY_BODY_COLOR)
