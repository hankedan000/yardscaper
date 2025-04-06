extends Object
class_name WorldObjectReorderHelper

class ObjOrderTuple:
	var obj : WorldObject = null
	var old_order : int = -1
	var new_order : int = -1
	
	func _init(world_object: WorldObject):
		obj = world_object
		old_order = world_object.get_order_in_world()

var _obj_order_tuples : Array[ObjOrderTuple] = []

func _init(objs: Array):
	for obj in objs:
		if obj is WorldObject:
			_obj_order_tuples.push_back(ObjOrderTuple.new(obj))

func apply_relative_shift(world: WorldViewportContainer, amount: int) -> void:
	if amount == 0:
		return
	
	_obj_order_tuples.sort_custom(_sort_by_ascending_old_order)
	if amount > 0:
		# when shifting "UP", move the items with the highter order first.
		_obj_order_tuples.reverse()
	
	for pair in _obj_order_tuples:
		var try_new_order = pair.old_order + amount
		if _find_tuple_by_old_order(try_new_order) == null:
			pair.new_order = try_new_order
	
	_apply_new_order(world)

func apply_shift_to_bottom(world: WorldViewportContainer) -> void:
	_obj_order_tuples.sort_custom(_sort_by_ascending_old_order)
	for i in range(_obj_order_tuples.size()):
		_obj_order_tuples[i].new_order = i
	_apply_new_order(world)

func apply_shift_to_top(world: WorldViewportContainer) -> void:
	_obj_order_tuples.sort_custom(_sort_by_ascending_old_order)
	_obj_order_tuples.reverse()
	var top_order_idx := world.objects.get_child_count() - 1
	for i in range(_obj_order_tuples.size()):
		_obj_order_tuples[i].new_order = top_order_idx - i
	_apply_new_order(world)

func _apply_new_order(world: WorldViewportContainer):
	for tuple in _obj_order_tuples:
		if tuple.new_order != -1:
			world.reorder_world_object(tuple.old_order, tuple.new_order)
			tuple.old_order = tuple.new_order
			tuple.new_order = -1

func _sort_by_ascending_old_order(obj1: ObjOrderTuple, obj2: ObjOrderTuple):
	return obj1.old_order < obj2.old_order

func _find_tuple_by_old_order(order: int) -> ObjOrderTuple:
	for tuple in _obj_order_tuples:
		if tuple.old_order == order:
			return tuple
	return null
