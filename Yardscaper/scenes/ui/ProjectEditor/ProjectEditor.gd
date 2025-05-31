extends PanelContainer
class_name ProjectEditor

enum ProjectMenuIDs {
	Open = 1,
	Save = 2,
	SaveAs = 3,
	ExportToImage = 4,
	QuitToProjectManager = 5
}

enum EditMenuIDs {
	Undo = 1,
	Redo = 2
}

enum HelpMenuIDs {
	Help = 1,
	About = 2
}

enum CloseType {
	None           = 0,
	ProjectManager = 1, # close project and goto project manager window
	Application    = 2  # close application entirely
}

@onready var open_dialog := $OpenDialog
@onready var save_as_dialog := $SaveAsDialog
@onready var unsaved_changes_dialog := $UnsavedChangesDialog
@onready var export_to_img_dialog := $ExportToImageDialog
@onready var about_dialog := $AboutDialog
@onready var help_dialog := $HelpDialog
@onready var proj_menu := $VBoxContainer/MenuBar/Project
@onready var edit_menu := $VBoxContainer/MenuBar/Edit
@onready var proj_tabs := $VBoxContainer/ProjectTabs
@onready var layout_tab := $VBoxContainer/ProjectTabs/Layout

var _requested_close_type = CloseType.None
var _active_undo_redo_ctrl : UndoController = null:
	set(value):
		if _active_undo_redo_ctrl:
			_active_undo_redo_ctrl.history_changed.disconnect(_on_undo_redo_ctrl_history_changed)
		if value is UndoController:
			value.history_changed.connect(_on_undo_redo_ctrl_history_changed)
		_active_undo_redo_ctrl = value
		_update_undo_redo_enabled(_active_undo_redo_ctrl)

func _ready():
	# manage window close request ourselve so we can ask to save before closing
	get_tree().set_auto_accept_quit(false)
	
	TheProject.connect('opened', _on_TheProject_opened)
	TheProject.connect('has_edits_changed', _on_TheProject_has_edits_changed)
	_update_window_title()
	
	# set save menu item shortcut to Ctrl + S
	_set_menu_item_shortcut(
		proj_menu, ProjectMenuIDs.Save,
		Utils.create_shortcut(KEY_S, true))
	# set save_as menu item shortcut to Ctrl + Shift + S
	_set_menu_item_shortcut(
		proj_menu, ProjectMenuIDs.SaveAs,
		Utils.create_shortcut(KEY_S, true, true))
	# set undo menu item shortcut to Ctrl + Z
	_set_menu_item_shortcut(
		edit_menu, EditMenuIDs.Undo,
		Utils.create_shortcut(KEY_Z, true))
	# set redo menu item shortcut to Ctrl + Shift + Z
	_set_menu_item_shortcut(
		edit_menu, EditMenuIDs.Redo,
		Utils.create_shortcut(KEY_Z, true, true))
	
	# trick to get undo/redo history active from startup
	_on_project_tabs_tab_changed(proj_tabs.current_tab)

func _request_close(type: CloseType):
	TheProject.save_preferences()
	_requested_close_type = type
	if TheProject.has_edits:
		unsaved_changes_dialog.popup_centered()
	else:
		_do_close(type)

func _do_close(type: CloseType):
	match type:
		CloseType.None:
			pass # nothing to do
		CloseType.ProjectManager:
			TheProject.reset()
			Globals.main.open_project_manager()
		CloseType.Application:
			get_tree().quit()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_request_close(CloseType.Application)

func _set_menu_item_shortcut(menu: PopupMenu, id: int, shortcut: Shortcut):
	menu.set_item_shortcut(menu.get_item_index(id), shortcut)

func _update_window_title():
	var title : String = ProjectUtils.get_app_name()
	if len(TheProject.project_name) > 0:
		var has_edits_label = "* " if TheProject.has_edits else ""
		title = "%s %s- %s" % [TheProject.project_name, has_edits_label, ProjectUtils.get_app_name()]
	DisplayServer.window_set_title(title)

func _request_save_as():
	_on_project_id_pressed(ProjectMenuIDs.SaveAs)

func _update_undo_redo_enabled(undo_redo_ctrl):
	var undo_disabled = true
	var redo_disabled = true
	if undo_redo_ctrl is UndoController:
		undo_disabled = not undo_redo_ctrl.has_undo()
		redo_disabled = not undo_redo_ctrl.has_redo()
	edit_menu.set_item_disabled(edit_menu.get_item_index(EditMenuIDs.Undo), undo_disabled)
	edit_menu.set_item_disabled(edit_menu.get_item_index(EditMenuIDs.Redo), redo_disabled)

func _on_project_id_pressed(id):
	match id:
		ProjectMenuIDs.Open:
			open_dialog.popup_centered()
		ProjectMenuIDs.Save:
			TheProject.save()
		ProjectMenuIDs.SaveAs:
			save_as_dialog.popup_centered()
		ProjectMenuIDs.ExportToImage:
			export_to_img_dialog.popup_centered()
		ProjectMenuIDs.QuitToProjectManager:
			_request_close(CloseType.ProjectManager)

func _on_save_as_dialog_dir_selected(dir: String):
	if TheProject.save_as(dir):
		# 'save as' can be requested if user hasn't saved a new project yet, 
		# but requested to close the window. this is where the final close
		# gets performed.
		_do_close(_requested_close_type)

func _on_open_dialog_dir_selected(dir):
	TheProject.open(dir)

func _on_TheProject_opened():
	_update_window_title()

func _on_TheProject_has_edits_changed(_has_edits):
	_update_window_title()

func _on_unsaved_changes_dialog_save():
	if len(TheProject.project_path) > 0:
		TheProject.save()
		_do_close(_requested_close_type)
	else:
		# need to request user where to save project to
		_request_save_as()

func _on_unsaved_changes_dialog_cancel():
	_requested_close_type = CloseType.None

func _on_unsaved_changes_dialog_discard():
	TheProject.discard_unsaved_edits() # removes auto-save file
	_do_close(_requested_close_type)

func _on_project_tabs_tab_changed(tab):
	var tab_title = proj_tabs.get_tab_title(tab)
	var next_undo_redo_ctrl = null
	match tab_title:
		"Layout":
			next_undo_redo_ctrl = layout_tab.undo_redo_ctrl
		"BOM List":
			pass
		_:
			push_warning("unsupported tab title '%s' in _on_project_tabs_tab_changed()" % [tab_title])
	
	_active_undo_redo_ctrl = next_undo_redo_ctrl

func _on_undo_redo_ctrl_history_changed():
	_update_undo_redo_enabled(_active_undo_redo_ctrl)

func _on_edit_id_pressed(id):
	match id:
		EditMenuIDs.Undo:
			_active_undo_redo_ctrl.undo()
		EditMenuIDs.Redo:
			_active_undo_redo_ctrl.redo()
		_:
			push_warning("unhandled press event for edit menu id %d" % [id])

func _on_help_id_pressed(id):
	match id:
		HelpMenuIDs.Help:
			help_dialog.popup_centered()
		HelpMenuIDs.About:
			about_dialog.popup_centered()
	
func _on_export_to_image_dialog_export(view_opt, _zone: int, filepath: String):
	var img = null
	match view_opt:
		Globals.ViewOptions.Current:
			img = layout_tab.world_view.get_image_of_current_view()
		_:
			push_warning("unsupported view export option '%s'" % Globals.ViewOptions.keys()[view_opt])
			return
	
	if img is Image:
		var ext = filepath.get_extension().to_lower()
		if ext == 'png':
			img.save_png(filepath)
		elif ext in ['jpg', 'jpeg']:
			img.save_jpg(filepath)
		elif ext == 'webp':
			img.save_webp(filepath)
		else:
			push_warning("unsupported image file extension '%s'" % ext)
