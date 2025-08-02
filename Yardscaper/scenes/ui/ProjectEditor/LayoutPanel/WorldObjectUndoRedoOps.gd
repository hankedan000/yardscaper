class_name WorldObjectUndoRedoOps extends Object

class AddOrRemove extends UndoController.UndoOperation:
	
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
	
	func brief_name() -> String:
		if _is_remove:
			return "Removed Node"
		else:
			return "Added Node"
	
	func detail_summary() -> String:
		if _is_remove:
			return "Removed %s (%s)" % [_ser_obj[WorldObject.PROP_KEY_SUBCLASS], _ser_obj[WorldObject.PROP_KEY_USER_LABEL]]
		else:
			return "Added %s (%s)" % [_ser_obj[WorldObject.PROP_KEY_SUBCLASS], _ser_obj[WorldObject.PROP_KEY_USER_LABEL]]
	
	func _do_add_logic() -> bool:
		var wobj := TheProject.instance_world_obj_from_data(_ser_obj)
		if ! is_instance_valid(wobj):
			return false
		
		wobj.set_order_in_world(_from_idx)
		if wobj is BaseNode:
			wobj.restore_pipe_connections()
		return true
	
	func _do_remove_logic() -> bool:
		var wobj := _world.objects.get_child(_from_idx) as WorldObject
		if is_instance_valid(wobj):
			wobj.queue_free()
			return true
		return false

class Reordered extends UndoController.UndoOperation:
	
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
	
	func brief_name() -> String:
		return "Reordered Node"
	
	func detail_summary() -> String:
		return "Reordered %s from position %d to %d" % [
			(_world.objects.get_child(_from_idx) as WorldObject).user_label,
			_from_idx,
			_to_idx]

class GlobalPositionChange extends UndoController.UndoOperation:
	
	var _node_ref := UndoController.TreePathNodeRef.new()
	var _old_pos : Vector2 = Vector2()
	var _new_pos : Vector2 = Vector2()
	
	func _init(obj: WorldObject, old_pos: Vector2, new_value: Vector2):
		_node_ref = UndoController.TreePathNodeRef.new(obj)
		_old_pos = old_pos
		_new_pos = new_value
	
	func undo() -> bool:
		return _apply_position(_old_pos)
		
	func redo() -> bool:
		return _apply_position(_new_pos)
	
	func _apply_position(new_pos: Vector2) -> bool:
		var wobj := _node_ref.get_node() as WorldObject
		if ! is_instance_valid(wobj):
			return false
		wobj.apply_global_position(new_pos)
		return true
	
	func brief_name() -> String:
		return "Moved Node"
	
	func detail_summary() -> String:
		return "Moved %s from position %s to %s" % [_node_ref.get_node_name(), _old_pos, _new_pos]
