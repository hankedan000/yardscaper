extends PanelContainer

@onready var img_dialog               := $ImgDialog

@onready var sprink_prop_list         := $HSplitContainer/LeftPane/Properties/SprinklerPropertiesList
@onready var img_prop_list            := $HSplitContainer/LeftPane/Properties/ImageNodePropertiesList
@onready var poly_prop_list           := $HSplitContainer/LeftPane/Properties/PolygonNodePropertiesList
@onready var objects_list             := $HSplitContainer/LeftPane/Objects

@onready var add_sprink_button        := $HSplitContainer/Layout/LayoutToolbar/HBox/AddSprinkler
@onready var add_img_button           := $HSplitContainer/Layout/LayoutToolbar/HBox/AddImage
@onready var add_dist_button          := $HSplitContainer/Layout/LayoutToolbar/HBox/AddDistMeasure
@onready var add_poly_button          := $HSplitContainer/Layout/LayoutToolbar/HBox/AddPolygon
@onready var remove_button            := $HSplitContainer/Layout/LayoutToolbar/HBox/RemoveButton
@onready var show_grid_button         := $HSplitContainer/Layout/LayoutToolbar/HBox/ShowGridButton
@onready var world_view               := $HSplitContainer/Layout/WorldView
@onready var img_import_wizard        := $ImageImportWizard

@export var SprinklerScene : PackedScene = null
@export var DistanceMeasurementScene : PackedScene = null
@export var PolygonScene : PackedScene = null

enum Mode {
	Idle,
	Panning,
	MovingObjects,
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
		match mode:
			Mode.Idle:
				Utils.pop_cursor_shape()
			Mode.Panning:
				Utils.push_cursor_shape(Input.CURSOR_DRAG)
			Mode.MovingObjects:
				Utils.push_cursor_shape(Input.CURSOR_DRAG)
			Mode.AddSprinkler:
				Utils.push_cursor_shape(Input.CURSOR_ARROW)
			Mode.AddDistMeasureA:
				Utils.push_cursor_shape(Input.CURSOR_ARROW)
			Mode.AddDistMeasureB:
				Utils.push_cursor_shape(Input.CURSOR_ARROW)
			Mode.AddPolygon:
				Utils.push_cursor_shape(Input.CURSOR_ARROW)
var sprinkler_to_add : Sprinkler = null
var dist_meas_to_add : DistanceMeasurement = null
var poly_to_add : PolygonNode = null
var undo_redo_ctrl := UndoRedoController.new()

# vars for editing PolygonNode points
var poly_edit_point_idx = 0

var _selected_objs : Array[PickableNode2D] = []
var _mouse_move_start_pos_px = null
var _move_undo_batch : UndoRedoController.OperationBatch = null
# object that would be selected next if LEFT mouse button were pressed
var _hovered_obj = null
# serialized versions of all copied world objects
var _copied_world_objs : Array[Dictionary] = []

func _set_all_cursors(ctrl: Control, cursor_shape: CursorShape) -> void:
	ctrl.set_default_cursor_shape(cursor_shape)
	for child in ctrl.get_children():
		if child is Control:
			_set_all_cursors(child, cursor_shape)

func _ready():
	TheProject.node_changed.connect(_on_TheProject_node_changed)
	TheProject.opened.connect(_on_TheProject_opened)
	sprink_prop_list.visible = false
	img_prop_list.visible = false
	poly_prop_list.visible = false
	objects_list.world = world_view
	
	# add shortcuts
	remove_button.shortcut = Utils.create_shortcut(KEY_DELETE)

func _input(event):
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE:
			_cancel_mode() # will only cancel if possible
		elif event.keycode == KEY_C and event.ctrl_pressed:
			_handle_world_object_copy(_selected_objs)
		elif event.keycode == KEY_V and event.ctrl_pressed:
			_handle_world_object_paste(_copied_world_objs)
		elif event.keycode == KEY_PAGEUP:
			var helper := WorldObjectReorderHelper.new(_selected_objs)
			helper.apply_relative_shift(world_view, +1)
		elif event.keycode == KEY_PAGEDOWN:
			var helper := WorldObjectReorderHelper.new(_selected_objs)
			helper.apply_relative_shift(world_view, -1)
		elif event.keycode == KEY_END:
			var helper := WorldObjectReorderHelper.new(_selected_objs)
			helper.apply_shift_to_bottom(world_view)
		elif event.keycode == KEY_HOME:
			var helper := WorldObjectReorderHelper.new(_selected_objs)
			helper.apply_shift_to_top(world_view)

func _nearest_pickable_obj(pos_in_world: Vector2):
	var smallest_dist_px = null
	var nearest_pick_area = null
	var cursor : Area2D = world_view.cursor
	var highest_draw_order : int = -1
	for pick_area in cursor.get_overlapping_areas():
		var obj_center = pick_area.global_position
		var pick_parent = pick_area.get_parent()
		var draw_order = -1
		if pick_parent is PickableNode2D:
			obj_center = pick_parent.get_global_center()
			draw_order = pick_parent.get_order_in_world()
		var dist_px = obj_center.distance_to(pos_in_world)
		if draw_order < highest_draw_order:
			continue
		elif smallest_dist_px and draw_order == highest_draw_order and dist_px > smallest_dist_px:
			continue
		nearest_pick_area = pick_area
		smallest_dist_px = dist_px
		highest_draw_order = draw_order
	
	if nearest_pick_area:
		return nearest_pick_area.get_parent()
	return null

func _handle_left_click(click_pos: Vector2):
	# ignore clicks that are outside the world viewpoint
	if not _is_point_over_world(click_pos):
		return
	
	match mode:
		Mode.Idle:
			if _hovered_obj:
				if not Input.is_key_pressed(KEY_CTRL) and _hovered_obj not in _selected_objs:
					_clear_selected_objects()
				_add_selected_object(_hovered_obj)

func _handle_left_click_release(click_pos: Vector2):
	var pos_in_world_px = world_view.global_xy_to_pos_in_world(click_pos)
	match mode:
		Mode.Idle:
			if not Input.is_key_pressed(KEY_CTRL):
				_clear_selected_objects()
			if _hovered_obj:
				_add_selected_object(_hovered_obj)
		Mode.MovingObjects:
			for obj in _selected_objs:
				if obj is MoveableNode2D:
					obj.finish_move()
			_move_undo_batch = null
			_mouse_move_start_pos_px = null
			mode = Mode.Idle
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

func _handle_held_obj_move(mouse_pos_in_world_px: Vector2) -> void:
	if _mouse_move_start_pos_px == null:
		_mouse_move_start_pos_px = mouse_pos_in_world_px
	
	# apply delta movement vector to all selected movable objects
	var delta_px = mouse_pos_in_world_px - _mouse_move_start_pos_px
	for obj in _selected_objs:
		if obj is MoveableNode2D:
			obj.update_move(delta_px)

func _handle_world_object_copy(objs: Array[PickableNode2D]) -> void:
	_copied_world_objs.clear()
	for obj in objs:
		if obj:
			_copied_world_objs.push_back(obj.serialize())

func _handle_world_object_paste(copied_data: Array[Dictionary]) -> void:
	for obj_data in copied_data:
		var obj := TheProject.instance_world_obj(obj_data)
		if obj:
			TheProject.add_object(obj)

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

func _clear_selected_objects() -> void:
	for obj in _selected_objs:
		_on_release_selected_obj(obj)
	_selected_objs.clear()
	remove_button.disabled = true

func _add_selected_object(obj: PickableNode2D) -> void:
	if obj not in _selected_objs:
		_selected_objs.append(obj)
	
	sprink_prop_list.hide()
	img_prop_list.hide()
	poly_prop_list.hide()
	var is_single := _selected_objs.size() == 1
	if obj is Sprinkler:
		_on_sprinkler_selected(obj, is_single)
	elif obj is ImageNode:
		_on_img_node_selected(obj, is_single)
	elif obj is DistanceMeasurement:
		_on_dist_measurement_selected(obj, is_single)
	elif obj is PolygonNode:
		_on_polygon_selected(obj, is_single)
	elif obj != null:
		push_warning("unsupported selection for obj '%s'" % obj)
	
	remove_button.disabled = false

func _remove_selected_object(obj: PickableNode2D) -> void:
	_on_release_selected_obj(obj)
	_selected_objs.erase(obj)
	remove_button.disabled = _selected_objs.is_empty()

func _on_release_selected_obj(obj: PickableNode2D):
	if obj is Sprinkler:
		obj.picked = false
		obj.show_min_dist = false
		obj.show_max_dist = false
	elif obj is ImageNode:
		obj.picked = false
	elif obj is DistanceMeasurement:
		obj.picked = false
	elif obj is PolygonNode:
		obj.picked = false
	elif obj != null:
		push_warning("unsupported release for obj '%s'" % obj)

func _on_sprinkler_selected(sprink: Sprinkler, is_single: bool):
	sprink.picked = true
	sprink.show_min_dist = true
	sprink.show_max_dist = true
	if is_single:
		sprink_prop_list.sprinkler = sprink
		sprink_prop_list.show()

func _on_img_node_selected(img_node: ImageNode, is_single: bool):
	img_node.picked = true
	if is_single:
		img_prop_list.img_node = img_node
		img_prop_list.show()

func _on_dist_measurement_selected(meas: DistanceMeasurement, _is_single: bool):
	meas.picked = true

func _on_polygon_selected(poly: PolygonNode, is_single: bool):
	poly.picked = true
	if is_single:
		poly_prop_list.poly_node = poly
		poly_prop_list.show()

func _is_point_over_world(global_pos: Vector2) -> bool:
	return world_view.get_global_rect().has_point(global_pos)

func _on_add_sprinkler_pressed():
	sprinkler_to_add = SprinklerScene.instantiate()
	sprinkler_to_add.user_label = TheProject.get_unique_name('Sprinkler')
	sprinkler_to_add.position = world_view.global_xy_to_pos_in_world(get_global_mouse_position())
	world_view.objects.add_child(sprinkler_to_add)
	mode = Mode.AddSprinkler

func _on_add_image_pressed():
	img_dialog.popup_centered()

func _on_add_dist_measure_pressed():
	dist_meas_to_add = DistanceMeasurementScene.instantiate()
	dist_meas_to_add.user_label = TheProject.get_unique_name('DistanceMeasurement')
	world_view.objects.add_child(dist_meas_to_add)
	mode = Mode.AddDistMeasureA

func _on_add_polygon_pressed():
	poly_to_add = PolygonScene.instantiate()
	poly_to_add.user_label = TheProject.get_unique_name('PolygonNode')
	poly_to_add.picked = true
	poly_to_add.add_point(Vector2())
	poly_edit_point_idx = 0
	world_view.objects.add_child(poly_to_add)
	mode = Mode.AddPolygon

func _on_remove_button_pressed():
	for obj in _selected_objs:
		undo_redo_ctrl.push_undo_op(WorldObjectUndoRedoOps.Remove.new(
			world_view,
			obj.get_order_in_world(),
			obj))
		TheProject.remove_object(obj)
	_clear_selected_objects()

func _on_TheProject_node_changed(obj, change_type: TheProject.ChangeType, args):
	var obj_in_world = obj in world_view.objects.get_children()
	match change_type:
		TheProject.ChangeType.ADD:
			if not obj_in_world:
				world_view.objects.add_child(obj)
			if obj is PickableNode2D:
				_clear_selected_objects()
				_add_selected_object(obj)
		TheProject.ChangeType.REMOVE:
			if obj_in_world:
				world_view.objects.remove_child(obj)
		TheProject.ChangeType.PROP_EDIT:
			var prop_name : String = args[0]
			var old_value = args[1]
			var new_value = args[2]
			var undo_op := UndoRedoController.PropEditUndoRedoOperation.new(
					obj,
					prop_name,
					old_value,
					new_value)
			if prop_name == &"position" and mode == Mode.MovingObjects:
				# batch undo operations for a multi-object move
				if _move_undo_batch != null:
					_move_undo_batch.push_op(undo_op)
				else:
					_move_undo_batch = undo_redo_ctrl.push_undo_op(undo_op)
			else:
				undo_redo_ctrl.push_undo_op(undo_op)

func _on_TheProject_opened():
	undo_redo_ctrl.reset()
	show_grid_button.button_pressed = TheProject.layout_pref.show_grid
	world_view.camera2d.position = TheProject.layout_pref.camera_pos
	world_view.camera2d.zoom = Vector2(1.0, 1.0) * TheProject.layout_pref.zoom

func _on_img_dialog_file_selected(path):
	if img_import_wizard.load_img(path):
		img_import_wizard.popup_centered()

func _on_image_import_wizard_accepted(img_path: String, size_ft: Vector2) -> void:
	var new_image := TheProject.add_image(img_path)
	print(new_image)
	if new_image:
		new_image.width_ft = size_ft.x
		new_image.height_ft = size_ft.y

func _on_show_grid_checkbox_toggled(toggled_on):
	world_view.show_grid = toggled_on
	TheProject.layout_pref.show_grid = toggled_on

func _on_world_object_reordered(from_idx: int, to_idx: int):
	var undo_op := WorldObjectUndoRedoOps.Reordered.new(
		world_view,
		from_idx,
		to_idx)
	undo_redo_ctrl.push_undo_op(undo_op)
	TheProject.has_edits = true

func _on_preference_update_timer_timeout():
	TheProject.layout_pref.camera_pos = world_view.camera2d.position
	TheProject.layout_pref.zoom = world_view.camera2d.zoom.x

func _on_world_view_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if ! event.alt_pressed: # let pan take precedence (alt + click + drag)
					if event.pressed:
						_handle_left_click(event.global_position)
					else:
						_handle_left_click_release(event.global_position)
			MOUSE_BUTTON_RIGHT:
				_cancel_mode() # will only cancel if possible
	elif event is InputEventMouseMotion:
		var evt_global_pos = event.global_position
		if _is_point_over_world(evt_global_pos):
			var pos_in_world_px = world_view.global_xy_to_pos_in_world(evt_global_pos)
			
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
				if nearest_pickable:
					Utils.push_cursor_shape(Input.CURSOR_POINTING_HAND)
				else:
					Utils.pop_cursor_shape()
			
			if sprinkler_to_add:
				sprinkler_to_add.position = pos_in_world_px
			elif dist_meas_to_add and mode == Mode.AddDistMeasureB:
				dist_meas_to_add.point_b = pos_in_world_px
			elif poly_to_add:
				if poly_edit_point_idx < poly_to_add.point_count():
					poly_to_add.set_point(poly_edit_point_idx, pos_in_world_px)
			elif mode != Mode.MovingObjects and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				for obj in _selected_objs:
					if obj is MoveableNode2D:
						obj.start_move()
						mode = Mode.MovingObjects
			
			if mode == Mode.MovingObjects:
				_handle_held_obj_move(pos_in_world_px)

func _on_viewport_container_pan_state_changed(panning: bool) -> void:
	if panning:
		mode = Mode.Panning
	else:
		mode = Mode.Idle
