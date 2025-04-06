extends Window

signal create_requested(project_name: String, project_path: String)

@onready var browse_dialog := $BrowseDialog
@onready var project_name_line_edit := $PanelContainer/VBoxContainer/ProjectNameLineEdit
@onready var project_path_line_edit := $PanelContainer/VBoxContainer/HBoxContainer2/ProjectPathLineEdit
@onready var create_folder_button := $PanelContainer/VBoxContainer/HBoxContainer/CreateFolderCheckButton
@onready var status_icon := $PanelContainer/VBoxContainer/HBoxContainer2/StatusIcon
@onready var status_text_label := $PanelContainer/VBoxContainer/StatusTextLabel
@onready var create_button := $PanelContainer/VBoxContainer/HBoxContainer3/CreateButton

# if true, then the project path will be automatically updated to
# relect the most recent project name.
var _sync_path_to_name : bool = true

var _project_parent_dir : String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)

func _ready() -> void:
	project_name_line_edit.text = "New Project"
	_update_after_name_change()

func _set_status(type: StatusIcon.StatusType, text: String) -> void:
	status_icon.status = type
	status_text_label.text = text
	match type:
		StatusIcon.StatusType.Success:
			status_text_label.modulate = Color("#84ff86")
		StatusIcon.StatusType.Warning:
			status_text_label.modulate = Color("#fffd8f")
		StatusIcon.StatusType.Error:
			status_text_label.modulate = Color("#ff6275")

func _get_project_folder_name() -> String:
	return (project_path_line_edit.text as String).split("/")[-1]

func _project_name_to_folder_name(pname: String) -> String:
	pname = pname.replace(" ", "")
	return pname

# make sure a project name only contains the following characters
# a-z, A-Z, 0-9, -, _, ., (, ), [, ], or spaces
func _is_valid_project_name(pname: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9\\-\\_\\.\\(\\)\\[\\] ]+$")
	if regex.search(pname) == null:
		return false
	return true

func _update_after_name_change() -> void:
	var new_name := project_name_line_edit.text as String
	var is_valid_name := _is_valid_project_name(new_name)
	create_button.disabled = not is_valid_name
	if not is_valid_name:
		_set_status(
			StatusIcon.StatusType.Error,
			"Project name should only contain the following characters:\na-z, A-Z, 0-9, -, _, ., (, ), [, ], and spaces.")
		return
	
	var new_folder_name := _project_name_to_folder_name(new_name)
	if create_folder_button.button_pressed and _sync_path_to_name:
		project_path_line_edit.text = _project_parent_dir.path_join(new_folder_name)
		_update_after_path_change()
	elif create_folder_button.button_pressed and not _sync_path_to_name:
		# set _sync_path_to_name to true if new folder name matches
		# the existing folder name now.
		var existing_project_folder_name := _get_project_folder_name()
		_sync_path_to_name = new_folder_name == existing_project_folder_name
	
	if new_name.length() == 0:
		_set_status(StatusIcon.StatusType.Error, "Project must have a name.")

	create_button.disabled = status_icon.status == StatusIcon.StatusType.Error

func _update_after_path_change() -> void:
	var new_path := project_path_line_edit.text as String
	if new_path.is_relative_path():
		_set_status(StatusIcon.StatusType.Error, "The project path can't be relative.")
	elif DirAccess.dir_exists_absolute(new_path):
		if Utils.is_dir_empty(new_path):
			_set_status(StatusIcon.StatusType.Success, "The existing empty folder will be used.")
		else:
			_set_status(StatusIcon.StatusType.Warning, "The project folder isn't empty.\nHighly recommend that you select and empty folder.")
	elif create_folder_button.button_pressed:
		_set_status(StatusIcon.StatusType.Success, "The project folder will be automatically created.")
	else:
		_set_status(StatusIcon.StatusType.Error, "The project folder must exist.")
	
	# set _sync_path_to_name to false if path was manually edited
	# to something different than what the automatically generated
	# folder name would be.
	var new_project_folder_name := _get_project_folder_name()
	var project_name_as_folder_name := _project_name_to_folder_name(project_name_line_edit.text)
	_sync_path_to_name = new_project_folder_name == project_name_as_folder_name
	
	create_button.disabled = status_icon.status == StatusIcon.StatusType.Error

func _on_project_name_line_edit_text_changed(_new_name: String) -> void:
	_update_after_name_change()

func _on_project_path_line_edit_text_changed(_new_text: String) -> void:
	_update_after_path_change()

func _on_browse_dialog_dir_selected(dir: String) -> void:
	if create_folder_button.button_pressed:
		_project_parent_dir = dir
		var project_name_as_folder := _project_name_to_folder_name(project_name_line_edit.text)
		project_path_line_edit.text = _project_parent_dir.path_join(project_name_as_folder)
	else:
		_project_parent_dir = dir.get_base_dir()
		project_path_line_edit.text = dir
	_update_after_path_change()

func _on_create_folder_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		var project_name_as_folder := _project_name_to_folder_name(project_name_line_edit.text)
		project_path_line_edit.text = _project_parent_dir.path_join(project_name_as_folder)
	else:
		project_path_line_edit.text = _project_parent_dir
	_update_after_path_change()

func _on_browse_button_pressed() -> void:
	browse_dialog.current_path = _project_parent_dir.path_join("/")
	browse_dialog.popup_centered()

func _on_close_requested() -> void:
	hide()

func _on_cancel_button_pressed() -> void:
	hide()

func _on_create_button_pressed() -> void:
	create_requested.emit(project_name_line_edit.text, project_path_line_edit.text)
	hide()
