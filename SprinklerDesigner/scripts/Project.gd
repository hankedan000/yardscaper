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

const VERSION_KEY := &"version"
const PROJECT_NAME_KEY := &"project_name"
const OBJECTS_KEY := &"objects"

const SprinklerScene : PackedScene = preload("res://scenes/world_objects/Sprinkler/Sprinkler.tscn")
const ImageNodeScene : PackedScene = preload("res://scenes/world_objects/ImageNode/ImageNode.tscn")
const DistanceMeasurementScene : PackedScene = preload("res://scenes/world_objects/DistanceMeasurement/DistanceMeasurement.tscn")
const PolygonNodeScene : PackedScene = preload("res://scenes/world_objects/PolygonNode/PolygonNode.tscn")

var project_path = ""
var project_name : String = ""
var objects : Array[WorldObject] = []
var has_edits = false :
	set(value):
		var old_value = has_edits
		has_edits = value
		if old_value != has_edits and not _suppress_self_edit_signals:
			has_edits_changed.emit(has_edits)
var layout_pref := LayoutPreferences.new()

var _suppress_self_edit_signals = false

func reset() -> void:
	_suppress_self_edit_signals = true
	while not objects.is_empty():
		remove_object(objects.front())
	project_name = ""
	_suppress_self_edit_signals = false
	has_edits = false
	closed.emit()

func is_opened() -> bool:
	return len(project_path) > 0

class QuickProjectInfo:
	var name : String = "Unnamed Project"
	var version : String = Globals.UNKOWN_VERSION
	# last modified timestamp (in UNIX time)
	var last_modified : int = 0

# @param[in] dir - path to the project
# @return parsed QuickProjectInfo, or null on error
static func get_quick_info(dir: String) -> QuickProjectInfo:
	var project_data = _get_project_data(dir)
	if project_data.is_empty():
		return null
	
	var info := QuickProjectInfo.new()
	info.name = _get_project_name(project_data, dir)
	info.version = Utils.dict_get(project_data, VERSION_KEY, Globals.UNKOWN_VERSION)
	info.last_modified = FileAccess.get_modified_time(_get_project_data_filepath(dir))
	return info

static func rename_project(dir: String, new_name: String) -> bool:
	var project_data = _get_project_data(dir)
	if project_data.is_empty():
		return false
	
	# apply new name
	project_data[PROJECT_NAME_KEY] = new_name
	
	# save modified project data
	var json_filepath := _get_project_data_filepath(dir)
	return Utils.to_json_file(project_data, json_filepath)

func open(dir: String) -> bool:
	var project_data = _get_project_data(dir)
	if project_data.is_empty():
		return false
	
	# open the project data
	Globals.add_recent_project(dir)
	project_path = dir
	deserialize(project_data, dir)
	has_edits = false
	
	# load layout preferences
	var layout_pref_filepath = dir.path_join('layout_pref.json')
	var layout_pref_data = Utils.from_json_file(layout_pref_filepath)
	if layout_pref_data:
		layout_pref.deserialize(layout_pref_data)
	
	opened.emit()
	return true

func save() -> bool:
	return save_as(project_path)

func save_preferences() -> void:
	# save layout preferences
	var layout_pref_filepath = project_path.path_join('layout_pref.json')
	Utils.to_json_file(layout_pref.serialize(), layout_pref_filepath)

func save_as(dir: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		return false
	var json_filepath = _get_project_data_filepath(dir)
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
	
	saved.emit()
	return true

func get_subclass_count(subclass: String) -> int:
	var count = 0
	for obj in objects:
		if obj.get_subclass() == subclass:
			count += 1
	return count

func add_object(obj: WorldObject) -> void:
	if objects.has(obj):
		push_warning("obj '%s' is already added to project. ignoring add." % obj.name)
		return
	
	# connect signal handlers
	obj.property_changed.connect(_on_node_property_changed)
	obj.moved.connect(_on_node_moved)
	objects.append(obj)
	node_changed.emit(obj, ChangeType.ADD, [])
	has_edits = true

func remove_object(obj: WorldObject) -> void:
	if not objects.has(obj):
		push_warning("obj '%s' is not in the project. ignoring remove." % obj.name)
		return
	
	objects.erase(obj)
	
	# disconnect signal handlers
	obj.property_changed.disconnect(_on_node_property_changed)
	obj.moved.disconnect(_on_node_moved)
	
	node_changed.emit(obj, ChangeType.REMOVE, [])
	has_edits = true

func get_img_dir() -> String:
	if len(project_path) == 0:
		push_error("need to set project_path first before you can add images")
	return project_path.path_join("imgs")

func load_image(filename: String) -> Image:
	var img_path = get_img_dir().path_join(filename)
	return Image.load_from_file(img_path)

func get_unique_name(subclass: String) -> String:
	return '%s%d' % [subclass, get_subclass_count(subclass)]

func add_image(path: String) -> ImageNode:
	# try to copy image into project directories img dir
	var filename = path.get_file()
	var img_path = get_img_dir().path_join(filename)
	if FileAccess.file_exists(img_path):
		# TODO warn user about importing existing?
		pass # already exist, so don't copy
	elif DirAccess.copy_absolute(path, img_path) != OK:
		push_warning("failed to copy '%s' to '%s'" % [path, img_path])
		return null
	var img = Image.load_from_file(img_path)
	if not (img is Image):
		push_warning("failed to load image '%s'" % [img_path])
		return null
	
	# load image and create a new ImageNode
	var img_node : ImageNode = ImageNodeScene.instantiate()
	img_node.filename = filename
	img_node.user_label = get_unique_name('ImageNode')
	add_object(img_node)
	has_edits = true
	return img_node

func serialize():
	var objects_ser = []
	if len(objects) > 0:
		# serialize all objects based on order they appear in world
		var world : WorldViewportContainer = objects[0].world
		for obj in world.objects.get_children():
			objects_ser.append(obj.serialize())
	
	return {
		VERSION_KEY : Globals.get_app_version(),
		OBJECTS_KEY : objects_ser,
		PROJECT_NAME_KEY : project_name
	}

# @param[in] data - serialized project data
# @param[in] dir - project directory path
func deserialize(data: Dictionary, dir: String) -> void:
	_suppress_self_edit_signals = true
	reset()
	for ser_obj in Utils.dict_get(data, OBJECTS_KEY, []):
		var wobj = instance_world_obj(ser_obj)
		if wobj:
			add_object(wobj)
	project_name = _get_project_name(data, dir)
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

static func _get_project_data_filepath(project_dir: String) -> String:
	return project_dir.path_join("project.json")

# returns an empty dictionary on error
static func _get_project_data(dir: String) -> Dictionary:
	if not DirAccess.dir_exists_absolute(dir):
		push_error("project dir '%s' doesn't exist" % [dir])
		return {}
	
	return Utils.from_json_file(_get_project_data_filepath(dir))

# @param[in] data - serialized project data
static func _get_project_name(data: Dictionary, project_dir: String) -> String:
	var pname = Utils.dict_get(data, PROJECT_NAME_KEY, "") as String
	if pname.length() == 0:
		# try returning project folder name as project name in
		var parts = project_dir.split("/")
		if parts.size() > 0:
			pname = parts[-1]
	return pname

func _on_node_property_changed(obj: WorldObject, property_key: StringName, from: Variant, to: Variant) -> void:
	node_changed.emit(obj, ChangeType.PROP_EDIT, [property_key, from, to])
	has_edits = true

func _on_node_moved(node, from_xy, to_xy):
	node_changed.emit(node, ChangeType.PROP_EDIT, ['position', from_xy, to_xy])
	has_edits = true
