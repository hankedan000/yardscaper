extends Window

signal save()
signal discard()
signal cancel()

func _on_save_button_pressed():
	emit_signal('save')

func _on_discard_button_pressed():
	emit_signal('discard')

func _on_cancel_button_pressed():
	emit_signal('cancel')
	hide()

func _on_close_requested():
	_on_cancel_button_pressed()
