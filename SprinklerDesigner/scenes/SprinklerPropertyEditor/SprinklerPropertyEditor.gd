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
		
		# disconnect signal handler from old sprinkler
		if sprinkler != null:
			sprinkler.property_changed.disconnect(_on_sprinkler_property_changed)
		
		if obj is Sprinkler:
			obj.property_changed.connect(_on_sprinkler_property_changed)
			_sync_ui_to_properties(obj)
		
		sprinkler = obj

func _sync_ui_to_properties(sprink: Sprinkler):
	user_label_lineedit.text = sprink.user_label
	rot_spinbox.value = sprink.rotation_degrees
	sweep_spinbox.value = sprink.sweep_deg
	manufacturer_lineedit.text = sprink.manufacturer
	model_lineedit.text = sprink.model
	min_dist_spinbox.value = sprink.min_dist_ft
	max_dist_spinbox.value = sprink.max_dist_ft
	dist_spinbox.min_value = min_dist_spinbox.value
	dist_spinbox.max_value = max_dist_spinbox.value
	dist_spinbox.value = sprink.dist_ft

func _on_user_label_line_edit_text_submitted(new_text):
	if sprinkler is Sprinkler:
		sprinkler.user_label = new_text

func _on_sweep_spin_box_value_changed(sweep_deg):
	if sprinkler is Sprinkler:
		sprinkler.sweep_deg = sweep_deg

func _on_rotation_spin_box_value_changed(rot_deg):
	if sprinkler is Sprinkler:
		sprinkler.rotation_degrees = rot_deg

func _on_manufacturer_line_edit_text_submitted(new_text):
	if sprinkler is Sprinkler:
		sprinkler.manufacturer = new_text

func _on_model_line_edit_text_submitted(new_text):
	if sprinkler is Sprinkler:
		sprinkler.model = new_text

func _on_distance_spin_box_value_changed(value):
	if sprinkler is Sprinkler:
		sprinkler.dist_ft = value

func _on_sprinkler_property_changed(_property, _from, _to):
	if sprinkler:
		_sync_ui_to_properties(sprinkler)
