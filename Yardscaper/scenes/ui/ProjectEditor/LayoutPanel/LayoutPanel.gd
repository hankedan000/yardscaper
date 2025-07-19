extends PanelContainer
class_name LayoutPanel

const MULTI_SELECT_KEY = KEY_SHIFT
const TOOLTIP_DELAY_DURATION_SEC := 1.0

@onready var img_dialog               := $ImgDialog
@onready var img_import_wizard        := $ImageImportWizard
@onready var grid_spacing_dialog      : GridSpacingDialog = $GridSpacingDialog
@onready var solve_summary_dialog     : SolveSummaryDialog = $SolveSummaryDialog

@onready var sprink_prop_list         : SprinklerPropertyEditor = $HSplitContainer/LeftPane/Properties/SprinklerPropertiesList
@onready var img_prop_list            : ImageNodePropertyEditor = $HSplitContainer/LeftPane/Properties/ImageNodePropertiesList
@onready var poly_prop_list           : PolygonNodePropertyEditor = $HSplitContainer/LeftPane/Properties/PolygonNodePropertiesList
@onready var pipe_prop_list           : PipePropertyEditor = $HSplitContainer/LeftPane/Properties/PipePropertyEditor
@onready var objects_list             := $HSplitContainer/LeftPane/Objects

@onready var add_sprink_button        := $HSplitContainer/Layout/LayoutToolbar/HBox/AddSprinkler
@onready var add_img_button           := $HSplitContainer/Layout/LayoutToolbar/HBox/AddImage
@onready var add_dist_button          := $HSplitContainer/Layout/LayoutToolbar/HBox/AddDistMeasure
@onready var add_poly_button          := $HSplitContainer/Layout/LayoutToolbar/HBox/AddPolygon
@onready var remove_button            := $HSplitContainer/Layout/LayoutToolbar/HBox/RemoveButton
@onready var pos_lock_button          := $HSplitContainer/Layout/LayoutToolbar/HBox/PositionLockButton
@onready var pos_unlock_button        := $HSplitContainer/Layout/LayoutToolbar/HBox/PositionUnlockButton
@onready var view_menu_button         := $HSplitContainer/Layout/LayoutToolbar/HBox/ViewMenuButton
@onready var obj_view_popupmenu       := $HSplitContainer/Layout/LayoutToolbar/HBox/ViewMenuButton/ObjectsViewPopupMenu
@onready var pipe_view_popupmenu      := $HSplitContainer/Layout/LayoutToolbar/HBox/ViewMenuButton/PipeViewPopupMenu
@onready var pipe_colorize_popupmenu  : PopupMenu = $HSplitContainer/Layout/LayoutToolbar/HBox/ViewMenuButton/PipeColorizePopupMenu
@onready var grid_view_popupmenu      := $HSplitContainer/Layout/LayoutToolbar/HBox/ViewMenuButton/GridViewPopupMenu
@onready var curve_edit_buttons       := $HSplitContainer/Layout/LayoutToolbar/HBox/CurveEditButtons
@onready var world_view               : WorldViewportContainer = $HSplitContainer/Layout/WorldView
@onready var tooltip_timer            := $ToolTipTimer

enum Mode {
	Idle,
	MovingObjects,
	AddSprinkler,
	AddDistMeasureA,
	AddDistMeasureB,
	AddPolygon,
	AddPipeNode
}

enum ViewMenuIds {
	ShowOrigin = 0,
	Objects = 2,
	Pipes = 4,
	Grid = 3
}

enum PipeViewMenuIds {
	ShowFlowDirection = 0,
	Colorize = 1
}

enum ObjectViewMenuIds {
	Measurements = 1,
	Polygons = 2,
	Sprinklers = 3,
	Pipes = 4,
	Images = 5
}

enum GridViewMenuIds {
	ShowGrid = 0,
	Spacing = 1
}

var mode = Mode.Idle:
	set(value):
		var adds_disabled = value != Mode.Idle
		add_sprink_button.disabled = adds_disabled
		add_img_button.disabled = adds_disabled
		add_dist_button.disabled = adds_disabled
		add_poly_button.disabled = adds_disabled
		mode = value
		if mode != Mode.Idle:
			world_view.hide_tooltip()
		match mode:
			Mode.Idle:
				Globals.pop_cursor_shape()
			Mode.MovingObjects:
				Globals.push_cursor_shape(Input.CURSOR_DRAG)
			Mode.AddSprinkler:
				Globals.push_cursor_shape(Input.CURSOR_CROSS)
			Mode.AddDistMeasureA:
				Globals.push_cursor_shape(Input.CURSOR_CROSS)
			Mode.AddDistMeasureB:
				Globals.push_cursor_shape(Input.CURSOR_CROSS)
			Mode.AddPolygon:
				Globals.push_cursor_shape(Input.CURSOR_CROSS)
			Mode.AddPipeNode:
				Globals.push_cursor_shape(Input.CURSOR_CROSS)
var sprinkler_to_add : Sprinkler = null
var dist_meas_to_add : DistanceMeasurement = null
var pipe_node_to_add : PipeNode = null
var poly_to_add : PolygonNode = null
var undo_redo_ctrl := UndoController.new()

var _selection_controller : WorldObjectSelectionController = WorldObjectSelectionController.new()
var _can_start_move : bool = false
var _mouse_move_start_pos_px = null
var _curr_undo_batch : UndoController.OperationBatch = null
# object that would be selected next if LEFT mouse button were pressed
var _hovered_obj : WorldObject = null:
	set(value):
		var old_value = _hovered_obj
		_hovered_obj = value
		if old_value != _hovered_obj:
			world_view.hide_tooltip()
			tooltip_timer.stop()
			if _hovered_obj:
				tooltip_timer.start(TOOLTIP_DELAY_DURATION_SEC)
# serialized versions of all copied world objects
var _copied_world_objs : Array[Dictionary] = []

# vars for editing PolygonNode points
var _poly_edit_point_idx = 0
var _poly_edit_mode := PolygonNode.EditMode.Edit

func _set_all_cursors(ctrl: Control, cursor_shape: CursorShape) -> void:
	ctrl.set_default_cursor_shape(cursor_shape)
	for child in ctrl.get_children():
		if child is Control:
			_set_all_cursors(child, cursor_shape)

func _ready():
	TheProject.node_changed.connect(_on_TheProject_node_changed)
	TheProject.opened.connect(_on_TheProject_opened)
	TheProject.layout_pref.view_show_state_changed.connect(_on_LayoutPref_view_show_state_changed)
	_selection_controller.item_selected.connect(_on_selection_controller_item_selected)
	_selection_controller.item_deselected.connect(_on_selection_controller_item_deselected)
	sprink_prop_list.visible = false
	sprink_prop_list.set_layout_panel(self)
	img_prop_list.visible = false
	poly_prop_list.visible = false
	pipe_prop_list.visible = false
	pipe_prop_list.set_layout_panel(self)
	objects_list.world = world_view
	img_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	
	# setup the view MenuButton
	var view_popup := view_menu_button.get_popup() as PopupMenu
	view_popup.hide_on_checkable_item_selection = false
	obj_view_popupmenu.hide_on_checkable_item_selection = false
	pipe_view_popupmenu.hide_on_checkable_item_selection = false
	pipe_colorize_popupmenu.hide_on_checkable_item_selection = false
	grid_view_popupmenu.hide_on_checkable_item_selection = false
	view_popup.id_pressed.connect(_on_view_menu_id_pressed)
	Utils.reparent_as_submenu(obj_view_popupmenu, view_popup, ViewMenuIds.Objects)
	Utils.reparent_as_submenu(pipe_view_popupmenu, view_popup, ViewMenuIds.Pipes)
	Utils.reparent_as_submenu(pipe_colorize_popupmenu, pipe_view_popupmenu, PipeViewMenuIds.Colorize)
	Utils.reparent_as_submenu(grid_view_popupmenu, view_popup, ViewMenuIds.Grid)
	
	# add shortcuts
	remove_button.shortcut = Utils.create_shortcut(KEY_DELETE)

func _process(_delta: float) -> void:
	_curr_undo_batch = null # start a new batch each frame

func _input(event):
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE:
			_cancel_mode() # will only cancel if possible
		elif event.keycode == KEY_C and event.ctrl_pressed:
			_handle_world_object_copy(_selection_controller.selected_objs())
		elif event.keycode == KEY_V and event.ctrl_pressed:
			_handle_world_object_paste(_copied_world_objs)
		elif event.keycode == KEY_PAGEUP:
			var helper := WorldObjectReorderHelper.new(_selection_controller.selected_objs())
			helper.apply_relative_shift(world_view, +1)
		elif event.keycode == KEY_PAGEDOWN:
			var helper := WorldObjectReorderHelper.new(_selection_controller.selected_objs())
			helper.apply_relative_shift(world_view, -1)
		elif event.keycode == KEY_END:
			var helper := WorldObjectReorderHelper.new(_selection_controller.selected_objs())
			helper.apply_shift_to_bottom(world_view)
		elif event.keycode == KEY_HOME:
			var helper := WorldObjectReorderHelper.new(_selection_controller.selected_objs())
			helper.apply_shift_to_top(world_view)

func _push_undo_op(op: UndoController.UndoOperation) -> void:
	if _curr_undo_batch != null:
		_curr_undo_batch.push_op(op)
	else:
		_curr_undo_batch = undo_redo_ctrl.push_undo_op(op)

func fit_view_to_zone(zone: int) -> void:
	var objs := TheProject.get_objs_in_zone(zone)
	var zone_box := Utils.get_bounding_box_around_all(objs)
	world_view.fit_view_to_rect(zone_box, 0.1)

func _handle_left_click_release(pos_in_world_px: Vector2):
	match mode:
		Mode.Idle:
			Globals.pop_cursor_shape()
		Mode.MovingObjects:
			for obj in _selection_controller.selected_objs():
				obj.finish_move()
			_mouse_move_start_pos_px = null
			mode = Mode.Idle
		Mode.AddSprinkler:
			sprinkler_to_add = null
			mode = Mode.Idle
		Mode.AddDistMeasureA:
			dist_meas_to_add.point_a = pos_in_world_px
			dist_meas_to_add.point_b = pos_in_world_px
			mode = Mode.AddDistMeasureB
		Mode.AddDistMeasureB:
			dist_meas_to_add.point_b = pos_in_world_px
			dist_meas_to_add = null
			mode = Mode.Idle
		Mode.AddPolygon:
			poly_to_add.set_point(_poly_edit_point_idx, pos_in_world_px)
			poly_to_add.set_handle_visible(_poly_edit_point_idx, true)
			poly_to_add.add_point(pos_in_world_px)
			_poly_edit_point_idx = poly_to_add.point_count() - 1
			poly_to_add.set_handle_visible(_poly_edit_point_idx, false)
		Mode.AddPipeNode:
			pipe_node_to_add = null
			mode = Mode.Idle

func _handle_held_obj_move(mouse_pos_in_world_px: Vector2) -> void:
	if _mouse_move_start_pos_px == null:
		_mouse_move_start_pos_px = mouse_pos_in_world_px
	
	# apply delta movement vector to all selected movable objects
	var delta_px = mouse_pos_in_world_px - _mouse_move_start_pos_px
	for obj in _selection_controller.selected_objs():
		obj.update_move(delta_px)

func _handle_world_object_copy(objs: Array[WorldObject]) -> void:
	_copied_world_objs.clear()
	for obj in objs:
		if obj:
			_copied_world_objs.push_back(obj.serialize())

func _handle_world_object_paste(copied_data: Array[Dictionary]) -> void:
	for obj_data in copied_data:
		TheProject.instance_world_obj(obj_data[&'subclass'], obj_data)

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
		if _poly_edit_point_idx < poly_to_add.point_count():
			poly_to_add.remove_point(_poly_edit_point_idx)
		poly_to_add.picked = false
		if poly_to_add.point_count() < 3:
			poly_to_add.queue_free()
		poly_to_add = null
		mode = Mode.Idle

func _update_ui_after_selection_change():
	var selected_objs := _selection_controller.selected_objs()
	_update_position_lock_buttons()
	remove_button.disabled = selected_objs.is_empty()
	sprink_prop_list.hide()
	sprink_prop_list.clear_objects()
	img_prop_list.hide()
	img_prop_list.clear_objects()
	poly_prop_list.hide()
	poly_prop_list.clear_objects()
	pipe_prop_list.hide()
	pipe_prop_list.clear_objects()
	curve_edit_buttons.hide()
	
	if selected_objs.size() == 0:
		return
	
	var all_sprinklers := true
	var all_images := true
	var all_distances := true
	var all_polygons := true
	var all_pipes := true
	var all_pipe_nodes := true
	
	for obj in selected_objs:
		if obj is Sprinkler:
			all_images = false
			all_distances = false
			all_polygons = false
			all_pipes = false
			all_pipe_nodes = false
		elif obj is ImageNode:
			all_sprinklers = false
			all_distances = false
			all_polygons = false
			all_pipes = false
			all_pipe_nodes = false
		elif obj is Pipe: # test Pipe before DistanceMeasurement because it inherits from it
			all_sprinklers = false
			all_images = false
			all_distances = false
			all_polygons = false
			all_pipe_nodes = false
		elif obj is DistanceMeasurement:
			all_sprinklers = false
			all_images = false
			all_polygons = false
			all_pipes = false
			all_pipe_nodes = false
		elif obj is PolygonNode:
			all_sprinklers = false
			all_images = false
			all_distances = false
			all_pipes = false
			all_pipe_nodes = false
		elif obj is PipeNode:
			all_sprinklers = false
			all_images = false
			all_polygons = false
			all_distances = false
			all_pipes = false
	
	if all_sprinklers:
		for obj in selected_objs:
			sprink_prop_list.add_object(obj)
		sprink_prop_list.show()
	elif all_images:
		for obj in selected_objs:
			img_prop_list.add_object(obj)
		img_prop_list.show()
	elif all_distances:
		pass
	elif all_polygons:
		for obj in selected_objs:
			poly_prop_list.add_object(obj)
		poly_prop_list.show()
		curve_edit_buttons.show()
	elif all_pipes:
		for obj in selected_objs:
			pipe_prop_list.add_object(obj)
		pipe_prop_list.show()
	elif all_pipe_nodes:
		pass # TODO add PipeNode property editor

func _update_position_lock_buttons():
	var selected_objs := _selection_controller.selected_objs()
	var all_are_locked = true
	for obj in selected_objs:
		if not obj.position_locked:
			all_are_locked = false
			break
	
	if selected_objs.is_empty():
		pos_lock_button.disabled = true
		pos_lock_button.visible = true
		pos_unlock_button.visible = false
	elif all_are_locked:
		pos_lock_button.visible = false
		pos_unlock_button.visible = true
	else:
		pos_lock_button.disabled = false
		pos_lock_button.visible = true
		pos_unlock_button.visible = false

func _is_point_over_world(global_pos: Vector2) -> bool:
	return world_view.get_global_rect().has_point(global_pos)

func _apply_polygon_edit_mode(objs: Array[WorldObject]) -> void:
	for obj in objs:
		if obj is PolygonNode:
			obj.edit_mode = _poly_edit_mode

func _focus_on_objs(objs: Array[WorldObject]) -> void:
	if objs.is_empty():
		return
	
	var bound_box := Utils.get_bounding_box_around_all(objs)
	world_view.fit_view_to_rect(bound_box, 0.1)
	_selection_controller.clear_selection()
	for obj in objs:
		_selection_controller.add_to_selection(obj)

func _on_obj_created(obj: WorldObject) -> void:
	# add the object to the world view
	var obj_parent := obj.get_parent()
	if is_instance_valid(obj_parent) && obj_parent != world_view.objects:
		obj.reparent(world_view.objects)
	else:
		world_view.objects.add_child(obj)
	
	_push_undo_op(WorldObjectUndoRedoOps.AddOrRemove.new(
		world_view,
		obj,
		false)) # is_remove
	obj.picked_state_changed.connect(_on_pickable_object_pick_state_changed.bind(obj))
	obj.undoable_edit.connect(_on_world_obj_undoable_edit)
	_selection_controller.clear_selection()
	obj.picked = true

func _on_obj_removed(obj: WorldObject) -> void:
	world_view.objects.remove_child(obj)
	_selection_controller.remove_from_selection(obj)
	if _hovered_obj == obj:
		_hovered_obj = null

func _on_obj_prop_edit(obj: WorldObject, prop_name: StringName, old_value, new_value) -> void:
	# create the undo operation based on the prop_name
	var undo_op : UndoController.UndoOperation = null
	if prop_name == &'global_position':
		undo_op = WorldObjectUndoRedoOps.GlobalPositionChange.new(
			obj,
			old_value as Vector2,
			new_value as Vector2)
	else:
		undo_op = UndoController.PropEditUndoOperation.new(
			obj,
			prop_name,
			old_value,
			new_value)
	
	_push_undo_op(undo_op)

func _on_add_sprinkler_pressed():
	sprinkler_to_add = TheProject.instance_world_obj(TypeNames.SPRINKLER)
	sprinkler_to_add.position = world_view.global_xy_to_pos_in_world(get_global_mouse_position())
	mode = Mode.AddSprinkler

func _on_add_pipe_pressed() -> void:
	# since pipes are similar to DistanceMeasurement nodes, we'll reused the
	# "adding" logic for it. should work for now ...
	dist_meas_to_add = TheProject.instance_world_obj(TypeNames.PIPE)
	mode = Mode.AddDistMeasureA

func _on_add_pipe_node_pressed() -> void:
	pipe_node_to_add = TheProject.instance_world_obj(TypeNames.PIPE_NODE)
	mode = Mode.AddPipeNode

func _on_add_image_pressed():
	img_dialog.popup_centered()

func _on_add_dist_measure_pressed():
	dist_meas_to_add = TheProject.instance_world_obj(TypeNames.DIST_MEASUREMENT)
	mode = Mode.AddDistMeasureA

func _on_add_polygon_pressed():
	poly_to_add = TheProject.instance_world_obj(TypeNames.POLYGON_NODE)
	poly_to_add.picked = true
	poly_to_add.add_point(Vector2())
	poly_to_add.set_handle_visible(0, false)
	_poly_edit_point_idx = 0
	mode = Mode.AddPolygon

func _on_remove_button_pressed():
	for obj in _selection_controller.selected_objs():
		_push_undo_op(WorldObjectUndoRedoOps.AddOrRemove.new(
			world_view,
			obj,
			true)) # is_remove
		obj.queue_free()
	_selection_controller.clear_selection()

func _on_TheProject_node_changed(obj, change_type: TheProject.ChangeType, args: Array):
	match change_type:
		TheProject.ChangeType.ADD:
			_on_obj_created(obj)
		TheProject.ChangeType.REMOVE:
			_on_obj_removed(obj)
		TheProject.ChangeType.PROP_EDIT:
			var prop_name : StringName = args[0]
			var old_value = args[1]
			var new_value = args[2]
			_on_obj_prop_edit(obj, prop_name, old_value, new_value)

func _on_TheProject_opened():
	_selection_controller.clear_selection()
	undo_redo_ctrl.reset()
	
	# restore "View" options
	var view_popup := view_menu_button.get_popup() as PopupMenu
	var layout_prefs := TheProject.layout_pref
	Utils.set_item_checked_by_id(view_popup, ViewMenuIds.ShowOrigin, layout_prefs.show_origin)
	Utils.set_item_checked_by_id(obj_view_popupmenu, ObjectViewMenuIds.Images, layout_prefs.show_images)
	Utils.set_item_checked_by_id(obj_view_popupmenu, ObjectViewMenuIds.Measurements, layout_prefs.show_measurements)
	Utils.set_item_checked_by_id(obj_view_popupmenu, ObjectViewMenuIds.Polygons, layout_prefs.show_polygons)
	Utils.set_item_checked_by_id(obj_view_popupmenu, ObjectViewMenuIds.Sprinklers, layout_prefs.show_sprinklers)
	Utils.set_item_checked_by_id(obj_view_popupmenu, ObjectViewMenuIds.Pipes, layout_prefs.show_pipes)
	Utils.set_item_checked_by_id(pipe_view_popupmenu, PipeViewMenuIds.ShowFlowDirection, layout_prefs.show_pipe_flow_direction)
	Utils.set_item_checked_by_id(grid_view_popupmenu, GridViewMenuIds.ShowGrid, layout_prefs.show_grid)
	
	# restore world view preferences
	world_view.show_grid = TheProject.layout_pref.show_grid
	world_view.show_origin = TheProject.layout_pref.show_origin
	world_view.major_spacing_ft = TheProject.layout_pref.grid_major_spacing_ft
	world_view.camera2d.position = TheProject.layout_pref.camera_pos
	world_view.camera2d.zoom = Vector2(1.0, 1.0) * TheProject.layout_pref.zoom
	world_view._on_pan_zoom_controller_zoom_changed(1.0, TheProject.layout_pref.zoom)

func _on_LayoutPref_view_show_state_changed(property: StringName, new_value: bool) -> void:
	match property:
		LayoutPreferences.PROP_KEY_SHOW_GRID:
			world_view.show_grid = new_value
		LayoutPreferences.PROP_KEY_SHOW_ORIGIN:
			world_view.show_origin = new_value
		LayoutPreferences.PROP_KEY_SHOW_IMAGES:
			for obj in world_view.objects.get_children():
				if obj is ImageNode:
					obj.visible = new_value
		LayoutPreferences.PROP_KEY_SHOW_MEASUREMENTS:
			for obj in world_view.objects.get_children():
				if obj is Pipe:
					pass # Pipes inherit from DistanceMeasurement, so ignore
				elif obj is DistanceMeasurement:
					obj.visible = new_value
		LayoutPreferences.PROP_KEY_SHOW_POLYGONS:
			for obj in world_view.objects.get_children():
				if obj is PolygonNode:
					obj.visible = new_value
		LayoutPreferences.PROP_KEY_SHOW_SPRINKLERS:
			for obj in world_view.objects.get_children():
				if obj is Sprinkler:
					obj.visible = new_value
		LayoutPreferences.PROP_KEY_SHOW_PIPES:
			for obj in world_view.objects.get_children():
				if obj is Pipe:
					obj.visible = new_value
		LayoutPreferences.PROP_KEY_SHOW_PIPE_FLOW_DIRECTION:
			for obj in world_view.objects.get_children():
				if obj is Pipe:
					obj.show_flow_arrows = new_value

func _on_img_dialog_file_selected(path) -> void:
	if img_import_wizard.load_img(path):
		img_import_wizard.popup_centered()

func _on_image_import_wizard_accepted(img_path: String, size_ft: Vector2) -> void:
	var new_image := TheProject.add_image(img_path)
	if new_image:
		new_image.width_ft = size_ft.x
		new_image.height_ft = size_ft.y

func _on_world_object_reordered(from_idx: int, to_idx: int):
	var undo_op := WorldObjectUndoRedoOps.Reordered.new(
		world_view,
		from_idx,
		to_idx)
	_push_undo_op(undo_op)
	TheProject.has_edits = true

func _on_pickable_object_pick_state_changed(obj: WorldObject) -> void:
	if obj.picked:
		_selection_controller.add_to_selection(obj)
	else:
		_selection_controller.remove_from_selection(obj)

func _on_world_obj_undoable_edit(undo_op: UndoController.UndoOperation) -> void:
	_push_undo_op(undo_op)
	TheProject.has_edits = true

func _on_preference_update_timer_timeout():
	TheProject.layout_pref.camera_pos = world_view.camera2d.position
	TheProject.layout_pref.zoom = world_view.camera2d.zoom.x

func _on_world_view_gui_input(event: InputEvent):
	var evt_global_pos = event.global_position
	var pos_in_world_px := world_view.global_xy_to_pos_in_world(evt_global_pos)
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if ! Input.is_key_pressed(KEY_ALT): # let pan take precedence (alt + click + drag)
					_can_start_move = (
						event.pressed &&
						mode != Mode.MovingObjects &&
						! Input.is_key_pressed(MULTI_SELECT_KEY))
					if event.pressed:
						_selection_controller.on_select_button_pressed(_hovered_obj)
					else:
						_handle_left_click_release(pos_in_world_px)
			MOUSE_BUTTON_RIGHT:
				_cancel_mode() # will only cancel if possible
	elif event is InputEventMouseMotion:
		# detect which object mouse is hovering over
		var is_panning := Input.is_key_pressed(KEY_ALT) or world_view.pan_zoom_ctrl.is_panning()
		if mode == Mode.Idle and not is_panning:
			var nearest_pickable := world_view.get_pickable_under_cursor()
			if nearest_pickable != _hovered_obj:
				# transition 'hovering' status from one object to the next
				if _hovered_obj:
					_hovered_obj.hovering = false
				if nearest_pickable:
					nearest_pickable.hovering = true
				_hovered_obj = nearest_pickable
			if nearest_pickable:
				Globals.push_cursor_shape(Input.CURSOR_POINTING_HAND)
			else:
				Globals.pop_cursor_shape()
		
		if sprinkler_to_add:
			sprinkler_to_add.position = pos_in_world_px
		elif dist_meas_to_add and mode == Mode.AddDistMeasureB:
			dist_meas_to_add.point_b = pos_in_world_px
		elif poly_to_add:
			if _poly_edit_point_idx < poly_to_add.point_count():
				poly_to_add.set_point(_poly_edit_point_idx, pos_in_world_px)
		elif pipe_node_to_add:
			pipe_node_to_add.position = pos_in_world_px
		elif _can_start_move:
			_can_start_move = false # clear flag once we started
			# check if any selected objects are position locked
			var all_movable = true
			var selected_objs := _selection_controller.selected_objs()
			for obj in selected_objs:
				if ! obj.is_movable():
					all_movable = false
					break
			
			# start move operations if all objects are movable
			if all_movable && selected_objs.size() > 0:
				for obj in selected_objs:
					obj.start_move()
				mode = Mode.MovingObjects
			elif ! all_movable && selected_objs.size() > 0:
				Globals.push_cursor_shape(Input.CURSOR_FORBIDDEN)
		
		if mode == Mode.MovingObjects:
			_handle_held_obj_move(pos_in_world_px)

func _on_viewport_container_pan_state_changed(panning: bool) -> void:
	if panning:
		Globals.push_cursor_shape(Input.CURSOR_DRAG)
	else:
		Globals.pop_cursor_shape()

func _on_position_lock_button_pressed() -> void:
	for obj in _selection_controller.selected_objs():
		obj.position_locked = true
	_update_position_lock_buttons()

func _on_position_unlock_button_pressed() -> void:
	for obj in _selection_controller.selected_objs():
		obj.position_locked = false
	_update_position_lock_buttons()

func _on_tool_tip_timer_timeout() -> void:
	if is_instance_valid(_hovered_obj) and mode == Mode.Idle:
		world_view.show_tooltip(_hovered_obj.get_tooltip_text())

func _on_view_menu_id_pressed(id: int) -> void:
	var view_popup := view_menu_button.get_popup() as PopupMenu
	var idx := view_popup.get_item_index(id) as int
	# toggle checked state if item is checkable
	if view_popup.is_item_checkable(idx):
		view_popup.toggle_item_checked(idx)
	
	var is_checked := view_popup.is_item_checked(idx)
	match id:
		ViewMenuIds.ShowOrigin:
			world_view.show_origin = is_checked
			TheProject.layout_pref.show_origin = is_checked

func _on_pipe_view_popup_menu_id_pressed(id: int) -> void:
	var idx := pipe_view_popupmenu.get_item_index(id) as int
	# toggle checked state if item is checkable
	if pipe_view_popupmenu.is_item_checkable(idx):
		pipe_view_popupmenu.toggle_item_checked(idx)
	
	var is_checked := pipe_view_popupmenu.is_item_checked(idx) as bool
	match id:
		PipeViewMenuIds.ShowFlowDirection:
			TheProject.layout_pref.show_pipe_flow_direction = is_checked

func _on_pipe_colorize_popup_menu_id_pressed(id: int) -> void:
	for item_idx in range(pipe_colorize_popupmenu.item_count):
		pipe_colorize_popupmenu.set_item_checked(item_idx, false)
	var idx := pipe_colorize_popupmenu.get_item_index(id) as int
	pipe_colorize_popupmenu.toggle_item_checked(idx)

func _on_objects_view_popup_menu_id_pressed(id: int) -> void:
	var idx := obj_view_popupmenu.get_item_index(id) as int
	# toggle checked state if item is checkable
	if obj_view_popupmenu.is_item_checkable(idx):
		obj_view_popupmenu.toggle_item_checked(idx)
	
	var is_checked := obj_view_popupmenu.is_item_checked(idx) as bool
	match id:
		ObjectViewMenuIds.Images:
			TheProject.layout_pref.show_images = is_checked
		ObjectViewMenuIds.Measurements:
			TheProject.layout_pref.show_measurements = is_checked
		ObjectViewMenuIds.Polygons:
			TheProject.layout_pref.show_polygons = is_checked
		ObjectViewMenuIds.Sprinklers:
			TheProject.layout_pref.show_sprinklers = is_checked
		ObjectViewMenuIds.Pipes:
			TheProject.layout_pref.show_pipes = is_checked

func _on_grid_view_popup_menu_id_pressed(id: int) -> void:
	var idx := grid_view_popupmenu.get_item_index(id) as int
	# toggle checked state if item is checkable
	if grid_view_popupmenu.is_item_checkable(idx):
		grid_view_popupmenu.toggle_item_checked(idx)
	
	var is_checked := grid_view_popupmenu.is_item_checked(idx) as bool
	match id:
		GridViewMenuIds.ShowGrid:
			world_view.show_grid = is_checked
			TheProject.layout_pref.show_grid = is_checked
		GridViewMenuIds.Spacing:
			grid_spacing_dialog.setup(world_view.major_spacing_ft)
			grid_spacing_dialog.popup_centered()

func _on_grid_spacing_dialog_apply(major_spacing_ft: Vector2) -> void:
	world_view.major_spacing_ft = major_spacing_ft
	TheProject.layout_pref.grid_major_spacing_ft = major_spacing_ft

func _on_grid_spacing_dialog_cancel(original_major_spacing_ft: Vector2) -> void:
	world_view.major_spacing_ft = original_major_spacing_ft
	
func _on_grid_spacing_dialog_spacing_changed(major_spacing_ft: Vector2) -> void:
	world_view.major_spacing_ft = major_spacing_ft

func _on_selection_controller_item_selected(obj: WorldObject) -> void:
	obj.picked = true
	_apply_polygon_edit_mode([obj])
	_update_ui_after_selection_change()

func _on_selection_controller_item_deselected(obj: WorldObject) -> void:
	obj.picked = false
	_update_ui_after_selection_change()

func _on_curve_create_button_pressed() -> void:
	_poly_edit_mode = PolygonNode.EditMode.Add
	_apply_polygon_edit_mode(_selection_controller.selected_objs())

func _on_curve_edit_button_pressed() -> void:
	_poly_edit_mode = PolygonNode.EditMode.Edit
	_apply_polygon_edit_mode(_selection_controller.selected_objs())

func _on_curve_remove_button_pressed() -> void:
	_poly_edit_mode = PolygonNode.EditMode.Remove
	_apply_polygon_edit_mode(_selection_controller.selected_objs())

func _on_solve_button_pressed() -> void:
	# solve the system while timing how long it takes
	TheProject.fsys.reset_solved_vars()
	var settings := FSolver.Settings.new()
	settings.set_basic_console_printer()
	var start_ticks_msec := Time.get_ticks_msec()
	var res := FSolver.solve_system(TheProject.fsys, settings)
	var solve_time_msec := Time.get_ticks_msec() - start_ticks_msec
	
	# display results to user
	solve_summary_dialog.show_summary(solve_time_msec, res)

func _on_solve_summary_dialog_entity_clicked(entity: FEntity) -> void:
	var wobj := TheProject.lookup_fentity_parent_obj(entity)
	if is_instance_valid(wobj):
		_focus_on_objs([wobj])

func _on_solve_summary_dialog_unknown_var_clicked(uvar: Var) -> void:
	var wobj := TheProject.lookup_fvar_parent_obj(uvar)
	if is_instance_valid(wobj):
		_focus_on_objs([wobj])
