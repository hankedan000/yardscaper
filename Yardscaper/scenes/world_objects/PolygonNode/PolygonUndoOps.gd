class_name PolygonUndoOps extends Object

class PointMove extends UndoController.UndoOperation:
	var _node_ref := UndoController.TreePathNodeRef.new()
	var _idx : int = 0
	var _from := Vector2()
	var _to := Vector2()
	
	func _init(poly: PolygonNode, idx: int, from: Vector2, to: Vector2):
		_node_ref = UndoController.TreePathNodeRef.new(poly)
		_idx = idx
		_from = from
		_to = to
	
	func undo() -> bool:
		return _set_point(_idx, _from)
		
	func redo() -> bool:
		return _set_point(_idx, _to)
	
	func _set_point(idx: int, new_pos: Vector2) -> bool:
		var poly := _node_ref.get_node() as PolygonNode
		if ! is_instance_valid(poly):
			return false
		poly.set_point(idx, new_pos)
		return true
	
	func brief_name() -> String:
		return "Polygon Point Move"
	
	func detail_summary() -> String:
		return "moved '%s' point #%d from position %s to %s" % [_node_ref.get_node_name(), _idx, _from, _to]

class PointAdd extends UndoController.UndoOperation:
	var _node_ref := UndoController.TreePathNodeRef.new()
	var _idx : int = 0
	var _point := Vector2()
	
	func _init(poly: PolygonNode, idx: int, point: Vector2):
		_node_ref = UndoController.TreePathNodeRef.new(poly)
		_idx = idx
		_point = point
	
	func undo() -> bool:
		return _apply(true) # is_remove=true
		
	func redo() -> bool:
		return _apply(false) # is_remove=false
	
	func _apply(is_remove) -> bool:
		var poly := _node_ref.get_node() as PolygonNode
		if ! is_instance_valid(poly):
			return false
		if is_remove:
			poly.remove_point(_idx)
		else:
			poly.insert_point(_idx, _point)
		return true
	
	func brief_name() -> String:
		return "Added Polygon Point"
	
	func detail_summary() -> String:
		return "added point #%d to Polygon '%s' at position %s" % [_idx, _node_ref.get_node_name(), _point]

class PointRemove extends UndoController.UndoOperation:
	var _node_ref := UndoController.TreePathNodeRef.new()
	var _idx : int = 0
	var _point := Vector2()
	
	func _init(poly: PolygonNode, idx: int, point: Vector2):
		_node_ref = UndoController.TreePathNodeRef.new(poly)
		_idx = idx
		_point = point
	
	func undo() -> bool:
		return _apply(false) # is_remove=false
		
	func redo() -> bool:
		return _apply(true) # is_remove=true
	
	func _apply(is_remove) -> bool:
		var poly := _node_ref.get_node() as PolygonNode
		if ! is_instance_valid(poly):
			return false
		if is_remove:
			poly.remove_point(_idx)
		else:
			poly.insert_point(_idx, _point)
		return true
	
	func brief_name() -> String:
		return "Removed Polygon Point"
	
	func detail_summary() -> String:
		return "removed point #%d from Polygon '%s'" % [_idx, _node_ref.get_node_name()]
