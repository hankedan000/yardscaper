extends PanelContainer
class_name LayoutPanel

const MULTI_SELECT_KEY = KEY_SHIFT
const TOOLTIP_DELAY_DURATION_SEC := 1.0

@onready var img_dialog               := $ImgDialog
@onready var img_import_wizard        := $ImageImportWizard
@onready var grid_spacing_dialog      : GridSpacingDialog = $GridSpacingDialog

@onready var sprink_prop_list         : SprinklerPropertyEditor = $HSplitContainer/LeftPane/Properties/SprinklerPropertiesList
@onready var img_prop_list            : ImageNodePropertyEditor = $HSplitContainer/LeftPane/Properties/ImageNodePropertiesList
@onready var poly_prop_list           : PolygonNodePropertyEditor = $HSplitContainer/LeftPane/Properties/PolygonNodePropertiesList
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
@onready var grid_view_popupmenu      := $HSplitContainer/Layout/LayoutToolbar/HBox/ViewMenuButton/GridViewPopupMenu
@onready var curve_edit_buttons       := $HSplitContainer/Layout/LayoutToolbar/HBox/CurveEditButtons
@onready var world_view               : WorldViewportContainer = $HSplitContainer/Layout/WorldView
@onready var tooltip_timer            := $ToolTipTimer

@export var SprinklerScene : PackedScene = null
@export var PipeScene : PackedScene = null
@export var DistanceMeasurementScene : PackedScene = null
@export var PolygonScene : PackedScene = null

enum Mode {
	Idle,
	MovingObjects,
	AddSprinkler,
	AddDistMeasureA,
	AddDistMeasureB,
	AddPolygon
}

enum ViewMenuIds {
	ShowOrigin = 0,
	Objects = 2,
	Grid = 3
}

enum ObjectViewMenuIds {
	Images = 0,
	Measurements = 1,
	Polygons = 2,
	Sprinklers = 3
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
				Utils.pop_cursor_shape()
			Mode.MovingObjects:
				Utils.push_cursor_shape(Input.CURSOR_DRAG)
			Mode.AddSprinkler:
				Utils.push_cursor_shape(Input.CURSOR_CROSS)
			Mode.AddDistMeasureA:
				Utils.push_cursor_shape(Input.CURSOR_CROSS)
			Mode.AddDistMeasureB:
				Utils.push_cursor_shape(Input.CURSOR_CROSS)
			Mode.AddPolygon:
				Utils.push_cursor_shape(Input.CURSOR_CROSS)
var sprinkler_to_add : Sprinkler = null
var dist_meas_to_add : DistanceMeasurement = null
var poly_to_add : PolygonNode = null
var undo_redo_ctrl := UndoController.new()

var _selection_controller : WorldObjectSelectionController = WorldObjectSelectionController.new()
var _mouse_move_start_pos_px = null
var _batch_edits_for_prop : StringName = &""
var _curr_batch_undo_op : UndoController.OperationBatch = null
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
	objects_list.world = world_view
	img_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	
	var view_popup := view_menu_button.get_popup() as PopupMenu
	view_popup.hide_on_checkable_item_selection = false
	obj_view_popupmenu.hide_on_checkable_item_selection = false
	grid_view_popupmenu.hide_on_checkable_item_selection = false
	view_popup.id_pressed.connect(_on_view_menu_id_pressed)
	# reparent the object view PopupMenu into the View MenuButton
	obj_view_popupmenu.get_parent().remove_child(obj_view_popupmenu)
	view_popup.set_item_submenu_node(
		view_popup.get_item_index(ViewMenuIds.Objects),
		obj_view_popupmenu)
	# reparent the grid view PopupMenu into the View MenuButton
	grid_view_popupmenu.get_parent().remove_child(grid_view_popupmenu)
	view_popup.set_item_submenu_node(
		view_popup.get_item_index(ViewMenuIds.Grid),
		grid_view_popupmenu)
	
	# add shortcuts
	remove_button.shortcut = Utils.create_shortcut(KEY_DELETE)

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

func start_batch_edit(prop_name: StringName) -> void:
	if _batch_edits_for_prop.length() > 0:
		push_warning("starting new batch edit for '%s', but there was an unstopped batch edit for '%s'" % [prop_name, _batch_edits_for_prop])
	_batch_edits_for_prop = prop_name
	_curr_batch_undo_op = null

func stop_batch_edit() -> void:
	_batch_edits_for_prop = &""
	_curr_batch_undo_op = null

func _handle_left_click_release(pos_in_world_px: Vector2):
	match mode:
		Mode.Idle:
			Utils.pop_cursor_shape()
		Mode.MovingObjects:
			for obj in _selection_controller.selected_objs():
				obj.finish_move()
			stop_batch_edit()
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
			poly_to_add.set_point(_poly_edit_point_idx, pos_in_world_px)
			poly_to_add.set_handle_visible(_poly_edit_point_idx, true)
			poly_to_add.add_point(pos_in_world_px)
			_poly_edit_point_idx = poly_to_add.point_count() - 1
			poly_to_add.set_handle_visible(_poly_edit_point_idx, false)

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
		if _poly_edit_point_idx < poly_to_add.point_count():
			poly_to_add.remove_point(_poly_edit_point_idx)
		poly_to_add.picked = false
		if poly_to_add.point_count() >= 3:
			TheProject.add_object(poly_to_add)
		poly_to_add = null
		mode = Mode.Idle

func _update_ui_after_selection_change():
	var selected_objs := _selection_controller.selected_objs()
	_update_position_lock_buttons()
	remove_button.disabled = selected_objs.is_empty()
	sprink_prop_list.hide()
	img_prop_list.hide()
	poly_prop_list.hide()
	curve_edit_buttons.hide()
	
	if selected_objs.size() == 0:
		return
	
	var all_sprinklers := true
	var all_images := true
	var all_distances := true
	var all_polygons := true
	
	for obj in selected_objs:
		if obj is Sprinkler:
			all_images = false
			all_distances = false
			all_polygons = false
		elif obj is ImageNode:
			all_sprinklers = false
			all_distances = false
			all_polygons = false
		elif obj is DistanceMeasurement:
			all_sprinklers = false
			all_images = false
			all_polygons = false
		elif obj is PolygonNode:
			all_sprinklers = false
			all_images = false
			all_distances = false
	
	var is_single_select = selected_objs.size() == 1
	if all_sprinklers:
		sprink_prop_list.clear_sprinklers()
		for obj in selected_objs:
			sprink_prop_list.add_sprinkler(obj)
		sprink_prop_list.show()
	elif all_images && is_single_select:
		img_prop_list.img_node = selected_objs[0]
		img_prop_list.show()
	elif all_distances && is_single_select:
		pass
	elif all_polygons && is_single_select:
		poly_prop_list.poly_node = selected_objs[0]
		poly_prop_list.show()
		curve_edit_buttons.show()

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

func _on_add_sprinkler_pressed():
	sprinkler_to_add = SprinklerScene.instantiate()
	sprinkler_to_add.user_label = TheProject.get_unique_name('Sprinkler')
	sprinkler_to_add.position = world_view.global_xy_to_pos_in_world(get_global_mouse_position())
	world_view.objects.add_child(sprinkler_to_add)
	mode = Mode.AddSprinkler

func _on_add_pipe_pressed() -> void:
	# since pipes are similar to DistanceMeasurement nodes, we'll reused the
	# "adding" logic for it. should work for now ...
	dist_meas_to_add = PipeScene.instantiate()
	dist_meas_to_add.user_label = TheProject.get_unique_name('Pipe')
	world_view.objects.add_child(dist_meas_to_add)
	mode = Mode.AddDistMeasureA

func _on_add_image_pressed():
	img_dialog.popup_centered()

func _on_add_dist_measure_pressed():
	dist_meas_to_add = DistanceMeasurementScene.instantiate()
	dist_meas_to_add.user_label = TheProject.get_unique_name('DistanceMeasurement')
	world_view.objects.add_child(dist_meas_to_add)
	mode = Mode.AddDistMeasureA

func _on_add_polygon_pressed():
	poly_to_add = PolygonScene.instantiate()
	world_view.objects.add_child(poly_to_add)
	poly_to_add.user_label = TheProject.get_unique_name('PolygonNode')
	poly_to_add.picked = true
	poly_to_add.add_point(Vector2())
	poly_to_add.set_handle_visible(0, false)
	_poly_edit_point_idx = 0
	mode = Mode.AddPolygon

func _on_remove_button_pressed():
	for obj in _selection_controller.selected_objs():
		undo_redo_ctrl.push_undo_op(WorldObjectUndoRedoOps.AddOrRemove.new(
			world_view,
			obj,
			true)) # is_remove
		TheProject.remove_object(obj)
	_selection_controller.clear_selection()

func _on_TheProject_node_changed(obj, change_type: TheProject.ChangeType, args):
	var obj_in_world = obj in world_view.objects.get_children()
	match change_type:
		TheProject.ChangeType.ADD:
			if not obj_in_world:
				world_view.objects.add_child(obj)
			undo_redo_ctrl.push_undo_op(WorldObjectUndoRedoOps.AddOrRemove.new(
				world_view,
				obj,
				false)) # is_remove
			obj.picked_state_changed.connect(_on_pickable_object_pick_state_changed.bind(obj))
			if obj is PolygonNode:
				obj.edited.connect(_on_polygon_edited)
			_selection_controller.clear_selection()
			obj.picked = true
		TheProject.ChangeType.REMOVE:
			if obj_in_world:
				world_view.objects.remove_child(obj)
		TheProject.ChangeType.PROP_EDIT:
			var prop_name : StringName = args[0]
			var old_value = args[1]
			var new_value = args[2]
			var undo_op := UndoController.PropEditUndoOperation.new(
					obj,
					prop_name,
					old_value,
					new_value)
			if prop_name == _batch_edits_for_prop:
				# batch undo operations for a multi-object edits
				if _curr_batch_undo_op != null:
					_curr_batch_undo_op.push_op(undo_op)
				else:
					_curr_batch_undo_op = undo_redo_ctrl.push_undo_op(undo_op)
			else:
				undo_redo_ctrl.push_undo_op(undo_op)

func _on_TheProject_opened():
	_selection_controller.clear_selection()
	undo_redo_ctrl.reset()
	
	# restore "View" options
	var view_popup := view_menu_button.get_popup() as PopupMenu
	Utils.set_item_checked_by_id(view_popup, ViewMenuIds.ShowOrigin, TheProject.layout_pref.show_origin)
	Utils.set_item_checked_by_id(obj_view_popupmenu, ObjectViewMenuIds.Images, TheProject.layout_pref.show_images)
	Utils.set_item_checked_by_id(obj_view_popupmenu, ObjectViewMenuIds.Measurements, TheProject.layout_pref.show_measurements)
	Utils.set_item_checked_by_id(obj_view_popupmenu, ObjectViewMenuIds.Polygons, TheProject.layout_pref.show_polygons)
	Utils.set_item_checked_by_id(obj_view_popupmenu, ObjectViewMenuIds.Sprinklers, TheProject.layout_pref.show_sprinklers)
	Utils.set_item_checked_by_id(grid_view_popupmenu, GridViewMenuIds.ShowGrid, TheProject.layout_pref.show_grid)
	
	# restore world view preferences
	world_view.show_grid = TheProject.layout_pref.show_grid
	world_view.show_origin = TheProject.layout_pref.show_origin
	world_view.major_spacing_ft = TheProject.layout_pref.grid_major_spacing_ft
	world_view.camera2d.position = TheProject.layout_pref.camera_pos
	world_view.camera2d.zoom = Vector2(1.0, 1.0) * TheProject.layout_pref.zoom
	world_view._on_pan_zoom_controller_zoom_changed(1.0, TheProject.layout_pref.zoom)

func _on_LayoutPref_view_show_state_changed(property: StringName, new_value: bool):
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
				if obj is DistanceMeasurement:
					obj.visible = new_value
		LayoutPreferences.PROP_KEY_SHOW_POLYGONS:
			for obj in world_view.objects.get_children():
				if obj is PolygonNode:
					obj.visible = new_value
		LayoutPreferences.PROP_KEY_SHOW_SPRINKLERS:
			for obj in world_view.objects.get_children():
				if obj is Sprinkler:
					obj.visible = new_value

func _on_img_dialog_file_selected(path):
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
	undo_redo_ctrl.push_undo_op(undo_op)
	TheProject.has_edits = true

func _on_pickable_object_pick_state_changed(obj: WorldObject) -> void:
	if obj.picked:
		_selection_controller.add_to_selection(obj)
	else:
		_selection_controller.remove_from_selection(obj)

func _on_polygon_edited(undo_op: UndoController.UndoOperation) -> void:
	undo_redo_ctrl.push_undo_op(undo_op)
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
				if ! event.alt_pressed: # let pan take precedence (alt + click + drag)
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
				Utils.push_cursor_shape(Input.CURSOR_POINTING_HAND)
			else:
				Utils.pop_cursor_shape()
		
		var can_start_move := (
			mode != Mode.MovingObjects and
			not is_panning and
			Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and
			not Input.is_key_pressed(MULTI_SELECT_KEY))
		if sprinkler_to_add:
			sprinkler_to_add.position = pos_in_world_px
		elif dist_meas_to_add and mode == Mode.AddDistMeasureB:
			dist_meas_to_add.point_b = pos_in_world_px
		elif poly_to_add:
			if _poly_edit_point_idx < poly_to_add.point_count():
				poly_to_add.set_point(_poly_edit_point_idx, pos_in_world_px)
		elif can_start_move:
			# check if any selected objects are position locked
			var all_movable = true
			var selected_objs := _selection_controller.selected_objs()
			for obj in selected_objs:
				if ! obj.is_movable():
					all_movable = false
					break
			
			# start move operations if all objects are movable
			if ! all_movable:
				Utils.push_cursor_shape(Input.CURSOR_FORBIDDEN)
			else:
				start_batch_edit(&"position")
				for obj in selected_objs:
					obj.start_move()
					mode = Mode.MovingObjects
		
		if mode == Mode.MovingObjects:
			_handle_held_obj_move(pos_in_world_px)

func _on_viewport_container_pan_state_changed(panning: bool) -> void:
	if panning:
		Utils.push_cursor_shape(Input.CURSOR_DRAG)
	else:
		Utils.pop_cursor_shape()

func _on_position_lock_button_pressed() -> void:
	for obj in _selection_controller.selected_objs():
		obj.position_locked = true
	_update_position_lock_buttons()

func _on_position_unlock_button_pressed() -> void:
	for obj in _selection_controller.selected_objs():
		obj.position_locked = false
	_update_position_lock_buttons()

func _on_tool_tip_timer_timeout() -> void:
	if _hovered_obj and mode == Mode.Idle:
		var tip_text := "%s" % _hovered_obj.user_label
		world_view.show_tooltip(tip_text)

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
