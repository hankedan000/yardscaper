extends PanelContainer

@onready var properties_list          := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList
@onready var user_label_lineedit      := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/UserLabelLineEdit
@onready var rot_spinbox              := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/RotationSpinBox
@onready var sweep_spinbox            := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/SweepSpinBox
@onready var manufacturer_lineedit    := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/ManufacturerLineEdit
@onready var model_lineedit           := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/ModelLineEdit
@onready var min_dist_spinbox         := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/MinDistanceSpinBox
@onready var max_dist_spinbox         := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/MaxDistanceSpinBox
@onready var dist_spinbox             := $HSplitContainer/PropertiesPanel/VBox/ScrollContainer/PropertiesList/DistanceSpinBox

@onready var world_viewport_container := $HSplitContainer/Layout/World/ViewportContainer
@onready var world_viewport           := $HSplitContainer/Layout/World/ViewportContainer/Viewport
@onready var pan_zoom_ctrl            := $HSplitContainer/Layout/World/ViewportContainer/Viewport/PanZoomController
@onready var mouse_pos_label          := $HSplitContainer/Layout/World/MousePosLabel

@onready var remove_sprinkler_button  := $HSplitContainer/Layout/LayoutToolbar/RemoveSprinkler

@export var SprinklerScene : PackedScene = null

enum Mode {
	Idle,
	AddSprinkler
}

var mode = Mode.Idle
var sprinkler_to_add : Sprinkler = null

var selected_sprinkler : Sprinkler = null :
	set(sprink):
		# release indicator for selectr spinkler
		if selected_sprinkler:
			selected_sprinkler.show_indicator = false
			selected_sprinkler.show_min_dist = false
			selected_sprinkler.show_max_dist = false
		
		# set to null first so property pane signals doesn't edit the
		# previously selected sprinkler while we're loading in the new
		# properties into the pane
		selected_sprinkler = null
		
		if sprink:
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
		
		selected_sprinkler = sprink
		properties_list.visible = selected_sprinkler != null
		remove_sprinkler_button.disabled = selected_sprinkler == null

var _held_sprinkler : Sprinkler = null

func _ready():
	TheProject.sprinkler_changed.connect(_on_project_sprinkler_changed)
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
			elif _held_sprinkler:
				if not _held_sprinkler.moving():
					_held_sprinkler.start_move()
				_held_sprinkler.position = pos_in_world_px

func _is_over_sprinkler(pos_in_world_px: Vector2, sprink: Sprinkler) -> bool:
	var dist_px = (sprink.position - pos_in_world_px).length()
	return dist_px <= Utils.ft_to_px(sprink.max_dist_ft)

func _handle_left_click(click_pos: Vector2):
	# ignore clicks that are outside the world viewpoint
	if not _is_point_over_world(click_pos):
		return
		
	match mode:
		Mode.Idle:
			var pos_in_world_px = _global_xy_to_pos_in_world(click_pos)
			var smallest_dist_px = null
			var nearest_sprink = null
			for child in world_viewport.get_children():
				if child is Sprinkler:
					var dist_px = (child.position - pos_in_world_px).length()
					if dist_px > Utils.ft_to_px(child.max_dist_ft):
						continue
					
					if not nearest_sprink or (nearest_sprink and dist_px <= smallest_dist_px):
						smallest_dist_px = dist_px
						nearest_sprink = child
			
			if nearest_sprink != null and selected_sprinkler == nearest_sprink:
				_held_sprinkler = selected_sprinkler
				Input.set_default_cursor_shape(Input.CURSOR_MOVE)
			else:
				selected_sprinkler = nearest_sprink
		Mode.AddSprinkler:
			TheProject.add_sprinkler(sprinkler_to_add)
			sprinkler_to_add = null
			mode = Mode.Idle

func _handle_left_click_release():
	if _held_sprinkler:
		if _held_sprinkler.moving():
			_held_sprinkler.finish_move()
		_held_sprinkler = null
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

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

func _on_remove_sprinkler_pressed():
	if selected_sprinkler:
		TheProject.remove_sprinkler(selected_sprinkler)
		selected_sprinkler = null

func _on_project_sprinkler_changed(sprink, change_type):
	var sprink_in_world = sprink.get_parent() == world_viewport
	match change_type:
		TheProject.ChangeType.ADD:
			if not sprink_in_world:
				world_viewport.add_child(sprink)
		TheProject.ChangeType.REMOVE:
			if sprink_in_world:
				world_viewport.remove_child(sprink)

func _on_user_label_line_edit_text_submitted(new_text):
	if selected_sprinkler:
		selected_sprinkler.user_label = new_text

func _on_sweep_spin_box_value_changed(sweep_deg):
	if selected_sprinkler:
		selected_sprinkler.sweep_deg = sweep_deg

func _on_rotation_spin_box_value_changed(rot_deg):
	if selected_sprinkler:
		selected_sprinkler.rotation_degrees = rot_deg

func _on_manufacturer_line_edit_text_submitted(new_text):
	if selected_sprinkler:
		selected_sprinkler.manufacturer = new_text

func _on_model_line_edit_text_submitted(new_text):
	if selected_sprinkler:
		selected_sprinkler.model = new_text

func _on_distance_spin_box_value_changed(value):
	if selected_sprinkler:
		selected_sprinkler.dist_ft = value
