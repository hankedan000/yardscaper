extends PanelContainer

@onready var sprinkler_properties := $Layout/LayoutToolbar/SprinklerProperties
@onready var rot_spinbox := $Layout/LayoutToolbar/SprinklerProperties/RotationSpinBox
@onready var sweep_spinbox := $Layout/LayoutToolbar/SprinklerProperties/SweepSpinbox
@onready var world_viewport_container := $Layout/WorldViewportContainer
@onready var world_viewport := $Layout/WorldViewportContainer/WorldViewport
@onready var pan_zoom_ctrl := $Layout/WorldViewportContainer/WorldViewport/PanZoomController

var selected_sprinkler : Sprinkler = null :
	set(value):
		# release indicator for selectr spinkler
		if selected_sprinkler:
			selected_sprinkler.show_indicator = false
		
		selected_sprinkler = value
		
		if selected_sprinkler:
			selected_sprinkler.show_indicator = true
			rot_spinbox.value = selected_sprinkler.rotation_degrees
			sweep_spinbox.value = selected_sprinkler.sweep_deg
		sprinkler_properties.visible = selected_sprinkler != null

func _ready():
	sprinkler_properties.hide()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)
					
func _handle_click(click_pos: Vector2):
	# ignore clicks that are outside the world viewpoint
	if not world_viewport_container.get_global_rect().has_point(click_pos):
		return
	
	var click_pos_within_viewport = click_pos - world_viewport_container.global_position
	var pos_in_world = pan_zoom_ctrl.get_xy_position_in_world(click_pos_within_viewport)
	var smallest_dist = null
	var nearest_sprink = null
	for child in world_viewport.get_children():
		if child is Sprinkler:
			var dist = (child.position - pos_in_world).length()
			if dist > Utils.ft_to_px(child.max_dist_ft):
				continue
			
			if not nearest_sprink or (nearest_sprink and dist < smallest_dist):
				smallest_dist = dist
				nearest_sprink = child
	
	selected_sprinkler = nearest_sprink

func _on_rotation_spin_box_value_changed(rot_deg):
	if selected_sprinkler:
		selected_sprinkler.rotation_degrees = rot_deg

func _on_sweep_spinbox_value_changed(sweep_deg):
	if selected_sprinkler:
		selected_sprinkler.sweep_deg = sweep_deg
