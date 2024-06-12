extends PanelContainer

enum ProjectMenuIDs {
	New = 2,
	Open = 3,
	Save = 0,
	SaveAs = 1
}

@onready var open_dialog := $OpenDialog
@onready var save_as_dialog := $SaveAsDialog

var project_path := ""

func save(dir: String):
	return TheProject.save(dir.path_join("project.json"))

func open(dir: String):
	return TheProject.load(dir.path_join("project.json"))

func _on_project_id_pressed(id):
	match id:
		ProjectMenuIDs.Open:
			open_dialog.popup_centered()
		ProjectMenuIDs.Save:
			save(project_path)
		ProjectMenuIDs.SaveAs:
			save_as_dialog.popup_centered()

func _on_save_as_dialog_dir_selected(dir: String):
	if save(dir):
		project_path = dir

func _on_open_dialog_dir_selected(dir):
	if open(dir):
		project_path = dir
