extends Node

var main : Main = null

const UNKOWN_VERSION : String = "0.0.0"
const HOVER_COLOR := Color.DARK_TURQUOISE
const SELECT_COLOR := Color.DARK_ORANGE
const MAX_RECENT_PROJECT = 10
const RECENT_PROJECTS_PATH = "user://recent_project.json"

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
	
	# restore recent projects from user preferences
	if FileAccess.file_exists(RECENT_PROJECTS_PATH):
		var ser_projects = Utils.from_json_file(RECENT_PROJECTS_PATH)
		if ser_projects is Array:
			while len(ser_projects) > 0:
				add_recent_project(ser_projects.pop_back())

func get_app_name() -> String:
	return ProjectSettings.get_setting("application/config/name") as String

func get_app_version() -> Version:
	var sver := ProjectSettings.get_setting("application/config/version") as String
	return Version.from_str(sver)

func get_recent_projects() -> Array[String]:
	return _recent_projects

func add_recent_project(path: String) -> void:
	# remove path if it exists so that it will promoted to the front
	if path in _recent_projects:
		_recent_projects.erase(path)
	_recent_projects.push_front(path)
	while len(_recent_projects) > MAX_RECENT_PROJECT:
		_recent_projects.pop_back()
	Utils.to_json_file(_recent_projects, RECENT_PROJECTS_PATH)

func remove_recent_project(path: String) -> void:
	_recent_projects.erase(path)
	Utils.to_json_file(_recent_projects, RECENT_PROJECTS_PATH)
