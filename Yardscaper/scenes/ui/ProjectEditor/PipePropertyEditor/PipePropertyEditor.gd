class_name PipePropertyEditor
extends PanelContainer

@onready var user_label_lineedit      : LineEdit = $VBoxContainer/PropertiesList/UserLabelLineEdit
@onready var flow_src_checkbox        : CheckBox = $VBoxContainer/PropertiesList/FlowSourceCheckBox
@onready var src_pressure_label       : Label = $VBoxContainer/PropertiesList/SrcPressureLabel
@onready var src_pressure_spinbox     : SpinBox = $VBoxContainer/PropertiesList/SrcPressureSpinBox
@onready var src_flow_rate_label      : Label = $VBoxContainer/PropertiesList/SrcFlowRateLabel
@onready var src_flow_rate_spinbox    : SpinBox = $VBoxContainer/PropertiesList/SrcFlowRateSpinBox
@onready var diameter_spinbox         : SpinBox = $VBoxContainer/PropertiesList/DiameterSpinBox
@onready var pipe_color_picker        := $VBoxContainer/PropertiesList/PipeColorPicker
@onready var multi_edit_warning       := $VBoxContainer/MultiEditWarning

var _layout_panel : LayoutPanel = null
var _pipes : Array[Pipe] = []
var _ignore_internal_edits = false

func _ready() -> void:
	set_process(false)

func _process(_delta) -> void:
	_sync_ui()
	set_process(false)

func set_layout_panel(layout_panel: LayoutPanel) -> void:
	_layout_panel = layout_panel

func add_pipe(pipe: Pipe) -> void:
	if pipe == null:
		return
	elif pipe in _pipes:
		return
	
	pipe.property_changed.connect(_on_pipe_property_changed)
	_pipes.push_back(pipe)
	queue_ui_sync()

func remove_pipe(pipe: Pipe) -> void:
	var idx := _pipes.find(pipe)
	if idx < 0:
		return
	
	pipe.property_changed.disconnect(_on_pipe_property_changed)
	_pipes.remove_at(idx)
	queue_ui_sync()

func clear_pipes() -> void:
	for pipe in _pipes.duplicate():
		remove_pipe(pipe)

func queue_ui_sync():
	set_process(true)

# synchronize UI elements to existing properties of the sprinkler
func _sync_ui():
	if _pipes.is_empty():
		return
	
	var ref_pipe := _pipes[0]
	var single_edit := _pipes.size() == 1
	user_label_lineedit.editable = single_edit
	multi_edit_warning.visible = ! single_edit
	multi_edit_warning.text = "Editing %d pipes" % _pipes.size()
	
	_ignore_internal_edits = true
	user_label_lineedit.text = ref_pipe.user_label if single_edit else "---"
	flow_src_checkbox.button_pressed = ref_pipe.is_flow_source
	src_pressure_spinbox.value = ref_pipe.src_pressure_psi
	src_flow_rate_spinbox.value = ref_pipe.src_flow_rate_gpm
	diameter_spinbox.value = ref_pipe.diameter_inches
	pipe_color_picker.color = ref_pipe.pipe_color
	_ignore_internal_edits = false

func _apply_prop_edit(prop_name: StringName, new_value: Variant) -> void:
	if _ignore_internal_edits:
		return
	_layout_panel.start_batch_edit(prop_name)
	for pipe in _pipes:
		pipe.set(prop_name, new_value)
	_layout_panel.stop_batch_edit()

func _on_user_label_line_edit_text_submitted(new_text):
	_apply_prop_edit(WorldObject.PROP_KEY_USER_LABEL, new_text)

func _on_flow_source_check_box_toggled(toggled_on: bool) -> void:
	src_pressure_label.visible = toggled_on
	src_pressure_spinbox.visible = toggled_on
	src_flow_rate_label.visible = toggled_on
	src_flow_rate_spinbox.visible = toggled_on
	_apply_prop_edit(Pipe.PROP_KEY_IS_FLOW_SRC, toggled_on)

func _on_src_pressure_spin_box_value_changed(value: float) -> void:
	_apply_prop_edit(Pipe.PROP_KEY_SRC_PRESSURE_PSI, value)

func _on_src_flow_rate_spin_box_value_changed(value: float) -> void:
	_apply_prop_edit(Pipe.PROP_KEY_SRC_FLOW_RATE_GPM, value)

func _on_diameter_spin_box_value_changed(value: float) -> void:
	_apply_prop_edit(Pipe.PROP_KEY_DIAMETER_INCHES, value)

func _on_pipe_color_picker_color_changed(color: Color) -> void:
	_apply_prop_edit(Pipe.PROP_KEY_PIPE_COLOR, color)

func _on_pipe_color_picker_pressed() -> void:
	for pipe in _pipes:
		pipe.deferred_prop_change.push(Pipe.PROP_KEY_PIPE_COLOR)

func _on_pipe_color_picker_popup_closed() -> void:
	for pipe in _pipes:
		pipe.deferred_prop_change.pop(Pipe.PROP_KEY_PIPE_COLOR)

func _on_pipe_property_changed(_obj: WorldObject, _property: StringName, _from: Variant, _to: Variant) -> void:
	queue_ui_sync()
