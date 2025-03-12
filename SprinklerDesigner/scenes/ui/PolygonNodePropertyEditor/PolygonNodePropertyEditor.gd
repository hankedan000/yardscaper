extends GridContainer

@onready var user_label_lineedit := $UserLabelLineEdit
@onready var color_picker := $ColorPicker
@onready var area_lineedit := $AreaLineEdit

var poly_node : PolygonNode = null:
	set(obj):
		if obj == poly_node:
			return # ignore duplicate sets
		
		# disconnect signal handler from old poly_node
		if poly_node != null:
			poly_node.property_changed.disconnect(_on_poly_node_property_changed)
		
		if obj is PolygonNode:
			obj.property_changed.connect(_on_poly_node_property_changed)
			_sync_ui_to_properties(obj)
		
		poly_node = obj

var _ui_needs_sync = false
var _ignore_internal_edits = false

func _process(_delta):
	if _ui_needs_sync:
		_sync_ui_to_properties(poly_node)

func queue_ui_sync():
	_ui_needs_sync = true

func _sync_ui_to_properties(node: PolygonNode):
	if node == null:
		_ui_needs_sync = false
		return
	
	_ignore_internal_edits = true
	user_label_lineedit.text = node.user_label
	color_picker.color = node.color
	area_lineedit.text = "%0.0f sq. ft" % node.get_area_ft()
	_ignore_internal_edits = false
	_ui_needs_sync = false

func _on_poly_node_property_changed(_property, _old_value, _new_value):
	if poly_node is PolygonNode:
		queue_ui_sync()

func _on_user_label_line_edit_text_submitted(new_text: String) -> void:
	if poly_node is PolygonNode and not _ignore_internal_edits:
		poly_node.user_label = new_text

func _on_color_picker_color_changed(color):
	if poly_node is PolygonNode and not _ignore_internal_edits:
		poly_node.color = color
