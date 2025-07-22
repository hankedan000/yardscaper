class_name ImageNodePropertyEditor extends WorldObjectPropertyEditor

@onready var width_spinbox  := $VBoxContainer/PropertiesList/WidthSpinBox
@onready var height_spinbox := $VBoxContainer/PropertiesList/HeightSpinBox

func _ready() -> void:
	super._ready()
	_setup_long_length_spinbox(width_spinbox)
	_setup_long_length_spinbox(height_spinbox)

# override so we can validate the type
func add_object(wobj: WorldObject) -> void:
	if wobj is ImageNode:
		super.add_object(wobj)

func _sync_ui_from_obj() -> void:
	super._sync_ui_from_obj()
	
	var ref_img := _wobjs[0] as ImageNode
	multi_edit_warning.text = "Editing %d images" % _wobjs.size()
	
	width_spinbox.value = ref_img.width_ft
	height_spinbox.value = ref_img.height_ft

func _on_width_spin_box_value_changed(value):
	_apply_prop_edit(ImageNode.PROP_KEY_WIDTH_FT, value)

func _on_height_spin_box_value_changed(value):
	_apply_prop_edit(ImageNode.PROP_KEY_HEIGHT_FT, value)
