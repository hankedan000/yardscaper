extends PanelContainer
class_name BootMenu

@export var PreviousItemScene : PackedScene = null

@onready var previous_projects := $VBoxContainer/MainPanel/VBoxContainer/HBoxContainer/ScrollContainer/PreviousProjects
@onready var open_project_dialog := $OpenProjectDialog
@onready var create_project_dialog := $CreateProjectDialog
@onready var rename_project_dialog := $RenameProjectDialog
@onready var open_button := $VBoxContainer/MainPanel/VBoxContainer/HBoxContainer/VBoxContainer/OpenButton
@onready var rename_button := $VBoxContainer/MainPanel/VBoxContainer/HBoxContainer/VBoxContainer/RenameButton
@onready var remove_button := $VBoxContainer/MainPanel/VBoxContainer/HBoxContainer/VBoxContainer/RemoveButton
@onready var version_label := $VBoxContainer/BottomBar/VersionLabel

var selected_project_item : PreviousProjectItem = null:
	set(value):
		selected_project_item = value
		if not is_inside_tree():
			await ready
		
		var project_is_invalid = false
		if selected_project_item == null:
			project_is_invalid = true
		elif selected_project_item.is_missing:
			project_is_invalid = true
		open_button.disabled = project_is_invalid
		rename_button.disabled = project_is_invalid
		remove_button.disabled = selected_project_item == null

func _ready():
	_reload_previous_projects()
	version_label.text = "v%s" % Globals.THIS_VERSION

func _reload_previous_projects() -> void:
	selected_project_item = null # make sure button start disabled
	
	while previous_projects.get_child_count() > 0:
		previous_projects.remove_child(previous_projects.get_child(0))
	
	for project_path in Globals.get_recent_projects():
		var new_item := PreviousItemScene.instantiate() as PreviousProjectItem
		new_item.setup(project_path)
		new_item.selected.connect(_on_recent_project_selected)
		new_item.opened.connect(_on_recent_project_opened)
		previous_projects.add_child(new_item)

func _on_create_project_button_pressed():
	create_project_dialog.popup_centered()

func _on_import_project_button_pressed():
	open_project_dialog.popup_centered()

func _on_recent_project_selected(item: PreviousProjectItem):
	selected_project_item = item

func _on_recent_project_opened(item: PreviousProjectItem):
	Globals.main.open_project_editor(item.get_project_path())

func _on_open_project_dialog_dir_selected(dir: String) -> void:
	if Project.get_quick_info(dir) != null:
		Globals.add_recent_project(dir)
		_reload_previous_projects()

func _on_create_project_dialog_create_requested(_project_name: String, project_path: String) -> void:
	var new_project := Project.new()
	if new_project.save_as(project_path):
		Globals.main.open_project_editor(project_path)

func _on_rename_project_dialog_project_renamed() -> void:
	_reload_previous_projects()

func _on_open_button_pressed() -> void:
	Globals.main.open_project_editor(selected_project_item.get_project_path())

func _on_rename_button_pressed() -> void:
	rename_project_dialog.setup(selected_project_item)
	rename_project_dialog.popup_centered()

func _on_remove_button_pressed() -> void:
	var path_to_remove := selected_project_item.get_project_path()
	Globals.remove_recent_project(path_to_remove)
	_reload_previous_projects()
