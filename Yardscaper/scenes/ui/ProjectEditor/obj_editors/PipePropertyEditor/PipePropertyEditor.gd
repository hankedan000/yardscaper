class_name PipePropertyEditor extends WorldObjectPropertyEditor

@onready var diameter_spinbox         : SpinBox = $VBoxContainer/PropertiesList/DiameterSpinBox
@onready var material_option          : OptionButton = $VBoxContainer/PropertiesList/MaterialOption
@onready var pipe_color_picker        : ColorPickerButton = $VBoxContainer/PropertiesList/PipeColorPicker

var _layout_panel : LayoutPanel = null

func _ready() -> void:
	super._ready()
	for material_key in PipeTables.MaterialType.keys():
		material_option.add_item(material_key, int(PipeTables.MaterialType[material_key]))

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
	_select_material_option(ref_pipe.material_type)
	pipe_color_picker.color = ref_pipe.pipe_color

func _select_material_option(material_type: PipeTables.MaterialType) -> void:
	for idx in range(material_option.item_count):
		if material_option.get_item_id(idx) == int(material_type):
			material_option.select(idx)

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
