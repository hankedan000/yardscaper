@tool
extends Gizmo
class_name GizmoLabel

@export var text : String = "":
	set(value):
		if is_instance_valid(_label):
			_label.text = value
			_apply_text_update()
		else:
			text = value
	get():
		if is_instance_valid(_label):
			return _label.text
		return text

@export_enum("Top", "Center", "Bottom", "Fill")
var vert_alignment : int = VERTICAL_ALIGNMENT_CENTER:
	set(value):
		if value == VERTICAL_ALIGNMENT_FILL:
			push_warning("VERTICAL_ALIGNMENT_FILL is not supported")
			return
		vert_alignment = value
		_apply_vert_alignment()

@export_enum("Left", "Center", "Right", "Fill")
var horz_alignment : int = HORIZONTAL_ALIGNMENT_CENTER:
	set(value):
		if value == HORIZONTAL_ALIGNMENT_FILL:
			push_warning("HORIZONTAL_ALIGNMENT_FILL is not supported")
			return
		horz_alignment = value
		_apply_horz_alignment()

# the label will be automatically hidden if the width of the label becomes
# wider than this value in pixels. it will be revealed again if it becomes
# smaller than the limit. a negative value will disable the feature.
var hide_if_wider_than : float = -1.0:
	set(value):
		hide_if_wider_than = value
		_try_auto_hide()

@onready var _label : Label = $Label

var _local_text_size : Vector2 = Vector2()
var _global_text_size : Vector2 = Vector2()

func _ready() -> void:
	_apply_text_update()

func get_label() -> Label:
	return _label

func on_zoom_changed(new_zoom: float, inv_scale: Vector2) -> void:
	super.on_zoom_changed(new_zoom, inv_scale)
	_apply_text_update()

func _apply_vert_alignment() -> void:
	if ! is_instance_valid(_label):
		return
	
	var offset : float = 0.0
	match vert_alignment:
		VERTICAL_ALIGNMENT_CENTER:
			offset = _local_text_size.y / -2.0
		VERTICAL_ALIGNMENT_TOP:
			offset = 0.0
		VERTICAL_ALIGNMENT_BOTTOM:
			offset = _local_text_size.y * -1.0
	_label.position.y = offset

func _apply_horz_alignment() -> void:
	if ! is_instance_valid(_label):
		return
	
	var offset : float = 0.0
	match horz_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			offset = _local_text_size.x / -2.0
		HORIZONTAL_ALIGNMENT_LEFT:
			offset = 0.0
		HORIZONTAL_ALIGNMENT_RIGHT:
			offset = _local_text_size.x * -1.0
	_label.position.x = offset

func _apply_text_update() -> void:
	_local_text_size = Utils.get_label_text_size(_label, _label.text, false)
	_global_text_size = _local_text_size * scale
	_try_auto_hide()
	_apply_vert_alignment()
	_apply_horz_alignment()

func _try_auto_hide() -> void:
	if ! is_instance_valid(_label):
		return
	elif hide_if_wider_than < 0.0:
		return
	
	_label.visible = _global_text_size.x < hide_if_wider_than
