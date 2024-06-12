extends Node

signal sprinkler_changed(sprink, change_type)

enum ChangeType {
	ADD,
	REMOVE,
	MODIFIED
}

var sprinklers = []

func reset():
	while not sprinklers.is_empty():
		remove_sprinkler(sprinklers.front())

func save(filepath):
	var proj_str = JSON.stringify(
		serialize(),
		" ",  # indent
		true, # sort_keys
		true) # full_precision
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file:
		file.store_string(proj_str)
		file.close()
	else:
		printerr("failed to save to '%s'" % [filepath])
		return false
	return true

func load(filepath):
	var file = FileAccess.open(filepath, FileAccess.READ)
	var proj_str = file.get_as_text()
	var json = JSON.new()
	if json.parse(proj_str) == OK:
		deserialize(json.data)
	else:
		printerr("failed to open to '%s'" % [filepath])
		return false
	return true

func add_sprinkler(sprink: Sprinkler):
	if not sprinklers.has(sprink):
		sprinklers.append(sprink)
		emit_signal('sprinkler_changed', sprink, ChangeType.ADD)
	else:
		push_warning("sprinkler %s is already added to project. ignoring add." % sprink.name)

func remove_sprinkler(sprink: Sprinkler):
	if sprinklers.has(sprink):
		sprinklers.erase(sprink)
		emit_signal('sprinkler_changed', sprink, ChangeType.REMOVE)
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
	reset()
	for sprink_ser in obj['sprinklers']:
		var sprink := Sprinkler.new()
		sprink.deserialize(sprink_ser)
		add_sprinkler(sprink)
