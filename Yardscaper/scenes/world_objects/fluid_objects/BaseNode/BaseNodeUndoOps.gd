class_name BaseNodeUndoOps extends Object

class AttachementChanged extends UndoController.UndoOperation:
	var _collector : MagneticArea = null
	var _collected : MagneticArea = null
	var _attached : bool = false
	
	func _init(collector: MagneticArea, collected: MagneticArea, attached: bool):
		_collector = collector
		_collected = collected
		_attached = attached
	
	func undo() -> bool:
		print("undoing attachment ...")
		if _attached:
			_collector.uncollect(_collected)
		else:
			_collector.collect(_collected, true) # ignore_disable=true
		return true
		
	func redo() -> bool:
		if _attached:
			_collector.collect(_collected, true) # ignore_disable=true
		else:
			_collector.uncollect(_collected)
		return true
	
	func pretty_str() -> String:
		return str({
			'_collector' : str(_collector),
			'_collected' : str(_collected),
			'_attached' : _attached
		})
