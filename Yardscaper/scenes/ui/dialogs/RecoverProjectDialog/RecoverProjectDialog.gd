extends Window

signal yes()
signal no()
signal cancel()

func _on_close_requested():
	cancel.emit()
	hide()

func _on_yes_button_pressed() -> void:
	yes.emit()
	hide()

func _on_no_button_pressed() -> void:
	no.emit()
	hide()
