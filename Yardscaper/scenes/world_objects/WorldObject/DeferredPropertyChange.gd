extends Object
class_name DeferredPropertyChange

var _obj : WorldObject = null
var _prop_name : StringName = &""
var _old_value : Variant = null

func _init(obj: WorldObject) -> void:
	assert(obj != null)
	_obj = obj

func reset() -> void:
	_prop_name = &""
	_old_value = null

func matches(prop_name: StringName) -> bool:
	return _prop_name == prop_name

func push(prop_name: StringName) -> void:
	if _old_value:
		push_warning("losing deferred change for property '%s' to new property '%s'" % [_prop_name, prop_name])
	_prop_name = prop_name
	_old_value = _obj.get(prop_name)

func pop(prop_name: StringName) -> void:
	if _old_value == null:
		push_warning("no deferred change value for '%s'" % prop_name)
		return
	elif _prop_name != prop_name:
		push_error("prop name mismatch! was '%s' but current is '%s'" % [_prop_name, prop_name])
		return
	
	var new_value = _obj.get(_prop_name)
	if _old_value != new_value:
		_obj.property_changed.emit(_obj, _prop_name, _old_value, new_value)
	reset()
