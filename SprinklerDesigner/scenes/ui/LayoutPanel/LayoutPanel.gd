extends PanelContainer

@onready var img_dialog               := $ImgDialog

@onready var sprink_prop_list         := $HSplitContainer/LeftPane/Properties/SprinklerPropertiesList
@onready var img_prop_list            := $HSplitContainer/LeftPane/Properties/ImageNodePropertiesList
@onready var poly_prop_list           := $HSplitContainer/LeftPane/Properties/PolygonNodePropertiesList
@onready var objects_list             := $HSplitContainer/LeftPane/Objects

@onready var add_sprink_button        := $HSplitContainer/Layout/LayoutToolbar/AddSprinkler
@onready var add_img_button           := $HSplitContainer/Layout/LayoutToolbar/AddImage
@onready var add_dist_button          := $HSplitContainer/Layout/LayoutToolbar/AddDistMeasure
@onready var add_poly_button          := $HSplitContainer/Layout/LayoutToolbar/AddPolygon
@onready var remove_button            := $HSplitContainer/Layout/LayoutToolbar/RemoveButton
@onready var show_grid_button         := $HSplitContainer/Layout/LayoutToolbar/ShowGridButton
@onready var world_container          := $HSplitContainer/Layout/World/ViewportContainer
@onready var mouse_pos_label          := $HSplitContainer/Layout/World/MousePosLabel

@export var SprinklerScene : PackedScene = null
@export var DistanceMeasurementScene : PackedScene = null
@export var PolygonScene : PackedScene = null

enum Mode {
	Idle,
	AddSprinkler,
	AddDistMeasureA,
	AddDistMeasureB,
	AddPolygon
}

var mode = Mode.Idle:
	set(value):
		var adds_disabled = value != Mode.Idle
		add_sprink_button.disabled = adds_disabled
		add_img_button.disabled = adds_disabled
		add_dist_button.disabled = adds_disabled
		add_poly_button.disabled = adds_disabled
		mode = value
var sprinkler_to_add : Sprinkler = null
var dist_meas_to_add : DistanceMeasurement = null
var poly_to_add : PolygonNode = null
var undo_redo_ctrl := UndoRedoController.new()

# vars for editing PolygonNode points
var poly_edit_point_idx = 0

var selected_obj = null :
	set(obj):
		if obj == selected_obj:
			return # ignore duplicate sets
		
		if selected_obj != null:
			_on_release_selected_obj(selected_obj)
			selected_obj = null
		
		if obj is Sprinkler:
			_on_sprinkler_selected(obj)
		elif obj is ImageNode:
			_on_img_node_selected(obj)
		elif obj is DistanceMeasurement:
			_on_dist_measurement_selected(obj)
		elif obj is PolygonNode:
			_on_polygon_selected(obj)
		elif obj != null:
			push_warning("unsupported select for obj '%s'" % obj)
		
		selected_obj = obj
		remove_button.disabled = selected_obj == null

# MoveableNode2D that's held during a drag/move operation
var _held_objs = []
var _mouse_move_start_pos_px = null
# object that would be selected next if LEFT mouse button were pressed
var _hovered_obj = null

# ignore property changes while inside of an undo/redo operation.
# we don't want to cyclically re-add an undo operation that will
# redo what we just undid... so many words!
var _ignore_while_in_undo_redo = false

func _ready():
	TheProject.node_changed.connect(_on_TheProject_node_changed)
	TheProject.opened.connect(_on_TheProject_opened)
	TheProject.saved.connect(_on_TheProject_saved)
	TheProject.closed.connect(_on_TheProject_closed)
	sprink_prop_list.visible = false
	img_prop_list.visible = false
	poly_prop_list.visible = false
	objects_list.world = world_container
	world_container.world_object_moved.connect(_on_world_object_moved)
	undo_redo_ctrl.before_a_do.connect(_on_undo_redo_ctrl_before_a_do)
	undo_redo_ctrl.after_a_do.connect(_on_undo_redo_ctrl_after_a_do)
	
	# add shortcuts
	remove_button.shortcut = Utils.create_shortcut(KEY_DELETE)

func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			_cancel_mode() # will only cancel if possible

func _nearest_pickable_obj(pos_in_world: Vector2):
	var smallest_dist_px = null
	var nearest_pick_area = null
	var cursor : Area2D = world_container.cursor
	for pick_area in cursor.get_overlapping_areas():
		var obj_center = pick_area.global_position
		var pick_parent = pick_area.get_parent()
		if pick_parent is PickableNode2D:
			obj_center = pick_parent.get_global_center()
		var dist_px = obj_center.distance_to(pos_in_world)
		if smallest_dist_px == null or dist_px < smallest_dist_px:
			smallest_dist_px = dist_px
			nearest_pick_area = pick_area
	
	if nearest_pick_area:
		return nearest_pick_area.get_parent()
	return null

func _handle_left_click(click_pos: Vector2):
	# ignore clicks that are outside the world viewpoint
	if not _is_point_over_world(click_pos):
		return
		
	var pos_in_world_px = _global_xy_to_pos_in_world(click_pos)
	match mode:
		Mode.Idle:
			selected_obj = _hovered_obj
			if selected_obj:
				_add_held_object(selected_obj)
		Mode.AddSprinkler:
			TheProject.add_object(sprinkler_to_add)
			sprinkler_to_add = null
			mode = Mode.Idle
		Mode.AddDistMeasureA:
			dist_meas_to_add.point_a = pos_in_world_px
			dist_meas_to_add.point_b = pos_in_world_px
			mode = Mode.AddDistMeasureB
		Mode.AddDistMeasureB:
			dist_meas_to_add.point_b = pos_in_world_px
			TheProject.add_object(dist_meas_to_add)
			dist_meas_to_add = null
			mode = Mode.Idle
		Mode.AddPolygon:
			poly_to_add.set_point(poly_edit_point_idx, pos_in_world_px)
			poly_to_add.add_point(pos_in_world_px)
			poly_edit_point_idx = poly_to_add.point_count() - 1

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

func _cancel_mode():
	if mode == Mode.AddSprinkler:
		_cancel_add_sprinkler()
	elif mode in [Mode.AddDistMeasureA, Mode.AddDistMeasureB]:
		_cancel_add_distance()
	elif mode == Mode.AddPolygon:
		_cancel_add_polygon()

func _cancel_add_distance():
	if dist_meas_to_add:
		dist_meas_to_add.queue_free()
		dist_meas_to_add = null
		mode = Mode.Idle

func _cancel_add_sprinkler():
	if sprinkler_to_add:
		sprinkler_to_add.queue_free()
		sprinkler_to_add = null
		mode = Mode.Idle

func _cancel_add_polygon():
	if poly_to_add:
		if poly_edit_point_idx < poly_to_add.point_count():
			poly_to_add.remove_point(poly_edit_point_idx)
		poly_to_add.picked = false
		TheProject.add_object(poly_to_add)
		poly_to_add = null
		mode = Mode.Idle

func _add_held_object(obj):
	if obj not in _held_objs:
		_held_objs.append(obj)

func _on_release_selected_obj(obj):
	if obj is Sprinkler:
		obj.picked = false
		obj.show_min_dist = false
		obj.show_max_dist = false
		sprink_prop_list.visible = false
	elif obj is ImageNode:
		obj.picked = false
		img_prop_list.visible = false
	elif obj is DistanceMeasurement:
		obj.picked = false
	elif obj is PolygonNode:
		obj.picked = false
		poly_prop_list.visible = false
	elif obj != null:
		push_warning("unsupported release for obj '%s'" % obj)

func _on_sprinkler_selected(sprink: Sprinkler):
	sprink_prop_list.sprinkler = sprink
	sprink.picked = true
	sprink.show_min_dist = true
	sprink.show_max_dist = true
	sprink_prop_list.visible = true

func _on_img_node_selected(img_node: ImageNode):
	img_prop_list.img_node = img_node
	img_node.picked = true
	img_prop_list.visible = true

func _on_dist_measurement_selected(meas: DistanceMeasurement):
	meas.picked = true

func _on_polygon_selected(poly: PolygonNode):
	poly_prop_list.poly_node = poly
	poly.picked = true
	poly_prop_list.visible = true

func _is_point_over_world(global_pos: Vector2) -> bool:
	return world_container.get_global_rect().has_point(global_pos)

func _global_xy_to_pos_in_world(global_pos: Vector2) -> Vector2:
	var pos_rel_to_world = global_pos - world_container.global_position
	return world_container.pan_zoom_ctrl.local_pos_to_world(pos_rel_to_world)

func _on_add_sprinkler_pressed():
	sprinkler_to_add = SprinklerScene.instantiate()
	sprinkler_to_add.user_label = TheProject.get_unique_name('Sprinkler')
	sprinkler_to_add.position = _global_xy_to_pos_in_world(get_global_mouse_position())
	world_container.objects.add_child(sprinkler_to_add)
	mode = Mode.AddSprinkler

func _on_add_image_pressed():
	img_dialog.popup_centered()

func _on_add_dist_measure_pressed():
	dist_meas_to_add = DistanceMeasurementScene.instantiate()
	dist_meas_to_add.user_label = TheProject.get_unique_name('DistanceMeasurement')
	world_container.objects.add_child(dist_meas_to_add)
	mode = Mode.AddDistMeasureA

func _on_add_polygon_pressed():
	poly_to_add = PolygonScene.instantiate()
	poly_to_add.user_label = TheProject.get_unique_name('PolygonNode')
	poly_to_add.picked = true
	poly_to_add.add_point(Vector2())
	poly_edit_point_idx = 0
	world_container.objects.add_child(poly_to_add)
	mode = Mode.AddPolygon

class WorldObjectRemoveUndoRedoOperation:
	extends UndoRedoController.UndoRedoOperation
	
	var _world : WorldViewportContainer = null
	var _from_idx = 0
	var _ser_obj = null
	
	func _init(world: WorldViewportContainer, from_idx: int, obj: WorldObject):
		_world = world
		_from_idx = from_idx
		_ser_obj = obj.serialize()
	
	func undo() -> bool:
		var wobj = TheProject.instance_world_obj(_ser_obj)
		if wobj is WorldObject:
			TheProject.add_object(wobj)
			wobj.set_order_in_world(_from_idx)
			return true
		return false
		
	func redo() -> bool:
		var wobj = _world.objects.get_child(_from_idx)
		TheProject.remove_object(wobj)
		return true
		
	func pretty_str() -> String:
		return str({
			'_from_idx' : _from_idx,
			'_ser_obj': _ser_obj
		})

func _on_remove_button_pressed():
	if selected_obj is WorldObject:
		undo_redo_ctrl.push_undo_op(WorldObjectRemoveUndoRedoOperation.new(
			world_container,
			selected_obj.get_order_in_world(),
			selected_obj))
		TheProject.remove_object(selected_obj)
		selected_obj = null

func _on_TheProject_node_changed(obj, change_type, args):
	var obj_in_world = obj in world_container.objects.get_children()
	match change_type:
		TheProject.ChangeType.ADD:
			if not obj_in_world:
				world_container.objects.add_child(obj)
		TheProject.ChangeType.REMOVE:
			if obj_in_world:
				world_container.objects.remove_child(obj)
		TheProject.ChangeType.PROP_EDIT:
			if not _ignore_while_in_undo_redo:
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
	show_grid_button.button_pressed = TheProject.layout_pref.show_grid
	world_container.camera2d.position = TheProject.layout_pref.camera_pos
	world_container.camera2d.zoom = Vector2(1.0, 1.0) * TheProject.layout_pref.zoom

func _on_TheProject_saved():
	add_img_button.disabled = false

func _on_TheProject_closed():
	add_img_button.disabled = true

func _on_img_dialog_file_selected(path):
	TheProject.add_image(path)

func _on_show_grid_checkbox_toggled(toggled_on):
	world_container.show_grid = toggled_on
	TheProject.layout_pref.show_grid = toggled_on

class WorldObjectMovedUndoRedoOperation:
	extends UndoRedoController.UndoRedoOperation
	
	var _world : WorldViewportContainer = null
	var _from_idx = 0
	var _to_idx = 0
	
	func _init(world: WorldViewportContainer, from_idx: int, to_idx: int):
		_world = world
		_from_idx = from_idx
		_to_idx = to_idx
	
	func undo() -> bool:
		return _world.move_world_object(_to_idx, _from_idx)
		
	func redo() -> bool:
		return _world.move_world_object(_from_idx, _to_idx)
		
	func pretty_str() -> String:
		return str({
			'from_idx' : _from_idx,
			'_to_idx': _to_idx
		})

func _on_world_object_moved(from_idx: int, to_idx: int):
	if _ignore_while_in_undo_redo:
		return
	undo_redo_ctrl.push_undo_op(WorldObjectMovedUndoRedoOperation.new(
		world_container, from_idx, to_idx))
	TheProject.has_edits = true

func _on_undo_redo_ctrl_before_a_do(_is_undo):
	_ignore_while_in_undo_redo = true

func _on_undo_redo_ctrl_after_a_do(_is_undo):
	_ignore_while_in_undo_redo = false

func _on_preference_update_timer_timeout():
	TheProject.layout_pref.camera_pos = world_container.camera2d.position
	TheProject.layout_pref.zoom = world_container.camera2d.zoom.x

func _on_viewport_container_gui_input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if ! event.alt_pressed: # let pan take precedence (alt + click + drag)
					if event.pressed:
						_handle_left_click(event.global_position)
					else:
						_handle_left_click_release()
			MOUSE_BUTTON_RIGHT:
				_cancel_mode() # will only cancel if possible
	elif event is InputEventMouseMotion:
		var evt_global_pos = event.global_position
		if _is_point_over_world(evt_global_pos):
			var pos_in_world_px = _global_xy_to_pos_in_world(evt_global_pos)
			var pos_in_world_ft = Utils.px_to_ft_vec(pos_in_world_px)
			var x_pretty = Utils.pretty_dist(pos_in_world_ft.x)
			var y_pretty = Utils.pretty_dist(pos_in_world_ft.y)
			mouse_pos_label.text = "%s, %s" % [x_pretty, y_pretty]
			
			# detect which object mouse is hovering over
			if mode == Mode.Idle:
				var nearest_pickable = _nearest_pickable_obj(pos_in_world_px)
				if nearest_pickable != _hovered_obj:
					# transition 'hovering' status from one object to the next
					if _hovered_obj:
						_hovered_obj.hovering = false
					if nearest_pickable:
						nearest_pickable.hovering = true
					_hovered_obj = nearest_pickable
			
			if sprinkler_to_add:
				sprinkler_to_add.position = pos_in_world_px
			elif dist_meas_to_add and mode == Mode.AddDistMeasureB:
				dist_meas_to_add.point_b = pos_in_world_px
			elif poly_to_add:
				if poly_edit_point_idx < poly_to_add.point_count():
					poly_to_add.set_point(poly_edit_point_idx, pos_in_world_px)
			elif len(_held_objs) > 0:
				_handle_held_obj_move(pos_in_world_px)
