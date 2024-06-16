extends PanelContainer

enum ProjectMenuIDs {
	New = 2,
	Open = 3,
	Save = 0,
	SaveAs = 1
}

@onready var open_dialog := $OpenDialog
@onready var save_as_dialog := $SaveAsDialog
@onready var unsaved_changes_dialog = $UnsavedChangesDialog

var _close_requested = false # set true if window close was requested

func _ready():
	# manage window close request ourselve so we can ask to save before closing
	get_tree().set_auto_accept_quit(false)
	
	TheProject.connect('opened', _on_TheProject_opened)
	TheProject.connect('has_edits_changed', _on_TheProject_has_edits_changed)
	_update_window_title()
	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_close_requested = true
		if TheProject.has_edits:
			unsaved_changes_dialog.popup_centered()
		else:
			get_tree().quit() # nothing to save, so quit now!

func _update_window_title():
	const BASE_TITLE = "Sprinkler Designer"
	var project_path = TheProject.project_path
	var title = BASE_TITLE
	if len(project_path) > 0:
		var has_edits_label = "* " if TheProject.has_edits else ""
		title = "%s %s- %s" % [project_path.get_file(), has_edits_label, BASE_TITLE]
	DisplayServer.window_set_title(title)

func _request_save_as():
	_on_project_id_pressed(ProjectMenuIDs.SaveAs)

func _on_project_id_pressed(id):
	match id:
		ProjectMenuIDs.New:
			TheProject.reset()
		ProjectMenuIDs.Open:
			open_dialog.popup_centered()
		ProjectMenuIDs.Save:
			TheProject.save()
		ProjectMenuIDs.SaveAs:
			save_as_dialog.popup_centered()

func _on_save_as_dialog_dir_selected(dir: String):
	if TheProject.save_as(dir):
		# 'save as' can be requested if user hasn't saved a new project yet, 
		# but requested to close the window. this is where the final close
		# gets performed.
		if _close_requested:
			get_tree().quit()

func _on_open_dialog_dir_selected(dir):
	TheProject.open(dir)

func _on_TheProject_opened():
	_update_window_title()

func _on_TheProject_has_edits_changed(_has_edits):
	_update_window_title()

func _on_unsaved_changes_dialog_save():
	if len(TheProject.project_path) > 0:
		TheProject.save()
		get_tree().quit()
	else:
		# need to request user where to save project to
		_request_save_as()

func _on_unsaved_changes_dialog_cancel():
	_close_requested = false

func _on_unsaved_changes_dialog_discard():
	get_tree().quit()
