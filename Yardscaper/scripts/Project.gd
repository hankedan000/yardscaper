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
	PROP_EDIT,
	FLUID_PROP_EDIT
}

const VERSION_KEY := &"version"
const PROJECT_NAME_KEY := &"project_name"
const OBJECTS_KEY := &"objects"

const SprinklerScene : PackedScene = preload("res://scenes/world_objects/fluid_objects/Sprinkler/Sprinkler.tscn")
const ImageNodeScene : PackedScene = preload("res://scenes/world_objects/ImageNode/ImageNode.tscn")
const DistanceMeasurementScene : PackedScene = preload("res://scenes/world_objects/DistanceMeasurement/DistanceMeasurement.tscn")
const PolygonNodeScene : PackedScene = preload("res://scenes/world_objects/PolygonNode/PolygonNode.tscn")
const PipeScene : PackedScene = preload("res://scenes/world_objects/fluid_objects/Pipe/Pipe.tscn")
const PipeNodeScene : PackedScene = preload("res://scenes/world_objects/fluid_objects/PipeNode/PipeNode.tscn")

var project_path = ""
var project_name : String = ""
var objects : Array[WorldObject] = []
var has_edits = false :
	set(value):
		var old_value = has_edits
		has_edits = value
		_has_edits_since_auto_save = value
		if old_value != has_edits and not _suppress_self_edit_signals:
			has_edits_changed.emit(has_edits)
var layout_pref := LayoutPreferences.new()
var fsys : FSystem = FSystem.new()

var _auto_save_timer := Timer.new()
var _auto_save_thread : Thread = null
var _has_edits_since_auto_save := false
var _suppress_self_edit_signals = false

func _ready() -> void:
	add_child(_auto_save_timer)
	_auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	_auto_save_timer.start(1)

func reset() -> void:
	_suppress_self_edit_signals = true
	for obj in objects:
		obj.queue_free()
	objects.clear()
	fsys.clear()
	project_name = ""
	_suppress_self_edit_signals = false
	has_edits = false
	closed.emit()

func is_opened() -> bool:
	return len(project_path) > 0

class QuickProjectInfo:
	var name : String = "Unnamed Project"
	var version : Version = Version.from_str(Globals.UNKOWN_VERSION)
	# last modified timestamp (in UNIX time)
	var last_modified : int = 0
	var has_recovery_data : bool = false

# @param[in] dir - path to the project
# @return parsed QuickProjectInfo, or null on error
static func get_quick_info(dir: String) -> QuickProjectInfo:
	var project_data = _get_project_data(dir, false)
	if project_data.is_empty():
		return null
	
	var info := QuickProjectInfo.new()
	info.name = _get_project_name(project_data, dir)
	info.version = Version.from_str(DictUtils.get_w_default(project_data, VERSION_KEY, Globals.UNKOWN_VERSION))
	info.last_modified = FileAccess.get_modified_time(_get_project_data_filepath(dir, false))
	info.has_recovery_data = has_auto_save_file(dir)
	return info

static func rename_project(dir: String, new_name: String) -> bool:
	var project_data = _get_project_data(dir, false)
	if project_data.is_empty():
		return false
	
	# apply new name
	project_data[PROJECT_NAME_KEY] = new_name
	
	# save modified project data
	var json_filepath := _get_project_data_filepath(dir, false)
	return FileUtils.to_json_file(project_data, json_filepath)

static func has_auto_save_file(dir: String) -> bool:
	var auto_save_filepath := _get_project_data_filepath(dir, true)
	return FileAccess.file_exists(auto_save_filepath)

static func static_discard_unsaved_edits(dir: String) -> void:
	var auto_save_filepath := _get_project_data_filepath(dir, true)
	if not FileAccess.file_exists(auto_save_filepath):
		return
	DirAccess.remove_absolute(auto_save_filepath)

static func recover_from_auto_save(dir: String) -> bool:
	var auto_save_filepath := _get_project_data_filepath(dir, true)
	if not FileAccess.file_exists(auto_save_filepath):
		return false
	var regular_save_filepath := _get_project_data_filepath(dir, false)
	return DirAccess.rename_absolute(auto_save_filepath, regular_save_filepath) == OK

func discard_unsaved_edits() -> void:
	if ! is_opened():
		return
	
	if _auto_save_thread:
		# wait so we don't delete the file while it's saving
		_auto_save_thread.wait_to_finish()
	static_discard_unsaved_edits(project_path)

func open(dir: String) -> bool:
	var project_data = _get_project_data(dir, false)
	if project_data.is_empty():
		return false
	
	# open the project data
	Globals.add_recent_project(dir)
	project_path = dir
	deserialize(project_data, dir)
	has_edits = false
	
	# load layout preferences
	var layout_pref_filepath = dir.path_join('layout_pref.json')
	var layout_pref_data = FileUtils.from_json_file(layout_pref_filepath)
	if layout_pref_data:
		layout_pref.deserialize(layout_pref_data)
	
	opened.emit()
	return true

func save() -> bool:
	return save_as(project_path)

func save_preferences() -> void:
	# save layout preferences
	var layout_pref_filepath = project_path.path_join('layout_pref.json')
	FileUtils.to_json_file(layout_pref.serialize(), layout_pref_filepath)

func save_as(dir: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		return false
		
	# serial project and save to json file
	var json_filepath = _get_project_data_filepath(dir, false)
	if not FileUtils.to_json_file(serialize(), json_filepath):
		return false
	
	# cleanup any auto-save files we don't need anymore
	var auto_save_filepath := _get_project_data_filepath(dir, true)
	if FileAccess.file_exists(auto_save_filepath):
		DirAccess.remove_absolute(auto_save_filepath)
	
	Globals.add_recent_project(dir)
	project_path = dir
	has_edits = false
		
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

func get_type_name_count(type_name: StringName) -> int:
	var count = 0
	for obj in objects:
		if obj.get_type_name() == type_name:
			count += 1
	return count

func get_obj_by_user_label(user_label: String) -> WorldObject:
	for obj in objects:
		if obj.user_label == user_label:
			return obj
	return null

func _remove_object(wobj: WorldObject) -> void:
	objects.erase(wobj)
	
	# disconnect signal handlers
	wobj.property_changed.disconnect(_on_node_property_changed)
	wobj.fluid_property_changed.disconnect(_on_node_fluid_property_changed)
	wobj.moved.disconnect(_on_node_moved)
	
	has_edits = true
	node_changed.emit(wobj, ChangeType.REMOVE, [])

func get_img_dir() -> String:
	if len(project_path) == 0:
		push_error("need to set project_path first before you can add images")
	return project_path.path_join("imgs")

func load_image(filename: String) -> Image:
	var img_path = get_img_dir().path_join(filename)
	return Image.load_from_file(img_path)

func is_user_label_unique(user_label: String) -> bool:
	for obj in objects:
		if user_label == obj.user_label:
			return false
	return true

func get_unique_name(type_name: StringName) -> String:
	var id : int = 0
	while true:
		var user_label := type_name + str(id)
		if is_user_label_unique(user_label):
			return user_label
		id += 1
	return "" # should never get here

# @return a dict containing lists of WorldObjects keyed by their zone #
func get_objs_by_zone() -> Dictionary:
	var objs_by_zone := {}
	for obj in objects:
		if &"zone" in obj:
			if obj.zone in objs_by_zone:
				objs_by_zone[obj.zone].push_back(obj)
			else:
				objs_by_zone[obj.zone] = [obj] as Array[WorldObject]
	return objs_by_zone

# @param[in] zone - the zone # to search for
# @return a list of WorldObjects that are in the specified zone #
func get_objs_in_zone(zone: int) -> Array[WorldObject]:
	var objs_by_zone := get_objs_by_zone()
	if zone in objs_by_zone:
		return objs_by_zone[zone]
	return []

func serialize() -> Dictionary:
	var objects_ser = []
	if len(objects) > 0:
		# serialize all objects based on order they appear in world
		var world : WorldViewportContainer = objects[0].world
		for obj in world.objects.get_children():
			objects_ser.append(obj.serialize())
	
	return {
		VERSION_KEY : ProjectUtils.get_app_version(),
		OBJECTS_KEY : objects_ser,
		PROJECT_NAME_KEY : project_name
	}

# @param[in] proj_data - serialized project data
# @param[in] dir - project directory path
func deserialize(proj_data: Dictionary, dir: String) -> void:
	_suppress_self_edit_signals = true
	reset()
	for obj_data in DictUtils.get_w_default(proj_data, OBJECTS_KEY, []):
		instance_world_obj_from_data(obj_data)
	
	# notify all BaseNodes to restore their pipe connections now that all
	# objects deserialized.
	for obj in objects:
		if obj is BaseNode:
			obj.restore_pipe_connections()
	
	project_name = _get_project_name(proj_data, dir)
	_suppress_self_edit_signals = false

func instance_world_obj(type_name: StringName) -> WorldObject:
	var new_wobj := _instance_world_obj(type_name)
	if new_wobj is WorldObject:
		has_edits = true
		node_changed.emit(new_wobj, ChangeType.ADD, [])
	return new_wobj

func instance_world_obj_from_data(data: Dictionary) -> WorldObject:
	var type_name = DictUtils.get_w_default(data, WorldObject.PROP_KEY_SUBCLASS, null) as StringName
	if ! (type_name is StringName):
		return null
	var new_wobj := _instance_world_obj(type_name)
	if new_wobj is WorldObject:
		new_wobj.deserialize(data)
		has_edits = true
		node_changed.emit(new_wobj, ChangeType.ADD, [])
	return new_wobj

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
	
	# create a new ImageNode
	var obj_data := {}
	obj_data[WorldObject.PROP_KEY_SUBCLASS] = TypeNames.IMG_NODE
	obj_data[ImageNode.PROP_KEY_FILENAME] = filename
	return instance_world_obj_from_data(obj_data)

func _instance_world_obj(type_name: StringName) -> WorldObject:
	var wobj : WorldObject = null
	match type_name:
		TypeNames.SPRINKLER:
			wobj = SprinklerScene.instantiate() as Sprinkler
		TypeNames.IMG_NODE:
			wobj = ImageNodeScene.instantiate() as ImageNode
		TypeNames.DIST_MEASUREMENT:
			wobj = DistanceMeasurementScene.instantiate() as DistanceMeasurement
		TypeNames.POLYGON_NODE:
			wobj = PolygonNodeScene.instantiate() as PolygonNode
		TypeNames.PIPE:
			wobj = PipeScene.instantiate() as Pipe
		TypeNames.PIPE_NODE:
			wobj = PipeNodeScene.instantiate() as PipeNode
		_:
			push_warning("unsupported subclass '%s'" % type_name)
			return wobj
	
	wobj.user_label = TheProject.get_unique_name(type_name)
	wobj.parent_project = self
	wobj._init_world_obj()
	wobj.property_changed.connect(_on_node_property_changed)
	wobj.fluid_property_changed.connect(_on_node_fluid_property_changed)
	wobj.moved.connect(_on_node_moved)
	objects.append(wobj)
	return wobj

static func _get_project_data_filepath(project_dir: String, from_auto_save: bool) -> String:
	if from_auto_save:
		return project_dir.path_join("project_auto_save.json")
	else:
		return project_dir.path_join("project.json")

# returns an empty dictionary on error
static func _get_project_data(dir: String, from_auto_save: bool) -> Dictionary:
	if not DirAccess.dir_exists_absolute(dir):
		push_warning("project dir '%s' doesn't exist" % [dir])
		return {}
	return FileUtils.from_json_file(_get_project_data_filepath(dir, from_auto_save))

# @param[in] data - serialized project data
static func _get_project_name(data: Dictionary, project_dir: String) -> String:
	var pname = DictUtils.get_w_default(data, PROJECT_NAME_KEY, "") as String
	if pname.length() == 0:
		# try returning project folder name as project name in
		var parts = project_dir.split("/")
		if parts.size() > 0:
			pname = parts[-1]
	return pname

func _on_node_property_changed(obj: WorldObject, property_key: StringName, from: Variant, to: Variant) -> void:
	has_edits = true
	node_changed.emit(obj, ChangeType.PROP_EDIT, [property_key, from, to])

func _on_node_fluid_property_changed(obj: WorldObject, prop_key: StringName, from: Variant, to: Variant) -> void:
	has_edits = true
	node_changed.emit(obj, ChangeType.FLUID_PROP_EDIT, [prop_key, from, to])

func _on_node_moved(obj: WorldObject, from_xy, to_xy):
	has_edits = true
	node_changed.emit(obj, ChangeType.PROP_EDIT, [&'global_position', from_xy, to_xy])

func __THREADED__auto_save(filepath: String, data: Dictionary) -> void:
	FileUtils.to_json_file(data, filepath)

func _on_auto_save_timer_timeout() -> void:
	if not is_opened():
		return
	elif not _has_edits_since_auto_save:
		return
	elif _auto_save_thread && _auto_save_thread.is_alive():
		return # still saving from last cycle
	
	if _auto_save_thread:
		_auto_save_thread.wait_to_finish() # allow thread to cleanup
	
	var filepath := _get_project_data_filepath(project_path, true)
	var data := serialize()
	_auto_save_thread = Thread.new()
	_auto_save_thread.start(__THREADED__auto_save.bind(filepath, data))
	_has_edits_since_auto_save = false
