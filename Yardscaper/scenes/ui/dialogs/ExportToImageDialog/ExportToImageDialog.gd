extends Window

signal export(view_opt: Globals.ViewOptions, zone: int, filepath: String)
signal canceled()

@onready var file_dialog         : FileDialog = $FileDialog
@onready var current_view_button := %CurrentViewCheckBox
@onready var full_view_button := %FullViewCheckBox
@onready var zone_view_button := %ZoneViewCheckBox
@onready var zone_selection := %ZoneSelection
@onready var zone_spinbox := %ZoneSpinBox
@onready var file_lineedit := %FileLineEdit

func _on_cancel_button_pressed():
	canceled.emit()
	hide()

func _on_export_button_pressed():
	var view_opt = Globals.ViewOptions.Current
	if full_view_button.button_pressed:
		view_opt = Globals.ViewOptions.Full
	elif zone_view_button.button_pressed:
		view_opt = Globals.ViewOptions.Zone
	var zone = zone_spinbox.value
	var filename = file_lineedit.text
	
	hide()
	export.emit(view_opt, zone, filename)

func _on_zone_view_check_box_toggled(toggled_on):
	zone_selection.visible = toggled_on

func _on_file_dialog_file_selected(path):
	file_lineedit.text = path

func _on_browse_button_pressed():
	file_dialog.popup_centered()

func _on_about_to_popup() -> void:
	if file_lineedit.text.length() > 0:
		return
	
	var default_file_name := TheProject.project_name + ".jpg"
	var default_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	file_dialog.current_dir = default_dir
	file_dialog.current_file = default_file_name
	file_lineedit.text = default_dir.path_join(default_file_name)

func _on_close_requested() -> void:
	hide()
