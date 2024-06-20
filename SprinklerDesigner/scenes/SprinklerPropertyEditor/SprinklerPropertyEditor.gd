extends GridContainer

@onready var user_label_lineedit      := $UserLabelLineEdit
@onready var rot_spinbox              := $RotationSpinBox
@onready var sweep_spinbox            := $SweepSpinBox
@onready var manufacturer_lineedit    := $ManufacturerLineEdit
@onready var model_lineedit           := $ModelLineEdit
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

func _process(_delta):
	if _ui_needs_sync:
		_sync_ui()

func queue_ui_sync():
	_ui_needs_sync = true

func _sync_ui():
	_ui_needs_sync = false
	if sprinkler == null:
		return
	
	_ignore_internal_edits = true
	user_label_lineedit.text = sprinkler.user_label
	rot_spinbox.value = sprinkler.rotation_degrees
	sweep_spinbox.value = sprinkler.sweep_deg
	manufacturer_lineedit.text = sprinkler.manufacturer
	model_lineedit.text = sprinkler.model
	min_dist_spinbox.value = sprinkler.min_dist_ft
	max_dist_spinbox.value = sprinkler.max_dist_ft
	dist_spinbox.min_value = min_dist_spinbox.value
	dist_spinbox.max_value = max_dist_spinbox.value
	dist_spinbox.value = sprinkler.dist_ft
	_ignore_internal_edits = false

func _on_user_label_line_edit_text_submitted(new_text):
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.user_label = new_text

func _on_sweep_spin_box_value_changed(sweep_deg):
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.sweep_deg = sweep_deg

func _on_rotation_spin_box_value_changed(rot_deg):
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.rotation_degrees = rot_deg

func _on_manufacturer_line_edit_text_submitted(new_text):
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.manufacturer = new_text

func _on_model_line_edit_text_submitted(new_text):
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.model = new_text

func _on_distance_spin_box_value_changed(value):
	if sprinkler is Sprinkler and not _ignore_internal_edits:
		sprinkler.dist_ft = value

func _on_sprinkler_property_changed(_property, _from, _to):
	queue_ui_sync()
