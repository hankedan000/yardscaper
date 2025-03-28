extends Object
class_name WorldObjectUndoRedoOps

class Remove:
	extends UndoRedoController.UndoRedoOperation
	
	var _world : WorldViewportContainer = null
	var _from_idx = 0
	var _ser_obj = null
	
	func _init(world: WorldViewportContainer, from_idx: int, obj: WorldObject):
		_world = world
		_from_idx = from_idx
		_ser_obj = obj.serialize()
	
	func undo() -> bool:
		var wobj = TheProject.instance_world_obj(_ser_obj)
		if wobj is WorldObject:
			TheProject.add_object(wobj)
			wobj.set_order_in_world(_from_idx)
			return true
		return false
		
	func redo() -> bool:
		var wobj = _world.objects.get_child(_from_idx)
		TheProject.remove_object(wobj)
		return true
		
	func pretty_str() -> String:
		return str({
			'_from_idx' : _from_idx,
			'_ser_obj': _ser_obj
		})

class Moved:
	extends UndoRedoController.UndoRedoOperation
	
	var _world : WorldViewportContainer = null
	var _from_idx = 0
	var _to_idx = 0
	
	func _init(world: WorldViewportContainer, from_idx: int, to_idx: int):
		_world = world
		_from_idx = from_idx
		_to_idx = to_idx
	
	func undo() -> bool:
		return _world.move_world_object(_to_idx, _from_idx)
		
	func redo() -> bool:
		return _world.move_world_object(_from_idx, _to_idx)
		
	func pretty_str() -> String:
		return str({
			'_from_idx' : _from_idx,
			'_to_idx': _to_idx
		})
