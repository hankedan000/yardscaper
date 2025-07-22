class_name PolygonUndoOps extends Object

class PointMove extends UndoController.UndoOperation:
	
	var _poly : PolygonNode = null
	var _idx : int = 0
	var _from := Vector2()
	var _to := Vector2()
	
	func _init(poly: PolygonNode, idx: int, from: Vector2, to: Vector2):
		_poly = poly
		_idx = idx
		_from = from
		_to = to
	
	func undo() -> bool:
		_poly.set_point(_idx, _from)
		return true
		
	func redo() -> bool:
		_poly.set_point(_idx, _to)
		return true
		
	func pretty_str() -> String:
		return str({
			'_poly.user_label' : _poly.user_label,
			'_idx' : _idx,
			'_from' : _from,
			'_to' : _to
		})

class PointAdd extends UndoController.UndoOperation:
	
	var _poly : PolygonNode = null
	var _idx : int = 0
	var _point := Vector2()
	
	func _init(poly: PolygonNode, idx: int, point: Vector2):
		_poly = poly
		_idx = idx
		_point = point
	
	func undo() -> bool:
		_poly.remove_point(_idx)
		return true
		
	func redo() -> bool:
		_poly.insert_point(_idx, _point)
		return true
		
	func pretty_str() -> String:
		return str({
			'_poly.user_label' : _poly.user_label,
			'_idx' : _idx,
			'_point' : _point
		})

class PointRemove extends UndoController.UndoOperation:
	
	var _poly : PolygonNode = null
	var _idx : int = 0
	var _point := Vector2()
	
	func _init(poly: PolygonNode, idx: int, point: Vector2):
		_poly = poly
		_idx = idx
		_point = point
	
	func undo() -> bool:
		_poly.insert_point(_idx, _point)
		return true
		
	func redo() -> bool:
		_poly.remove_point(_idx)
		return true
		
	func pretty_str() -> String:
		return str({
			'_poly.user_label' : _poly.user_label,
			'_idx' : _idx,
			'_point' : _point
		})
