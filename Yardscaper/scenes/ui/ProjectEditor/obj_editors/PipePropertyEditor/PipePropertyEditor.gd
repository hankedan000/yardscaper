class_name PipePropertyEditor extends WorldObjectPropertyEditor

@onready var diameter_spinbox         : SpinBox = $VBoxContainer/PropertiesList/DiameterSpinBox
@onready var material_option          : OptionButton = $VBoxContainer/PropertiesList/MaterialOption
@onready var pipe_color_picker        : ColorPickerButton = $VBoxContainer/PropertiesList/PipeColorPicker
@onready var flow_rate_label          : Label = $VBoxContainer/PropertiesList/FlowRateLabel
@onready var flow_rate_spinbox        : OverrideSpinbox = $VBoxContainer/PropertiesList/FlowRateSpinBox
@onready var entry_fitting_option     : PipeFittingOption = $VBoxContainer/PropertiesList/EntryFittingOption
@onready var exit_fitting_option      : PipeFittingOption = $VBoxContainer/PropertiesList/ExitFittingOption

var _layout_panel : LayoutPanel = null

func _ready() -> void:
	super._ready()
	for material_key in PipeTables.MaterialType.keys():
		material_option.add_item(material_key, int(PipeTables.MaterialType[material_key]))
	_setup_short_length_spinbox(diameter_spinbox)
	_setup_flow_rate_spinbox(flow_rate_spinbox.control as SpinBox)
	_setup_minor_loss_spinbox(entry_fitting_option.spinbox)
	_setup_minor_loss_spinbox(exit_fitting_option.spinbox)

func set_layout_panel(layout_panel: LayoutPanel) -> void:
	_layout_panel = layout_panel

# override so we can validate the type
func add_object(wobj: WorldObject) -> void:
	if wobj is Pipe:
		super.add_object(wobj)

func _sync_ui_from_obj() -> void:
	super._sync_ui_from_obj()
	
	var ref_pipe := _wobjs[0] as Pipe
	multi_edit_warning.text = "Editing %d pipes" % _wobjs.size()
	
	diameter_spinbox.value = Utils.ft_to_inches(ref_pipe.diameter_ft)
	_sync_material_option(ref_pipe.material_type)
	pipe_color_picker.color = ref_pipe.pipe_color
	_sync_fvar_to_spinbox(ref_pipe.fpipe.q_cfs, flow_rate_spinbox, Utils.cftps_to_gpm)
	entry_fitting_option.select_option_by_id(ref_pipe.entry_fitting_type)
	entry_fitting_option.spinbox.value = ref_pipe.fpipe.K_entry
	exit_fitting_option.select_option_by_id(ref_pipe.exit_fitting_type)
	exit_fitting_option.spinbox.value = ref_pipe.fpipe.K_exit

func _sync_material_option(material_type: PipeTables.MaterialType) -> void:
	for idx in range(material_option.item_count):
		if material_option.get_item_id(idx) == int(material_type):
			material_option.select(idx)

# override from WorldObjectPropertyEditor
func _show_advanced_properties_toggled(toggled_on: bool) -> void:
	super._show_advanced_properties_toggled(toggled_on)
	flow_rate_label.visible = toggled_on
	flow_rate_spinbox.visible = toggled_on

func _on_user_label_line_edit_text_submitted(new_text):
	_apply_prop_edit(WorldObject.PROP_KEY_USER_LABEL, new_text)

func _on_diameter_spin_box_value_changed(value: float) -> void:
	_apply_prop_edit(Pipe.PROP_KEY_DIAMETER_FT, Utils.inches_to_ft(value))

func _on_material_option_item_selected(index: int) -> void:
	var key = material_option.get_item_text(index)
	_apply_prop_edit(Pipe.PROP_KEY_MATERIAL_TYPE, PipeTables.MaterialType[key])

func _on_pipe_color_picker_color_changed(color: Color) -> void:
	_apply_prop_edit(Pipe.PROP_KEY_PIPE_COLOR, color)

func _on_pipe_color_picker_pressed() -> void:
	for pipe: Pipe in _wobjs:
		pipe.deferred_prop_change.push(Pipe.PROP_KEY_PIPE_COLOR)

func _on_pipe_color_picker_popup_closed() -> void:
	for pipe: Pipe in _wobjs:
		pipe.deferred_prop_change.pop(Pipe.PROP_KEY_PIPE_COLOR)

func _on_flow_rate_spin_box_override_changed(new_overriden: bool) -> void:
	_apply_fluid_prop_edit(Pipe.PROP_KEY_FPIPE_Q_CFS, _override_to_var_state(new_overriden))

func _on_flow_rate_spin_box_value_changed(new_value: Variant) -> void:
	_apply_fluid_prop_edit(Pipe.PROP_KEY_FPIPE_Q_CFS, new_value as float)

func _on_entry_fitting_option_option_changed(_option_text: String, option_id: int) -> void:
	var fitting_type := option_id as PipeTables.FittingType
	_apply_prop_edit(Pipe.PROP_KEY_ENTRY_FITTING_TYPE, fitting_type)

func _on_entry_fitting_option_custom_value_changed(new_value: float) -> void:
	_apply_prop_edit(Pipe.PROP_KEY_ENTRY_CUSTOM_K, new_value)

func _on_exit_fitting_option_option_changed(_option_text: String, option_id: int) -> void:
	var fitting_type := option_id as PipeTables.FittingType
	_apply_prop_edit(Pipe.PROP_KEY_EXIT_FITTING_TYPE, fitting_type)

func _on_exit_fitting_option_custom_value_changed(new_value: float) -> void:
	_apply_prop_edit(Pipe.PROP_KEY_EXIT_CUSTOM_K, new_value)
