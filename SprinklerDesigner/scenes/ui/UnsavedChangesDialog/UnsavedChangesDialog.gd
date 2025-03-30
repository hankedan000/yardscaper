extends Window

signal save()
signal discard()
signal cancel()

func _on_save_button_pressed():
	save.emit()

func _on_discard_button_pressed():
	discard.emit()

func _on_cancel_button_pressed():
	cancel.emit()
	hide()

func _on_close_requested():
	_on_cancel_button_pressed()
