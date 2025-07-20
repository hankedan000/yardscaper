class_name WorldObjectPropertyEditor extends PanelContainer

@onready var user_label_lineedit      : LineEdit = $VBoxContainer/PropertiesList/UserLabelLineEdit
@onready var multi_edit_warning       : BlinkLabel = $VBoxContainer/MultiEditWarning

var _wobjs : Array[WorldObject] = []
var _ignore_internal_edits = false

func _ready():
	set_process(false)

func _process(_delta: float) -> void:
	if _wobjs.size() > 0:
		_ignore_internal_edits = true
		_sync_ui_from_obj()
		_ignore_internal_edits = false
	set_process(false) # only sync once

func add_object(wobj: WorldObject) -> void:
	if ! is_instance_valid(wobj):
		return
	elif wobj in _wobjs:
		return
	
	wobj.property_changed.connect(_on_world_object_property_changed)
	_wobjs.push_back(wobj)
	queue_ui_sync()

func remove_object(wobj: WorldObject) -> void:
	var idx := _wobjs.find(wobj)
	if idx < 0:
		return
	
	wobj.property_changed.disconnect(_on_world_object_property_changed)
	_wobjs.remove_at(idx)
	queue_ui_sync()

func clear_objects() -> void:
	for wobj in _wobjs.duplicate():
		remove_object(wobj)

func queue_ui_sync():
	set_process(true)

func _sync_ui_from_obj() -> void:
	var ref_node := _wobjs[0] as WorldObject
	var single_edit := _wobjs.size() == 1
	user_label_lineedit.editable = single_edit
	multi_edit_warning.visible = ! single_edit
	multi_edit_warning.text = "Editing multiple objects"
	
	user_label_lineedit.text = ref_node.user_label if single_edit else "---"

static func _sync_fvar_to_spinbox(fvar: Var, spinbox: OverrideSpinbox, conv_func:=Callable()) -> void:
	spinbox.set_overriden(fvar.state == Var.State.Known)
	var conv_value := fvar.value
	if conv_func.is_valid():
		conv_value = conv_func.call(fvar.value)
	spinbox.set_control_value(conv_value)

func _override_to_var_state(override: bool) -> Var.State:
	return Var.State.Known if override else Var.State.Unknown

func _apply_prop_edit(prop_name: StringName, new_value: Variant) -> void:
	if _ignore_internal_edits:
		return
	for wobj in _wobjs:
		wobj.set(prop_name, new_value)

func _apply_fluid_prop_edit(prop_name: StringName, new_value: Variant) -> void:
	if _ignore_internal_edits:
		return
	for wobj in _wobjs:
		wobj.set_fluid_property(prop_name, new_value)

func _setup_short_length_spinbox(spinbox: SpinBox) -> void:
	_setup_spinbox(
		spinbox,
		Globals.SHORT_LENGTH_MIN_IN,
		Globals.SHORT_LENGTH_MAX_IN,
		Globals.SHORT_LENGTH_STEP_IN,
		Utils.DISP_UNIT_IN)

func _setup_long_length_spinbox(spinbox: SpinBox) -> void:
	_setup_spinbox(
		spinbox,
		Globals.LONG_LENGTH_MIN_IN,
		Globals.LONG_LENGTH_MAX_IN,
		Globals.LONG_LENGTH_STEP_IN,
		Utils.DISP_UNIT_FT)

func _setup_pressure_spinbox(spinbox: SpinBox) -> void:
	_setup_spinbox(
		spinbox,
		Globals.PRESSURE_MIN_PSI,
		Globals.PRESSURE_MAX_PSI,
		Globals.PRESSURE_STEP_PSI,
		Utils.DISP_UNIT_PSI)

func _setup_flow_rate_spinbox(spinbox: SpinBox) -> void:
	_setup_spinbox(
		spinbox,
		Globals.FLOW_MIN_GPM,
		Globals.FLOW_MAX_GPM,
		Globals.FLOW_STEP_GPM,
		Utils.DISP_UNIT_GPM)

func _setup_spinbox(
		spinbox: SpinBox,
		min_value: float,
		max_value: float,
		step: float,
		suffix: String) -> void:
	spinbox.min_value = min_value
	spinbox.max_value = max_value
	spinbox.step = step
	spinbox.suffix = suffix

func _on_user_label_line_edit_text_submitted(new_text: String) -> void:
	_apply_prop_edit(WorldObject.PROP_KEY_USER_LABEL, new_text)

func _on_world_object_property_changed(_obj: WorldObject, _property: StringName, _from: Variant, _to: Variant) -> void:
	queue_ui_sync()
