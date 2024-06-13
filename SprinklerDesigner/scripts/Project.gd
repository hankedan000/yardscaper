extends Node

signal opened()
signal sprinkler_changed(sprink, change_type)
signal has_edits_changed(has_edits)

enum ChangeType {
	ADD,
	REMOVE,
	MODIFIED
}

var project_path = ""
var sprinklers = []
var has_edits = false :
	set(value):
		var old_value = has_edits
		has_edits = value
		if old_value != has_edits and not _suppress_self_edit_signals:
			emit_signal('has_edits_changed', has_edits)

var _suppress_self_edit_signals = false

func reset():
	_suppress_self_edit_signals = true
	while not sprinklers.is_empty():
		remove_sprinkler(sprinklers.front())
	_suppress_self_edit_signals = false
	has_edits = false

func open(dir: String):
	var json_filepath = dir.path_join("project.json")
	var json_file = FileAccess.open(json_filepath, FileAccess.READ)
	var proj_str = json_file.get_as_text()
	var json = JSON.new()
	if json.parse(proj_str) == OK:
		deserialize(json.data)
		project_path = dir
		has_edits = false
		emit_signal('opened')
	else:
		printerr("failed to open to '%s'" % [json_filepath])
		return false
	return true

func save():
	return save_as(project_path)

func save_as(dir: String):
	var proj_str = JSON.stringify(
		serialize(),
		" ",  # indent
		true, # sort_keys
		true) # full_precision
	var json_filepath = dir.path_join("project.json")
	var json_file = FileAccess.open(json_filepath, FileAccess.WRITE)
	if json_file:
		json_file.store_string(proj_str)
		json_file.close()
		project_path = dir
		has_edits = false
	else:
		printerr("failed to save to '%s'" % [json_filepath])
		return false
	return true

func add_sprinkler(sprink: Sprinkler):
	if not sprinklers.has(sprink):
		sprink.connect('moved', _on_sprinkler_moved)
		sprinklers.append(sprink)
		emit_signal('sprinkler_changed', sprink, ChangeType.ADD)
		has_edits = true
	else:
		push_warning("sprinkler %s is already added to project. ignoring add." % sprink.name)

func remove_sprinkler(sprink: Sprinkler):
	if sprinklers.has(sprink):
		sprinklers.erase(sprink)
		emit_signal('sprinkler_changed', sprink, ChangeType.REMOVE)
		has_edits = true
	else:
		push_warning("sprinkler %s is not in the project. ignoring remove." % sprink.name)

func serialize():
	# serialize all sprinkler objecs
	var sprinklers_ser = []
	for sprink in sprinklers:
		sprinklers_ser.append(sprink.serialize())
	
	# return final serialized object
	return {
		'sprinklers' : sprinklers_ser
	}

func deserialize(obj):
	_suppress_self_edit_signals = true
	reset()
	for sprink_ser in obj['sprinklers']:
		var sprink := Sprinkler.new()
		sprink.deserialize(sprink_ser)
		add_sprinkler(sprink)
	_suppress_self_edit_signals = false

func _on_sprinkler_moved(sprink, from_xy, to_xy):
	print("sprinkler '%s' moved %s -> %s" % [sprink.name, from_xy, to_xy])
	emit_signal('sprinkler_changed', sprink, ChangeType.MODIFIED)
	has_edits = true
