extends Node

var main : Main = null

const UNKOWN_VERSION : String = "0.0.0"
const HOVER_COLOR := Color.DARK_TURQUOISE
const SELECT_COLOR := Color.DARK_ORANGE
const MAX_RECENT_PROJECT = 10
const RECENT_PROJECTS_FILE := &"recent_project.json"
const GITHUB_USER := &"hankedan000"
const GITHUB_REPO := &"yardscaper"

# most recent is at the front, oldest at the back
var _recent_projects : Array[String] = []

enum ViewOptions {
	Current,
	Full,
	Zone
}

func _ready():
	for c in get_tree().root.get_children():
		if c is Main:
			main = c
			break
	
	if main == null:
		push_error("couldn't find main scene")
	
	# try to get recent projects from old "Sprinkler Designer" user:// dir
	_try_migrate_recent_projects()
	
	# restore recent projects from user preferences
	var recent_proj_path := recent_project_path()
	if FileAccess.file_exists(recent_proj_path):
		var ser_projects = Utils.from_json_file(recent_proj_path)
		if ser_projects is Array:
			while len(ser_projects) > 0:
				add_recent_project(ser_projects.pop_back())

func get_app_name() -> String:
	return ProjectSettings.get_setting("application/config/name") as String

func get_app_version() -> Version:
	var sver := ProjectSettings.get_setting("application/config/version") as String
	return Version.from_str(sver)

func recent_project_path() -> String:
	return "user://".path_join(RECENT_PROJECTS_FILE)

func get_recent_projects() -> Array[String]:
	return _recent_projects

func add_recent_project(path: String) -> void:
	# remove path if it exists so that it will promoted to the front
	if path in _recent_projects:
		_recent_projects.erase(path)
	_recent_projects.push_front(path)
	while len(_recent_projects) > MAX_RECENT_PROJECT:
		_recent_projects.pop_back()
	Utils.to_json_file(_recent_projects, recent_project_path())

func remove_recent_project(path: String) -> void:
	_recent_projects.erase(path)
	Utils.to_json_file(_recent_projects, recent_project_path())

func _try_migrate_recent_projects() -> void:
	var new_path := recent_project_path()
	if FileAccess.file_exists(new_path):
		return # recents already exist at new path. don't try migration.
	
	var old_path := "user://../Sprinkler Designer/".path_join(RECENT_PROJECTS_FILE)
	if not FileAccess.file_exists(old_path):
		return # nothing to migrate
	
	# attempt to move file to new location
	if DirAccess.rename_absolute(old_path, new_path) == OK:
		print("successfully migrated recent projects from '%s'" % old_path)
	else:
		push_warning("failed to migrate old recent projects")
