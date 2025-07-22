class_name PolygonNodePropertyEditor extends WorldObjectPropertyEditor

@onready var color_picker := $VBoxContainer/PropertiesList/ColorPicker

# override so we can validate the type
func add_object(wobj: WorldObject) -> void:
	if wobj is PolygonNode:
		super.add_object(wobj)

func _sync_ui_from_obj() -> void:
	super._sync_ui_from_obj()
	
	var ref_poly := _wobjs[0] as PolygonNode
	multi_edit_warning.text = "Editing %d polygons" % _wobjs.size()
	
	color_picker.color = ref_poly.color

func _on_color_picker_color_changed(color: Color) -> void:
	_apply_prop_edit(PolygonNode.PROP_KEY_COLOR, color)

func _on_color_picker_pressed() -> void:
	for poly: PolygonNode in _wobjs:
		poly.deferred_prop_change.push(PolygonNode.PROP_KEY_COLOR)

func _on_color_picker_popup_closed() -> void:
	for poly: PolygonNode in _wobjs:
		poly.deferred_prop_change.pop(PolygonNode.PROP_KEY_COLOR)
