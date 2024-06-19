extends Node

signal opened()
signal closed()
signal node_changed(node, change_type, args)
signal has_edits_changed(has_edits)

enum ChangeType {
	ADD,
	REMOVE,
	PROP_EDIT
}

var ImageNodeScene : PackedScene = preload("res://scenes/ImageNode/ImageNode.tscn")

var project_path = ""
var sprinklers = []
var images = []
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
	emit_signal('closed')

func is_opened() -> bool:
	return len(project_path) > 0

func open(dir: String):
	if len(dir) == 0:
		return false
	elif not DirAccess.dir_exists_absolute(dir):
		push_error("project dir '%s' doesn't exist" % [dir])
		return false
	
	var json_filepath = dir.path_join("project.json")
	var ser_data = Utils.from_json_file(json_filepath)
	if ser_data:
		Globals.add_recent_project(dir)
		project_path = dir
		deserialize(ser_data)
		has_edits = false
		emit_signal('opened')
	else:
		return false
	return true

func save():
	return save_as(project_path)

func save_as(dir: String):
	var json_filepath = dir.path_join("project.json")
	if Utils.to_json_file(serialize(), json_filepath):
		Globals.add_recent_project(dir)
		project_path = dir
		has_edits = false
	else:
		return false
	
	# create image directory
	var img_dir = get_img_dir()
	if DirAccess.dir_exists_absolute(img_dir):
		pass # nothing to make
	elif DirAccess.make_dir_absolute(img_dir) != OK:
		printerr("failed to create img dir in '%s'" % [img_dir])
		return false
	
	return true

func add_sprinkler(sprink: Sprinkler):
	if not sprinklers.has(sprink):
		sprink.moved.connect(_on_node_moved)
		sprink.property_changed.connect(_on_node_property_changed.bind(sprink))
		sprinklers.append(sprink)
		emit_signal('node_changed', sprink, ChangeType.ADD, [])
		has_edits = true
	else:
		push_warning("sprinkler %s is already added to project. ignoring add." % sprink.name)

func remove_sprinkler(sprink: Sprinkler):
	if sprinklers.has(sprink):
		sprinklers.erase(sprink)
		emit_signal('node_changed', sprink, ChangeType.REMOVE, [])
		has_edits = true
	else:
		push_warning("sprinkler %s is not in the project. ignoring remove." % sprink.name)

func get_img_dir():
	if len(project_path) == 0:
		push_error("need to set project_path first before you can add images")
	return project_path.path_join("imgs")

func load_image(filename: String):
	var img_path = get_img_dir().path_join(filename)
	return Image.load_from_file(img_path)

func add_image(path: String) -> bool:
	var filename = path.get_file()
	# make sure we don't already have an image with that name imported
	for img in images:
		if filename == img.filename:
			push_warning("image with filename '%s' already imported" % filename)
			return false
	
	# copy image into project directories img dir
	var img_path = get_img_dir().path_join(filename)
	if DirAccess.copy_absolute(path, img_path) != OK:
		push_warning("failed to copy '%s' to '%s'" % [path, img_path])
		return false
	var img = Image.load_from_file(img_path)
	if not (img is Image):
		push_warning("failed to load image '%s'" % [img_path])
		return false
	
	# load image and create a new ImageNode
	var img_node : ImageNode = ImageNodeScene.instantiate()
	img_node.filename = filename
	_add_image(img_node)
	has_edits = true
	return true

func _add_image(img_node):
	img_node.moved.connect(_on_node_moved)
	img_node.property_changed.connect(_on_node_property_changed.bind(img_node))
	images.append(img_node)
	emit_signal('node_changed', img_node, ChangeType.ADD, [])

func serialize():
	# serialize all sprinkler objects
	var sprinklers_ser = []
	for sprink in sprinklers:
		sprinklers_ser.append(sprink.serialize())
	
	# serialize all image objects
	var images_ser = []
	for img in images:
		images_ser.append(img.serialize())
	
	# return final serialized object
	return {
		'sprinklers' : sprinklers_ser,
		'images' : images_ser
	}

func deserialize(obj):
	_suppress_self_edit_signals = true
	reset()
	for sprink_ser in Utils.dict_get(obj, 'sprinklers', []):
		var sprink := Sprinkler.new()
		sprink.deserialize(sprink_ser)
		add_sprinkler(sprink)
	for img_ser in Utils.dict_get(obj, 'images', []):
		var img_node := ImageNodeScene.instantiate()
		img_node.deserialize(img_ser)
		_add_image(img_node)
	_suppress_self_edit_signals = false

func _on_node_property_changed(property, from, to, node):
	emit_signal(
		'node_changed',
		node,
		ChangeType.PROP_EDIT,
		[property, from, to])
	has_edits = true

func _on_node_moved(node, from_xy, to_xy):
	emit_signal(
		'node_changed',
		node,
		ChangeType.PROP_EDIT,
		['position', from_xy, to_xy])
	has_edits = true
