extends Window

signal yes()
signal no()
signal cancel()

func _on_close_requested():
	hide()
	cancel.emit()

func _on_yes_button_pressed() -> void:
	hide()
	yes.emit()

func _on_no_button_pressed() -> void:
	hide()
	no.emit()
