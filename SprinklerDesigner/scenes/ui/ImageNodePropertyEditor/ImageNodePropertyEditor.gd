extends GridContainer

@onready var width_spinbox  := $WidthSpinBox
@onready var height_spinbox := $HeightSpinBox

var img_node : ImageNode = null:
	set(obj):
		if obj == img_node:
			return # ignore duplicate sets
		
		# disconnect signal handler from old img_node
		if img_node != null:
			img_node.property_changed.disconnect(_on_img_node_property_changed)
		
		if obj is ImageNode:
			obj.property_changed.connect(_on_img_node_property_changed)
			_sync_ui_to_properties(obj)
		
		img_node = obj

func _sync_ui_to_properties(node: ImageNode):
	width_spinbox.value = node.width_ft
	height_spinbox.value = node.height_ft

func _on_width_spin_box_value_changed(value):
	if img_node is ImageNode:
		img_node.width_ft = value

func _on_height_spin_box_value_changed(value):
	if img_node is ImageNode:
		img_node.height_ft = value

func _on_img_node_property_changed(_property, _old_value, _new_value):
	if img_node is ImageNode:
		_sync_ui_to_properties(img_node)
