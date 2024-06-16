extends PanelContainer

@onready var img_dialog               := $ImgDialog

@onready var properties_list          := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList
@onready var user_label_lineedit      := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/UserLabelLineEdit
@onready var rot_spinbox              := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/RotationSpinBox
@onready var sweep_spinbox            := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/SweepSpinBox
@onready var manufacturer_lineedit    := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/ManufacturerLineEdit
@onready var model_lineedit           := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/ModelLineEdit
@onready var min_dist_spinbox         := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/MinDistanceSpinBox
@onready var max_dist_spinbox         := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/MaxDistanceSpinBox
@onready var dist_spinbox             := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/DistanceSpinBox

@onready var add_img_button           := $HSplitContainer/Layout/LayoutToolbar/AddImage

@onready var world_viewport_container := $HSplitContainer/Layout/World/ViewportContainer
@onready var world_viewport           := $HSplitContainer/Layout/World/ViewportContainer/Viewport
@onready var pan_zoom_ctrl            := $HSplitContainer/Layout/World/ViewportContainer/Viewport/PanZoomController
@onready var mouse_pos_label          := $HSplitContainer/Layout/World/MousePosLabel

@onready var remove_button            := $HSplitContainer/Layout/LayoutToolbar/RemoveButton

@export var SprinklerScene : PackedScene = null

enum Mode {
	Idle,
	AddSprinkler
}

var mode = Mode.Idle
var sprinkler_to_add : Sprinkler = null
var undo_redo_ctrl := UndoRedoController.new()

var selected_obj = null :
	set(obj):
		if obj == selected_obj:
			return # ignore duplicate sets
		
		print("selected_obj = %s" % [obj])
		if selected_obj != null:
			_on_release_selected_obj(selected_obj)
			selected_obj = null
		
		if obj is Sprinkler:
			_on_sprinkler_selected(obj)
		elif obj is ImageNode:
			_on_img_node_selected(obj)
		
		selected_obj = obj
		remove_button.disabled = selected_obj == null

# MoveableNode2D that's held during a drag/move operation
var _held_objs = []
var _mouse_move_start_pos_px = null

func _ready():
	TheProject.node_changed.connect(_on_TheProject_node_changed)
	TheProject.opened.connect(_on_TheProject_opened)
	TheProject.closed.connect(_on_TheProject_closed)
	properties_list.visible = false
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_left_click(event.global_position)
			else:
				_handle_left_click_release()
	elif event is InputEventMouseMotion:
		var evt_global_pos = event.global_position
		if _is_point_over_world(evt_global_pos):
			var pos_in_world_px = _global_xy_to_pos_in_world(evt_global_pos)
			var pos_in_world_ft = Utils.px_to_ft_vec(pos_in_world_px)
			var x_pretty = Utils.pretty_dist(pos_in_world_ft.x)
			var y_pretty = Utils.pretty_dist(pos_in_world_ft.y)
			mouse_pos_label.text = "%s, %s" % [x_pretty, y_pretty]
			
			if sprinkler_to_add:
				sprinkler_to_add.position = pos_in_world_px
			elif len(_held_objs) > 0:
				_handle_held_obj_move(pos_in_world_px)

func _handle_left_click(click_pos: Vector2):
	# ignore clicks that are outside the world viewpoint
	if not _is_point_over_world(click_pos):
		return
		
	match mode:
		Mode.Idle:
			var pos_in_world_px = _global_xy_to_pos_in_world(click_pos)
			var smallest_dist_px = null
			var nearest_sprink = null
			var clicked_image = null
			for child in world_viewport.get_children():
				if child is Sprinkler:
					var dist_px = (child.position - pos_in_world_px).length()
					if dist_px > Utils.ft_to_px(child.dist_ft):
						continue
					
					if not nearest_sprink or (nearest_sprink and dist_px <= smallest_dist_px):
						smallest_dist_px = dist_px
						nearest_sprink = child
				elif child is ImageNode:
					var img_rect = Rect2(child.position, child.get_img_size())
					if img_rect.has_point(pos_in_world_px):
						clicked_image = child
			
			var next_select_obj = null
			if nearest_sprink:
				next_select_obj = nearest_sprink
			elif clicked_image:
				next_select_obj = clicked_image
			selected_obj = next_select_obj
			
			if selected_obj != null and selected_obj == next_select_obj:
				_add_held_object(selected_obj)
		Mode.AddSprinkler:
			TheProject.add_sprinkler(sprinkler_to_add)
			sprinkler_to_add = null
			mode = Mode.Idle

func _handle_left_click_release():
	if len(_held_objs) > 0:
		for held_obj in _held_objs:
			if held_obj is MoveableNode2D and held_obj.moving():
				held_obj.finish_move()
		_held_objs = []
		_mouse_move_start_pos_px = null
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _handle_held_obj_move(mouse_pos_in_world_px):
	if _mouse_move_start_pos_px == null:
		_mouse_move_start_pos_px = mouse_pos_in_world_px
		Input.set_default_cursor_shape(Input.CURSOR_MOVE)
	var delta_px = mouse_pos_in_world_px - _mouse_move_start_pos_px
	
	for held_obj in _held_objs:
		if held_obj is MoveableNode2D:
			if not held_obj.moving():
				held_obj.start_move()
			held_obj.update_move(delta_px)

func _add_held_object(obj):
	if obj not in _held_objs:
		_held_objs.append(obj)

func _on_release_selected_obj(obj):
	if obj is Sprinkler:
		obj.show_indicator = false
		obj.show_min_dist = false
		obj.show_max_dist = false
	elif obj is ImageNode:
		obj.show_indicator = false

func _on_sprinkler_selected(sprink: Sprinkler):
	sprink.show_indicator = true
	sprink.show_min_dist = true
	sprink.show_max_dist = true
	user_label_lineedit.text = sprink.user_label
	rot_spinbox.value = sprink.rotation_degrees
	sweep_spinbox.value = sprink.sweep_deg
	manufacturer_lineedit.text = sprink.manufacturer
	model_lineedit.text = sprink.model
	min_dist_spinbox.value = sprink.min_dist_ft
	max_dist_spinbox.value = sprink.max_dist_ft
	dist_spinbox.min_value = min_dist_spinbox.value
	dist_spinbox.max_value = max_dist_spinbox.value
	dist_spinbox.value = sprink.dist_ft
	
	properties_list.visible = true

func _on_img_node_selected(img_node: ImageNode):
	img_node.show_indicator = true

func _is_point_over_world(global_pos: Vector2) -> bool:
	return world_viewport_container.get_global_rect().has_point(global_pos)

func _global_xy_to_pos_in_world(global_pos: Vector2) -> Vector2:
	var pos_rel_to_world = global_pos - world_viewport_container.global_position
	return pan_zoom_ctrl.get_xy_position_in_world(pos_rel_to_world)

func _on_add_sprinkler_pressed():
	sprinkler_to_add = SprinklerScene.instantiate()
	sprinkler_to_add.user_label = "Sprinkler%d" % TheProject.sprinklers.size()
	sprinkler_to_add.position = _global_xy_to_pos_in_world(get_global_mouse_position())
	world_viewport.add_child(sprinkler_to_add)
	mode = Mode.AddSprinkler

func _on_add_image_pressed():
	img_dialog.popup_centered()

func _on_remove_button_pressed():
	if selected_obj is Sprinkler:
		TheProject.remove_sprinkler(selected_obj)
	elif selected_obj is ImageNode:
		TheProject.remove_image(selected_obj)
	selected_obj = null

func _on_TheProject_node_changed(obj, change_type, args):
	var obj_in_world = obj.get_parent() == world_viewport
	match change_type:
		TheProject.ChangeType.ADD:
			if not obj_in_world:
				world_viewport.add_child(obj)
		TheProject.ChangeType.REMOVE:
			if obj_in_world:
				world_viewport.remove_child(obj)
		TheProject.ChangeType.PROP_EDIT:
			var prop = args[0]
			var old_value = args[1]
			var new_value = args[2]
			undo_redo_ctrl.push_undo_op(
				UndoRedoController.PropEditUndoRedoOperation.new(
					obj, prop, old_value, new_value)
			)

func _on_TheProject_opened():
	undo_redo_ctrl.reset()
	add_img_button.disabled = false

func _on_TheProject_closed():
	add_img_button.disabled = true

func _on_user_label_line_edit_text_submitted(new_text):
	if selected_obj is Sprinkler:
		selected_obj.user_label = new_text

func _on_sweep_spin_box_value_changed(sweep_deg):
	if selected_obj is Sprinkler:
		selected_obj.sweep_deg = sweep_deg

func _on_rotation_spin_box_value_changed(rot_deg):
	if selected_obj is Sprinkler:
		selected_obj.rotation_degrees = rot_deg

func _on_manufacturer_line_edit_text_submitted(new_text):
	if selected_obj is Sprinkler:
		selected_obj.manufacturer = new_text

func _on_model_line_edit_text_submitted(new_text):
	if selected_obj is Sprinkler:
		selected_obj.model = new_text

func _on_distance_spin_box_value_changed(value):
	if selected_obj is Sprinkler:
		selected_obj.dist_ft = value

func _on_img_dialog_file_selected(path):
	TheProject.add_image(path)
