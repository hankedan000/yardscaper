extends GridContainer
class_name SprinklerPropertyEditor

@onready var user_label_lineedit      := $UserLabelLineEdit
@onready var zone_spinbox             := $ZoneSpinBox
@onready var rot_spinbox              := $RotationSpinBox
@onready var sweep_spinbox            := $SweepSpinBox
@onready var manu_option              := $ManufacturerOption
@onready var model_option             := $ModelOption
@onready var min_dist_spinbox         := $MinDistanceSpinBox
@onready var max_dist_spinbox         := $MaxDistanceSpinBox
@onready var dist_spinbox             := $DistanceSpinBox

var sprinkler : Sprinkler = null:
	set(obj):
		if obj == sprinkler:
			return # ignore duplicate sets
		
		# forget about previous sprinkler
		if sprinkler != null:
			sprinkler.property_changed.disconnect(_on_sprinkler_property_changed)
		
		if obj is Sprinkler:
			obj.property_changed.connect(_on_sprinkler_property_changed)
		
		sprinkler = obj
		queue_ui_sync()

var _ui_needs_sync = false
var _ignore_internal_edits = false

func _ready():
	_update_ui_from_sprinkler_db()

func _process(_delta):
	if _ui_needs_sync:
		_sync_ui()

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
	if sprinkler == null:
		_ui_needs_sync = false
		return
	
	_ignore_internal_edits = true
	user_label_lineedit.text = sprinkler.user_label
	zone_spinbox.value = sprinkler.zone
	rot_spinbox.value = sprinkler.rotation_degrees
	sweep_spinbox.value = sprinkler.sweep_deg
	_sync_option_to_text(manu_option, sprinkler.manufacturer)
	_update_model_options(sprinkler.manufacturer)
	_sync_option_to_text(model_option, sprinkler.model)
	min_dist_spinbox.value = sprinkler.min_dist_ft
	max_dist_spinbox.value = sprinkler.max_dist_ft
	dist_spinbox.min_value = min_dist_spinbox.value
	dist_spinbox.max_value = max_dist_spinbox.value
	dist_spinbox.value = sprinkler.dist_ft
	_ignore_internal_edits = false
	_ui_needs_sync = false

func _sync_option_to_text(option_button: OptionButton, text: String):
	for idx in range(option_button.item_count):
		if option_button.get_item_text(idx) == text:
			option_button.selected = idx
			return
	option_button.selected = 0

func _on_user_label_line_edit_text_submitted(new_text):
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.user_label = new_text

func _on_zone_spin_box_value_changed(value):
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.zone = value

func _on_sweep_spin_box_value_changed(sweep_deg):
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.sweep_deg = sweep_deg

func _on_rotation_spin_box_value_changed(rot_deg):
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.rotation_degrees = rot_deg

func _on_manufacturer_option_item_selected(index):
	var manufacturer = manu_option.get_item_text(index)
	_update_model_options(manufacturer)
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.manufacturer = manufacturer

func _on_model_option_item_selected(index):
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.model = model_option.get_item_text(index)

func _on_distance_spin_box_value_changed(value):
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.dist_ft = value

func _on_min_distance_spin_box_value_changed(value):
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.min_dist_ft = value

func _on_max_distance_spin_box_value_changed(value):
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.max_dist_ft = value

func _on_sprinkler_property_changed(_obj: WorldObject, _property: StringName, _from: Variant, _to: Variant) -> void:
	queue_ui_sync()
