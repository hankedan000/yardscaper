extends Window

signal project_renamed()

@onready var name_line_edit : LineEdit = $PanelContainer/VBoxContainer/ProjectNameLineEdit
@onready var path_line_edit : LineEdit = $PanelContainer/VBoxContainer/ProjectPathLineEdit

func setup(proj: PreviousProjectItem) -> void:
	name_line_edit.text = proj.get_project_name()
	path_line_edit.text = proj.get_project_path()

func _on_cancel_button_pressed() -> void:
	hide()

func _on_rename_button_pressed() -> void:
	hide()
	# rename the project
	if Project.rename_project(path_line_edit.text, name_line_edit.text):
		project_renamed.emit()

func _on_project_name_line_edit_text_submitted(_new_text: String) -> void:
	_on_rename_button_pressed()
