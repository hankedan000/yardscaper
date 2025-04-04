extends PanelContainer

const MULTI_SELECT_KEY = KEY_SHIFT
const TOOLTIP_DELAY_DURATION_SEC := 1.0

@onready var img_dialog               := $ImgDialog

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
@onready var world_view               : WorldViewportContainer = $HSplitContainer/Layout/WorldView
@onready var img_import_wizard        := $ImageImportWizard
@onready var tooltip_timer            := $ToolTipTimer

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

enum ViewMenuIds {
	ShowOrigin = 0,
	ShowGrid = 1,
	Objects = 2
}

enum ObjectViewMenuIds {
	Images = 0,
	Measurements = 1,
	Polygons = 2,
	Sprinklers = 3
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
			Mode.Panning:
				Utils.push_cursor_shape(Input.CURSOR_DRAG)
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
var undo_redo_ctrl := UndoRedoController.new()

# vars for editing PolygonNode points
var poly_edit_point_idx = 0

var _selected_objs : Array[WorldObject] = []
var _mouse_move_start_pos_px = null
var _move_undo_batch : UndoRedoController.OperationBatch = null
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

func _set_all_cursors(ctrl: Control, cursor_shape: CursorShape) -> void:
	ctrl.set_default_cursor_shape(cursor_shape)
	for child in ctrl.get_children():
		if child is Control:
			_set_all_cursors(child, cursor_shape)

func _ready():
	TheProject.node_changed.connect(_on_TheProject_node_changed)
	TheProject.opened.connect(_on_TheProject_opened)
	TheProject.layout_pref.view_show_state_changed.connect(_on_LayoutPref_view_show_state_changed)
	sprink_prop_list.visible = false
	img_prop_list.visible = false
	poly_prop_list.visible = false
	objects_list.world = world_view
	img_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	
	var view_popup := view_menu_button.get_popup() as PopupMenu
	view_popup.hide_on_checkable_item_selection = false
	obj_view_popupmenu.hide_on_checkable_item_selection = false
	view_popup.id_pressed.connect(_on_view_menu_id_pressed)
	# reparent the object view PopupMenu into the View MenuButton
	obj_view_popupmenu.get_parent().remove_child(obj_view_popupmenu)
	view_popup.set_item_submenu_node(
		view_popup.get_item_index(ViewMenuIds.Objects),
		obj_view_popupmenu)
	
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

func _handle_left_click(_pos_in_world_px: Vector2):
	match mode:
		Mode.Idle:
			if _hovered_obj:
				if not Input.is_key_pressed(MULTI_SELECT_KEY) and (_hovered_obj not in _selected_objs):
					# handle corner case where object is newly selected and
					# we start dragging without releasing yet.
					_clear_selected_objects()
					_hovered_obj.picked = true

func _handle_left_click_release(pos_in_world_px: Vector2):
	match mode:
		Mode.Idle:
			Utils.pop_cursor_shape()
			if not Input.is_key_pressed(MULTI_SELECT_KEY):
				if _hovered_obj == null:
					_clear_selected_objects()
			else:
				_hovered_obj.picked = not _hovered_obj.picked
		Mode.MovingObjects:
			for obj in _selected_objs:
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
		if poly_edit_point_idx < poly_to_add.point_count():
			poly_to_add.remove_point(poly_edit_point_idx)
		poly_to_add.picked = false
		TheProject.add_object(poly_to_add)
		poly_to_add = null
		mode = Mode.Idle

func _clear_selected_objects() -> void:
	# make a copy of the list because setting picked to false
	# will trigger a picked_state_change signal to fire which
	# ends up modifying the _selected_objs list, and we don't
	# want that to happen while we're iterating on it.
	for obj in _selected_objs.duplicate():
		obj.picked = false

func _add_selected_object(obj: WorldObject) -> void:
	if obj == null:
		return
	elif obj in _selected_objs:
		return # don't double add
	_selected_objs.append(obj)
	_update_ui_after_selection_change()

func _remove_selected_object(obj: WorldObject) -> void:
	_selected_objs.erase(obj)
	_update_ui_after_selection_change()

func _update_ui_after_selection_change():
	_update_position_lock_buttons()
	remove_button.disabled = _selected_objs.is_empty()
	sprink_prop_list.hide()
	img_prop_list.hide()
	poly_prop_list.hide()
	
	if _selected_objs.size() != 1:
		return
	
	var obj = _selected_objs[0]
	if obj is Sprinkler:
		sprink_prop_list.sprinkler = obj
		sprink_prop_list.show()
	elif obj is ImageNode:
		img_prop_list.img_node = obj
		img_prop_list.show()
	elif obj is DistanceMeasurement:
		pass
	elif obj is PolygonNode:
		poly_prop_list.poly_node = obj
		poly_prop_list.show()

func _update_position_lock_buttons():
	var all_are_locked = true
	for obj in _selected_objs:
		if not obj.position_locked:
			all_are_locked = false
			break
	
	if _selected_objs.is_empty():
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
			obj.picked_state_changed.connect(_on_pickable_object_pick_state_changed.bind(obj))
			_clear_selected_objects()
			obj.picked = true
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
	
	# restore "View" options
	var view_popup := view_menu_button.get_popup() as PopupMenu
	Utils.set_item_checked_by_id(view_popup, ViewMenuIds.ShowGrid, TheProject.layout_pref.show_grid)
	world_view.show_grid = TheProject.layout_pref.show_grid
	Utils.set_item_checked_by_id(view_popup, ViewMenuIds.ShowOrigin, TheProject.layout_pref.show_origin)
	world_view.show_origin = TheProject.layout_pref.show_origin
	Utils.set_item_checked_by_id(obj_view_popupmenu, ObjectViewMenuIds.Images, TheProject.layout_pref.show_images)
	Utils.set_item_checked_by_id(obj_view_popupmenu, ObjectViewMenuIds.Measurements, TheProject.layout_pref.show_measurements)
	Utils.set_item_checked_by_id(obj_view_popupmenu, ObjectViewMenuIds.Polygons, TheProject.layout_pref.show_polygons)
	Utils.set_item_checked_by_id(obj_view_popupmenu, ObjectViewMenuIds.Sprinklers, TheProject.layout_pref.show_sprinklers)
	
	# restor camera position and zoom level
	world_view.camera2d.position = TheProject.layout_pref.camera_pos
	world_view.camera2d.zoom = Vector2(1.0, 1.0) * TheProject.layout_pref.zoom

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
	print(new_image)
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
		_add_selected_object(obj)
	else:
		_remove_selected_object(obj)

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
						_handle_left_click(pos_in_world_px)
					else:
						_handle_left_click_release(pos_in_world_px)
			MOUSE_BUTTON_RIGHT:
				_cancel_mode() # will only cancel if possible
	elif event is InputEventMouseMotion:
		# detect which object mouse is hovering over
		if mode == Mode.Idle:
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
		
		if sprinkler_to_add:
			sprinkler_to_add.position = pos_in_world_px
		elif dist_meas_to_add and mode == Mode.AddDistMeasureB:
			dist_meas_to_add.point_b = pos_in_world_px
		elif poly_to_add:
			if poly_edit_point_idx < poly_to_add.point_count():
				poly_to_add.set_point(poly_edit_point_idx, pos_in_world_px)
		elif mode != Mode.MovingObjects and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			# check if any selected objects are position locked
			var any_locked = false
			for obj in _selected_objs:
				if obj.position_locked:
					any_locked = true
					break
			
			# start move operations if no objects are locked
			if any_locked:
				Utils.push_cursor_shape(Input.CURSOR_FORBIDDEN)
			else:
				for obj in _selected_objs:
					obj.start_move()
					mode = Mode.MovingObjects
		
		if mode == Mode.MovingObjects:
			_handle_held_obj_move(pos_in_world_px)

func _on_viewport_container_pan_state_changed(panning: bool) -> void:
	if panning:
		mode = Mode.Panning
	else:
		mode = Mode.Idle

func _on_position_lock_button_pressed() -> void:
	for obj in _selected_objs:
		obj.position_locked = true
	_update_position_lock_buttons()

func _on_position_unlock_button_pressed() -> void:
	for obj in _selected_objs:
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
		ViewMenuIds.ShowGrid:
			world_view.show_grid = is_checked
			TheProject.layout_pref.show_grid = is_checked

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
