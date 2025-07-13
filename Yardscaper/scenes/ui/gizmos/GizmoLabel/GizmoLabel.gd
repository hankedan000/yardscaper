@tool
extends Gizmo
class_name GizmoLabel

@export var keep_center : bool = true
@export var text : String = "":
	set(value):
		if is_instance_valid(_label):
			_label.text = value
			if keep_center:
				center_text()
		else:
			text = value
	get():
		if is_instance_valid(_label):
			return _label.text
		return text

@onready var _label : Label = $Label

func _ready() -> void:
	_label.text = text
	if keep_center:
		center_text()

func get_label() -> Label:
	return _label

func center_text() -> void:
	var text_size := Utils.get_label_text_size(_label, _label.text, false)
	_label.position = Vector2() - (text_size / 2.0)
