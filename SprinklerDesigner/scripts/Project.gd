extends Node
class_name Project

signal opened()
signal saved()
signal closed()
signal node_changed(node, change_type, args)
signal has_edits_changed(has_edits)

enum ChangeType {
	ADD,
	REMOVE,
	PROP_EDIT
}

const SprinklerScene : PackedScene = preload("res://scenes/world_objects/Sprinkler/Sprinkler.tscn")
const ImageNodeScene : PackedScene = preload("res://scenes/world_objects/ImageNode/ImageNode.tscn")
const DistanceMeasurementScene : PackedScene = preload("res://scenes/world_objects/DistanceMeasurement/DistanceMeasurement.tscn")
const PolygonNodeScene : PackedScene = preload("res://scenes/world_objects/PolygonNode/PolygonNode.tscn")

var project_path = ""
var objects = []
var has_edits = false :
	set(value):
		var old_value = has_edits
		has_edits = value
		if old_value != has_edits and not _suppress_self_edit_signals:
			emit_signal('has_edits_changed', has_edits)
var layout_pref := LayoutPreferences.new()

var _suppress_self_edit_signals = false

func reset():
	_suppress_self_edit_signals = true
	while not objects.is_empty():
		remove_object(objects.front())
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
	else:
		return false
	
	# load layout preferences
	var layout_pref_filepath = dir.path_join('layout_pref.json')
	var layout_pref_data = Utils.from_json_file(layout_pref_filepath)
	if layout_pref_data:
		layout_pref.deserialize(layout_pref_data)
		
	emit_signal('opened')
	return true

func save():
	return save_as(project_path)

func save_preferences():
	# save layout preferences
	var layout_pref_filepath = project_path.path_join('layout_pref.json')
	Utils.to_json_file(layout_pref.serialize(), layout_pref_filepath)

func save_as(dir: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		return false
	var json_filepath = dir.path_join("project.json")
	if Utils.to_json_file(serialize(), json_filepath):
		Globals.add_recent_project(dir)
		project_path = dir
		has_edits = false
	else:
		return false
		
	save_preferences()
	
	# create image directory
	var img_dir = get_img_dir()
	if DirAccess.dir_exists_absolute(img_dir):
		pass # nothing to make
	elif DirAccess.make_dir_absolute(img_dir) != OK:
		push_error("failed to create img dir in '%s'" % [img_dir])
		return false
	
	emit_signal('saved')
	return true

func get_subclass_count(subclass: String):
	var count = 0
	for obj in objects:
		if obj.get_subclass() == subclass:
			count += 1
	return count

func add_object(obj: WorldObject):
	if objects.has(obj):
		push_warning("obj '%s' is already added to project. ignoring add." % obj.name)
		return
	
	# connect signal handlers
	obj.property_changed.connect(_on_node_property_changed.bind(obj))
	if obj is MoveableNode2D:
		obj.moved.connect(_on_node_moved)
	objects.append(obj)
	emit_signal('node_changed', obj, ChangeType.ADD, [])
	has_edits = true

func remove_object(obj: WorldObject):
	if not objects.has(obj):
		push_warning("obj '%s' is not in the project. ignoring remove." % obj.name)
		return
	
	objects.erase(obj)
	
	# disconnect signal handlers
	obj.property_changed.disconnect(_on_node_property_changed)
	if obj is MoveableNode2D:
		obj.moved.disconnect(_on_node_moved)
	
	emit_signal('node_changed', obj, ChangeType.REMOVE, [])
	has_edits = true

func get_img_dir():
	if len(project_path) == 0:
		push_error("need to set project_path first before you can add images")
	return project_path.path_join("imgs")

func load_image(filename: String):
	var img_path = get_img_dir().path_join(filename)
	return Image.load_from_file(img_path)

func get_unique_name(subclass: String):
	return '%s%d' % [subclass, get_subclass_count(subclass)]

func add_image(path: String) -> bool:
	var filename = path.get_file()
	# make sure we don't already have an image with that name imported
	for obj in objects:
		if obj is ImageNode and obj.filename == filename:
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
	img_node.user_label = get_unique_name('ImageNode')
	add_object(img_node)
	has_edits = true
	return true

func serialize():
	# serialize all objects base on order they appear in world
	var objects_ser = []
	if len(objects) > 0:
		var world : WorldViewportContainer = objects[0].world
		for obj in world.objects.get_children():
			objects_ser.append(obj.serialize())
	
	return {
		'objects' : objects_ser
	}

func deserialize(obj):
	_suppress_self_edit_signals = true
	reset()
	for ser_obj in Utils.dict_get(obj, 'objects', []):
		var wobj = instance_world_obj(ser_obj)
		if wobj:
			add_object(wobj)
	_suppress_self_edit_signals = false

func instance_world_obj(ser_obj: Dictionary) -> WorldObject:
	var wobj = null
	match ser_obj['subclass']:
		'Sprinkler':
			wobj = SprinklerScene.instantiate()
		'ImageNode':
			wobj = ImageNodeScene.instantiate()
		'DistanceMeasurement':
			wobj = DistanceMeasurementScene.instantiate()
		'PolygonNode':
			wobj = PolygonNodeScene.instantiate()
		_:
			push_warning("unimplemented subclass '%s' deserialization" % [ser_obj['subclass']])
	if wobj:
		wobj.deserialize(ser_obj)
	return wobj

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
