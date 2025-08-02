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
	
	func pretty_str() -> String:
		return str({
			'_collector_node_ref' : _collector_node_ref,
			'_collected_node_ref' : _collected_node_ref,
			'_attached' : _attached
		})
