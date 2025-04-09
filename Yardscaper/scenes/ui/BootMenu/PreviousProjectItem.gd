extends HBoxContainer
class_name PreviousProjectItem

signal selected(item: PreviousProjectItem)
signal opened(item: PreviousProjectItem)

@onready var select_button : Button = $SelectButton
@onready var name_label : Label = $SelectButton/HBoxContainer/VBoxContainer/ProjectNameLabel
@onready var path_label : Label = $SelectButton/HBoxContainer/VBoxContainer/HBoxContainer/ProjectPathLabel
@onready var version_label : Label = $SelectButton/HBoxContainer/VBoxContainer/HBoxContainer/ProjectVersionLabel
@onready var status_icon := $SelectButton/HBoxContainer/VBoxContainer/HBoxContainer/StatusIcon
@onready var modify_time_label : Label = $SelectButton/HBoxContainer/VBoxContainer/HBoxContainer/ModifyTimeLabel

const DOUBLE_CLICK_TIME_MSEC : int = 350

var _last_click_ticks_msec : int = 0
# true if the project doesn't exist on file system anymoe
var is_missing : bool = true
# false if the project's version is unknown or > editor's version
var is_version_compatible : bool = false

func setup(project_path: String) -> void:
	if not is_inside_tree():
		await ready
	# default everything as if project doesn't exist at given path
	is_missing = true
	is_version_compatible = false
	path_label.text = project_path
	path_label.tooltip_text = project_path # if path is too long, show full path as tooltip
	name_label.text = "Missing Project"
	version_label.text = "?" # unknown project version
	modify_time_label.text = Time.get_datetime_string_from_unix_time(0, true)
	
	# now populate project info if the project path does exist
	var info := Project.get_quick_info(project_path)
	if info:
		is_missing = false
		is_version_compatible = info.version.is_compatible()
		name_label.text = info.name
		version_label.text = info.version.to_string()
		status_icon.visible = false
		modify_time_label.text = Time.get_datetime_string_from_unix_time(info.last_modified, true)
	
	status_icon.visible = false
	if is_missing:
		status_icon.visible = true
		status_icon.tooltip_text = "Project no longer exists at given path."
		status_icon.status = StatusIcon.StatusType.Warning
	elif not is_version_compatible:
		status_icon.visible = true
		status_icon.tooltip_text = "Project version is greater than editor version."
		status_icon.status = StatusIcon.StatusType.Warning

func get_project_name() -> String:
	return name_label.text

func get_project_path() -> String:
	return path_label.text

func _on_button_pressed() -> void:
	var ticks_now_msec = Time.get_ticks_msec()
	var delta_ticks_msec = ticks_now_msec - _last_click_ticks_msec
	if delta_ticks_msec <= DOUBLE_CLICK_TIME_MSEC:
		if not is_missing:
			opened.emit(self)
	else:
		selected.emit(self)
	_last_click_ticks_msec = ticks_now_msec
