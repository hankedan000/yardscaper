extends PanelContainer

@onready var sprinkler_properties     := $Layout/LayoutToolbar/SprinklerProperties
@onready var rot_spinbox              := $Layout/LayoutToolbar/SprinklerProperties/RotationSpinBox
@onready var sweep_spinbox            := $Layout/LayoutToolbar/SprinklerProperties/SweepSpinbox
@onready var world_viewport_container := $Layout/World/ViewportContainer
@onready var world_viewport           := $Layout/World/ViewportContainer/Viewport
@onready var pan_zoom_ctrl            := $Layout/World/ViewportContainer/Viewport/PanZoomController
@onready var mouse_pos_label          := $Layout/World/MousePosLabel

@export var SprinklerScene : PackedScene = null

enum Mode {
	Idle,
	AddSprinkler
}

var mode = Mode.Idle
var sprinkler_to_add : Sprinkler = null

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
	TheProject.sprinkler_changed.connect(_on_project_sprinkler_changed)
	sprinkler_properties.hide()
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.global_position)
	elif event is InputEventMouseMotion:
		var evt_global_pos = event.global_position
		if _is_point_over_world(evt_global_pos):
			var pos_in_world_xy = _global_xy_to_pos_in_world(evt_global_pos)
			var pos_in_world_ft = Utils.px_to_ft_vec(pos_in_world_xy)
			var x_pretty = Utils.pretty_dist(pos_in_world_ft.x)
			var y_pretty = Utils.pretty_dist(pos_in_world_ft.y)
			mouse_pos_label.text = "%s, %s" % [x_pretty, y_pretty]
			
			if sprinkler_to_add:
				sprinkler_to_add.position = pos_in_world_xy
					
func _handle_click(click_pos: Vector2):
	# ignore clicks that are outside the world viewpoint
	if not _is_point_over_world(click_pos):
		return
		
	match mode:
		Mode.Idle:
			var pos_in_world = _global_xy_to_pos_in_world(click_pos)
			var smallest_dist = null
			var nearest_sprink = null
			for child in world_viewport.get_children():
				if child is Sprinkler:
					var dist = (child.position - pos_in_world).length()
					if dist > Utils.ft_to_px(child.max_dist_ft):
						continue
					
					if not nearest_sprink or (nearest_sprink and dist <= smallest_dist):
						smallest_dist = dist
						nearest_sprink = child
			
			selected_sprinkler = nearest_sprink
		Mode.AddSprinkler:
			TheProject.add_sprinkler(sprinkler_to_add)
			sprinkler_to_add = null
			mode = Mode.Idle

func _is_point_over_world(global_pos: Vector2) -> bool:
	return world_viewport_container.get_global_rect().has_point(global_pos)

func _global_xy_to_pos_in_world(global_pos: Vector2) -> Vector2:
	var pos_rel_to_world = global_pos - world_viewport_container.global_position
	return pan_zoom_ctrl.get_xy_position_in_world(pos_rel_to_world)

func _on_rotation_spin_box_value_changed(rot_deg):
	if selected_sprinkler:
		selected_sprinkler.rotation_degrees = rot_deg

func _on_sweep_spinbox_value_changed(sweep_deg):
	if selected_sprinkler:
		selected_sprinkler.sweep_deg = sweep_deg

func _on_add_sprinkler_pressed():
	sprinkler_to_add = SprinklerScene.instantiate()
	sprinkler_to_add.user_label = "Sprinkler%d" % TheProject.sprinklers.size()
	sprinkler_to_add.position = _global_xy_to_pos_in_world(get_global_mouse_position())
	world_viewport.add_child(sprinkler_to_add)
	mode = Mode.AddSprinkler

func _on_project_sprinkler_changed(sprink, change_type):
	var sprink_in_world = sprink.get_parent() == world_viewport
	match change_type:
		TheProject.ChangeType.ADD:
			if not sprink_in_world:
				world_viewport.add_child(sprink)
		TheProject.ChangeType.REMOVE:
			if sprink_in_world:
				world_viewport.remove_child(sprink)
