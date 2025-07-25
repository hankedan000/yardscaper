extends Node

var main : Main = null

const UNKOWN_VERSION : String = "0.0.0"
const HOVER_COLOR := Color.DARK_TURQUOISE
const SELECT_COLOR := Color.DARK_ORANGE
const DEFAULT_PIPE_COLOR := Color.GRAY
const DEFAULT_PIPE_NODE_COLOR := Color.DIM_GRAY
const OUTLINE_BASE_WIDTH_PX : float = 2.0
const MAX_RECENT_PROJECT = 10
const RECENT_PROJECTS_FILE := &"recent_project.json"
const GITHUB_USER := &"hankedan000"
const GITHUB_REPO := &"yardscaper"

const SHORT_LENGTH_MIN_IN := 0.0
const SHORT_LENGTH_MAX_IN := +100.0
const SHORT_LENGTH_STEP_IN := 0.001
const LONG_LENGTH_MIN_IN := 0.0
const LONG_LENGTH_MAX_IN := +10000.0
const LONG_LENGTH_STEP_IN := 0.001
const PRESSURE_MIN_PSI := -10000.0
const PRESSURE_MAX_PSI := +10000.0
const PRESSURE_STEP_PSI := 0.001
const FLOW_MIN_GPM := -10000.0
const FLOW_MAX_GPM := +10000.0
const FLOW_STEP_GPM := 0.001
const MINOR_LOSS_COEF_MIN := 0.0
const MINOR_LOSS_COEF_MAX := 1000.0
const MINOR_LOSS_COEF_STEP := 0.000000001

# most recent is at the front, oldest at the back
var _recent_projects : Array[String] = []

enum ViewOptions {
	Current,
	Full,
	Zone
}

func _ready():
	# try to get recent projects from old "Sprinkler Designer" user:// dir
	_try_migrate_recent_projects()
	
	# restore recent projects from user preferences
	var recent_proj_path := recent_project_path()
	if FileAccess.file_exists(recent_proj_path):
		var ser_projects = FileUtils.from_json_file(recent_proj_path)
		if ser_projects is Array:
			while len(ser_projects) > 0:
				add_recent_project(ser_projects.pop_back())

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
	FileUtils.to_json_file(_recent_projects, recent_project_path())

func remove_recent_project(path: String) -> void:
	_recent_projects.erase(path)
	FileUtils.to_json_file(_recent_projects, recent_project_path())

var _prev_cursor_shape : Input.CursorShape = Input.CURSOR_ARROW
var _curr_cursor_shape : Input.CursorShape = Input.CURSOR_ARROW

func push_cursor_shape(cursor_shape: Input.CursorShape) -> void:
	if cursor_shape != _curr_cursor_shape:
		_prev_cursor_shape = _curr_cursor_shape
		_curr_cursor_shape = cursor_shape
		Input.set_default_cursor_shape(cursor_shape)

func pop_cursor_shape() -> Input.CursorShape:
	if _prev_cursor_shape != _curr_cursor_shape:
		_curr_cursor_shape = _prev_cursor_shape
		_prev_cursor_shape = Input.CURSOR_ARROW
		Input.set_default_cursor_shape(_curr_cursor_shape)
	return _curr_cursor_shape

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
