class_name PipePropertyEditor
extends PanelContainer

@onready var user_label_lineedit      : LineEdit = $VBoxContainer/PropertiesList/UserLabelLineEdit
@onready var diameter_spinbox         : SpinBox = $VBoxContainer/PropertiesList/DiameterSpinBox
@onready var material_option          : OptionButton = $VBoxContainer/PropertiesList/MaterialOption
@onready var pipe_color_picker        := $VBoxContainer/PropertiesList/PipeColorPicker
@onready var multi_edit_warning       := $VBoxContainer/MultiEditWarning

var _layout_panel : LayoutPanel = null
var _pipes : Array[Pipe] = []
var _ignore_internal_edits = false

func _ready() -> void:
	set_process(false)
	for material_key in PipeTables.MaterialType.keys():
		material_option.add_item(material_key, int(PipeTables.MaterialType[material_key]))

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
	diameter_spinbox.value = Utils.ft_to_inches(ref_pipe.diameter_ft)
	_select_material_option(ref_pipe.material_type)
	pipe_color_picker.color = ref_pipe.pipe_color
	_ignore_internal_edits = false

func _apply_prop_edit(prop_name: StringName, new_value: Variant) -> void:
	if _ignore_internal_edits:
		return
	_layout_panel.start_batch_edit(prop_name)
	for pipe in _pipes:
		pipe.set(prop_name, new_value)
	_layout_panel.stop_batch_edit()

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
	for pipe in _pipes:
		pipe.deferred_prop_change.push(Pipe.PROP_KEY_PIPE_COLOR)

func _on_pipe_color_picker_popup_closed() -> void:
	for pipe in _pipes:
		pipe.deferred_prop_change.pop(Pipe.PROP_KEY_PIPE_COLOR)

func _on_pipe_property_changed(_obj: WorldObject, _property: StringName, _from: Variant, _to: Variant) -> void:
	queue_ui_sync()
