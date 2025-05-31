extends Object
class_name WorldObjectUndoRedoOps

class AddOrRemove:
	extends UndoController.UndoOperation
	
	var _world : WorldViewportContainer = null
	var _from_idx : int = -1
	var _ser_obj : Dictionary = {}
	var _is_remove : bool = true
	
	func _init(world: WorldViewportContainer, obj: WorldObject, is_remove: bool):
		_world = world
		_from_idx = obj.get_order_in_world()
		_ser_obj = obj.serialize()
		_is_remove = is_remove
	
	func undo() -> bool:
		if _is_remove:
			return _do_add_logic()
		else:
			return _do_remove_logic()
		
	func redo() -> bool:
		if _is_remove:
			return _do_remove_logic()
		else:
			return _do_add_logic()
		
	func pretty_str() -> String:
		return str({
			'_from_idx' : _from_idx,
			'_ser_obj': _ser_obj,
			'_is_remove': _is_remove
		})
	
	func _do_add_logic() -> bool:
		var wobj := TheProject.instance_world_obj(_ser_obj)
		if wobj and TheProject.add_object(wobj):
			wobj.set_order_in_world(_from_idx)
			return true
		return false
	
	func _do_remove_logic() -> bool:
		var wobj := _world.objects.get_child(_from_idx) as WorldObject
		return TheProject.remove_object(wobj)

class Reordered:
	extends UndoController.UndoOperation
	
	var _world : WorldViewportContainer = null
	var _from_idx = 0
	var _to_idx = 0
	
	func _init(world: WorldViewportContainer, from_idx: int, to_idx: int):
		_world = world
		_from_idx = from_idx
		_to_idx = to_idx
	
	func undo() -> bool:
		return _world.reorder_world_object(_to_idx, _from_idx)
		
	func redo() -> bool:
		return _world.reorder_world_object(_from_idx, _to_idx)
		
	func pretty_str() -> String:
		return str({
			'_from_idx' : _from_idx,
			'_to_idx': _to_idx
		})
