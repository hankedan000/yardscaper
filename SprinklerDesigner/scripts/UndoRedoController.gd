extends Object
class_name UndoRedoController

signal history_changed()
# called right before an undo/redo operation is performed
# @param is_undo - true if an undo, false if a redo
signal before_a_do(is_undo)
# called right after an undo/redo operation is performed
# @param is_undo - true if an undo, false if a redo
signal after_a_do(is_undo)

class UndoRedoOperation:
	extends Object
	
	func undo() -> bool:
		return true
		
	func redo() -> bool:
		return true
		
	func pretty_str() -> String:
		return "**pretty_str() unimplemented***"

class PropEditUndoRedoOperation:
	extends UndoRedoOperation
	
	var _obj : Object = null
	var _prop : StringName = ""
	var _old_value = null
	var _new_value = null
	
	func _init(obj: Object, prop: StringName, old_value, new_value):
		if obj == null:
			push_error("obj can't be null")
		if prop not in obj:
			push_error("obj %s doesn't have a property named '%s'" % [obj, prop])
		_obj = obj
		_prop = prop
		_old_value = old_value
		_new_value = new_value
	
	func undo() -> bool:
		_obj.set(_prop, _old_value)
		return true
		
	func redo() -> bool:
		_obj.set(_prop, _new_value)
		return true
		
	func pretty_str() -> String:
		return str({
			"obj" : str(_obj),
			"property" : _prop,
			"old_value" : str(_old_value),
			"new_value" : str(_new_value),
			})

const MAX_UNDO_REDO_HISTORY = 100
var _undo_stack = []
var _redo_stack = []

func reset():
	_undo_stack = []
	_redo_stack = []
	emit_signal('history_changed')

func has_undo() -> bool:
	return len(_undo_stack) > 0

func has_redo() -> bool:
	return len(_redo_stack) > 0

func push_undo_op(op: UndoRedoOperation):
	_push_op(_undo_stack, op)
	_redo_stack.clear()
	emit_signal('history_changed')

func undo():
	if has_undo():
		var op = _undo_stack.pop_back()
		emit_signal('before_a_do', true) # is_undo = true
		op.undo()
		_push_op(_redo_stack, op)
		emit_signal('after_a_do', true) # is_undo = true
		emit_signal('history_changed')

func redo():
	if has_redo():
		var op = _redo_stack.pop_back()
		emit_signal('before_a_do', false) # is_undo = false
		op.redo()
		_push_op(_undo_stack, op)
		emit_signal('after_a_do', false) # is_undo = false
		emit_signal('history_changed')

func _push_op(stack: Array, entry):
	stack.push_back(entry)
	if len(stack) > MAX_UNDO_REDO_HISTORY:
		stack.pop_front()
