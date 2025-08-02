class_name BaseNodeUndoOps extends Object

class AttachmentChanged extends UndoController.UndoOperation:
	var _collector_node_ref := UndoController.TreePathNodeRef.new()
	var _collected_node_ref := UndoController.TreePathNodeRef.new()
	var _attached : bool = false
	
	func _init(collector: MagneticArea, collected: MagneticArea, attached: bool):
		if ! is_instance_valid(collector):
			push_error("collector is invalid")
			return
		elif ! is_instance_valid(collected):
			push_error("collected is invalid")
			return
		
		_collector_node_ref = collector.get_undo_node_ref()
		_collected_node_ref = collected.get_undo_node_ref()
		_attached = attached
	
	func undo() -> bool:
		var collector := _collector_node_ref.get_node() as MagneticArea
		if ! is_instance_valid(collector):
			return false
		var collected := _collected_node_ref.get_node() as MagneticArea
		if ! is_instance_valid(collected):
			return false
		
		if _attached:
			collector.uncollect(collected)
		else:
			collector.collect(collected, true) # ignore_disable=true
		return true
		
	func redo() -> bool:
		var collector := _collector_node_ref.get_node() as MagneticArea
		if ! is_instance_valid(collector):
			return false
		var collected := _collected_node_ref.get_node() as MagneticArea
		if ! is_instance_valid(collected):
			return false
		
		if _attached:
			collector.collect(collected, true) # ignore_disable=true
		else:
			collector.uncollect(collected)
		return true
	
	func brief_name() -> String:
		if _attached:
			return "Pipe Attached"
		else:
			return "Pipe Detached"
	
	func detail_summary() -> String:
		var collector_mag_parents := Utils.get_magnet_parents(_collector_node_ref.get_node() as MagneticArea)
		var collector_user_label := "<null>"
		if is_instance_valid(collector_mag_parents.wobj):
			collector_user_label = collector_mag_parents.wobj.user_label
		
		var collected_mag_parents := Utils.get_magnet_parents(_collected_node_ref.get_node() as MagneticArea)
		var collected_user_label := "<null>"
		var side_text := "unknown"
		if is_instance_valid(collected_mag_parents.wobj):
			collected_user_label = collected_mag_parents.wobj.user_label
			side_text = "source"
			if (collected_mag_parents.wobj as Pipe).point_b_handle == collected_mag_parents.handle:
				side_text = "sink"
		
		if _attached:
			return "attached %s to %s side of %s" % [collector_user_label, side_text, collected_user_label]
		else:
			return "detached %s from %s side of %s" % [collector_user_label, side_text, collected_user_label]
