extends Node
class_name WorldObjectSelectionController

signal item_selected(obj: WorldObject)
signal item_deselected(obj: WorldObject)
signal selection_changed()

var multi_select_key : Key = KEY_SHIFT

var _selected_objs : Array[WorldObject] = []

func on_select_button_pressed(obj_under_mouse: WorldObject):
	var emit_change = false
	if obj_under_mouse == null:
		emit_change = clear_selection()
	elif is_multi_select_key_pressed():
		if is_selected(obj_under_mouse):
			emit_change = remove_from_selection(obj_under_mouse)
		else:
			emit_change = add_to_selection(obj_under_mouse)
	elif not is_selected(obj_under_mouse):
		emit_change = clear_selection() || emit_change
		emit_change = add_to_selection(obj_under_mouse) || emit_change
	
	if emit_change:
		selection_changed.emit()

func is_selected(obj: WorldObject) -> bool:
	return obj in _selected_objs

func is_multi_select_key_pressed() -> bool:
	return Input.is_key_pressed(multi_select_key)

# @return true if selection list changed
func clear_selection() -> bool:
	if _selected_objs.is_empty():
		return false
	# make a copy of the list so we can clear the list first then report
	# that they've been removed afteward
	var list_copy := _selected_objs.duplicate()
	_selected_objs.clear()
	for obj in list_copy:
		item_deselected.emit(obj)
	return true

# @param[in] obj - the object to add to the selection list
# @return true if the object was added, false if not
func add_to_selection(obj: WorldObject) -> bool:
	if obj == null:
		return false
	elif obj in _selected_objs:
		return false
	_selected_objs.push_back(obj)
	item_selected.emit(obj)
	return true

# @param[in] obj - the object to remove from the selection list
# @return true if the object was removed, false if not
func remove_from_selection(obj: WorldObject) -> bool:
	if obj == null:
		return false
	elif obj not in _selected_objs:
		return false
	_selected_objs.erase(obj)
	item_deselected.emit(obj)
	return true

func selected_objs() -> Array[WorldObject]:
	return _selected_objs.duplicate()
