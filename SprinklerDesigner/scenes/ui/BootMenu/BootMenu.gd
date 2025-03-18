extends PanelContainer
class_name BootMenu

@onready var previous_projects := $VBoxContainer/ScrollContainer/PreviousProjects
@onready var open_project_dialog := $OpenProjectDialog
@onready var new_project_dialog := $NewProjectDialog

func _ready():
	while previous_projects.get_child_count() > 0:
		previous_projects.remove_child(previous_projects.get_child(0))
	
	for project_path in Globals.get_recent_projects():
		var button := Button.new()
		button.text = project_path
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_recent_project_pressed.bind(project_path))
		previous_projects.add_child(button)

func _on_new_project_button_pressed():
	new_project_dialog.popup_centered()

func _on_open_project_button_pressed():
	open_project_dialog.popup_centered()

func _on_recent_project_pressed(project_path: String):
	Globals.main.open_project_editor(project_path)

func _on_open_project_dialog_dir_selected(dir: String) -> void:
	Globals.main.open_project_editor(dir)

func _on_new_project_dialog_dir_selected(dir: String) -> void:
	var new_project := Project.new()
	if new_project.save_as(dir):
		Globals.main.open_project_editor(dir)
