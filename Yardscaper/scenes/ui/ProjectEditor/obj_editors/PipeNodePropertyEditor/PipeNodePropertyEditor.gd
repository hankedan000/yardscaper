class_name PipeNodePropertyEditor extends BaseNodePropertyEditor

# override so we can validate the type
func add_object(wobj: WorldObject) -> void:
	if wobj is PipeNode:
		super.add_object(wobj)

func _sync_ui_from_obj() -> void:
	super._sync_ui_from_obj()
	
	#var ref_node := _wobjs[0] as PipeNode
	multi_edit_warning.text = "Editing %d pipe nodes" % _wobjs.size()
