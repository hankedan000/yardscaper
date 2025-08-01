extends WorldObject
class_name PolygonNode

const PROP_KEY_COLOR = &"color"
const PROP_KEY_POINTS_FT = &"points_ft"

enum EditMode {
	None, Add, Edit, Remove
}

@export var EditorHandleScene : PackedScene = null

@onready var poly             : Polygon2D = $Polygon2D
@onready var coll_poly        : CollisionPolygon2D = $PickArea/CollisionPolygon2D
@onready var draw_layer       := $ManualDrawLayer
@onready var edit_path        : Path2D = $EditPath
@onready var path_follow      : PathFollow2D = $EditPath/PathFollow2D
@onready var add_point_handle : EditorHandle = $EditPath/PathFollow2D/AddPointHandle

var color := Color.MEDIUM_AQUAMARINE:
	set(value):
		var old_value = color
		color = value
		if _check_and_emit_prop_change(PROP_KEY_COLOR, old_value):
			queue_redraw()

var edit_mode : EditMode = EditMode.None:
	set(value):
		edit_mode = value
		if is_being_edited():
			_enter_edit_state()
		else:
			_exit_edit_state()

var _handle_being_moved : EditorHandle = null
var _handle_init_pos : Vector2 = Vector2() # init position when starting move
var _mouse_init_pos : Vector2 = Vector2() # init position when starting move
var _is_new_vertex : bool = false
var _vertex_handles : Array[EditorHandle] = []

# @return true if initialization was successful, false otherwise
func _ready() -> void:
	super._ready()
	set_process(false)
	set_process_input(false)
	_setup_cmn_edit_handle_signals(add_point_handle)
	add_point_handle.get_button().button_down.connect(_on_add_point_handle_button_down)

func _draw():
	draw_layer.queue_redraw()
	poly.color = color

func _process(_delta: float) -> void:
	# even though the getter says 'global', it seems to return a position
	# within the world. regardless, it works for what we need in here.
	var world_mouse_pos := get_global_mouse_position()
	if _handle_being_moved:
		var mouse_delta_pos := world_mouse_pos - _mouse_init_pos
		_handle_being_moved.position = _handle_init_pos + mouse_delta_pos
		set_point(_handle_being_moved.user_id, _handle_being_moved.position)
	
	# update the add point position to the closest point on the edit_path.
	# we're also computing the mouse's relative distance to the edit_path
	# so we can make the add_handle visible when the mouse is within range
	# of the edit_path. we also compute the dist to the closest polygon
	# control handle so that we can hide the add_handle when the mouse is
	# close to those. if we didn't do this, the add_handle and polygon
	# control handles would overlap and make it difficult to select a
	# control handle.
	var mouse_pos_within_polygon_space := world_mouse_pos - global_position
	var closest_offset := edit_path.curve.get_closest_offset(mouse_pos_within_polygon_space)
	var closest_point_on_path := edit_path.curve.sample_baked(closest_offset)
	var dist_to_clostest_point : float = -1.0
	for point in poly.polygon:
		var dist := (point - closest_point_on_path).length()
		if dist_to_clostest_point < 0.0:
			dist_to_clostest_point = dist
		elif dist < dist_to_clostest_point:
			dist_to_clostest_point = dist
	path_follow.progress = closest_offset
	add_point_handle.visible = true
	if dist_to_clostest_point >= 0 && dist_to_clostest_point < 16:
		add_point_handle.visible = false

func _input(event: InputEvent) -> void:
	if ! _handle_being_moved:
		push_warning("_input called, handle is null (ie. not moving a handle). disabling process.")
		set_process(false)
		return
	
	# see if mouse button is being released so we can stop the
	# vertex_point movement.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && ! event.pressed:
			editor_handle_state_change.emit(self, _handle_being_moved, WorldObject.EditorHandleState.ButtonUp)
			_stop_vertex_movement()

func add_point(point: Vector2) -> void:
	if ! is_inside_tree():
		push_error("must be inside tree")
		return
	# can't do direct append of point onto polygon.
	# need to assign polygon with edited list of points
	var new_points : PackedVector2Array = poly.polygon
	new_points.append(point)
	poly.polygon = new_points
	coll_poly.polygon = new_points
	_update_edit_objects()
	_update_info_label()
	queue_redraw()

func set_handle_visible(idx: int, new_visible: bool) -> void:
	if idx < _vertex_handles.size():
		_vertex_handles[idx].visible = new_visible

func set_point(idx: int, point: Vector2) -> void:
	if idx < point_count():
		poly.polygon[idx] = point
		coll_poly.polygon[idx] = point
	
	# update the edit-related objects
	if idx < _vertex_handles.size():
		_vertex_handles[idx].position = point
	var edit_path_point_count := edit_path.curve.point_count
	if edit_path_point_count > 0:
		edit_path.curve.set_point_position(idx, point)
		if idx == 0 and edit_path_point_count >= 3:
			# move last point in path too to keep the circuit intact
			edit_path.curve.set_point_position(edit_path_point_count - 1, point)
	
	_update_info_label()
	queue_redraw()

func insert_point(at_idx: int, point: Vector2):
	var new_points : PackedVector2Array = poly.polygon
	new_points.insert(at_idx, point)
	poly.polygon = new_points
	coll_poly.polygon = new_points
	_update_edit_objects()
	_update_info_label()
	queue_redraw()

func remove_point(idx: int):
	# can't do direct remove of point in polygon.
	# need to assign polygon with edited list of points
	var new_points : PackedVector2Array = poly.polygon
	new_points.remove_at(idx)
	poly.polygon = new_points
	coll_poly.polygon = new_points
	_update_edit_objects()
	_update_info_label()
	queue_redraw()

func point_count() -> int:
	return poly.polygon.size()

func get_closed_points() -> PackedVector2Array:
	var points = poly.polygon # returns a copy
	if points.size() >= 2:
		points.append(points[0])
	return points

# math is from https://www.omnicalculator.com/math/centroid
func get_signed_area_px() -> float:
	var area = 0.0
	var points = get_closed_points()
	var n = points.size()
	for i in range(n - 1):
		var p1 = points[i]
		var p2 = points[i+1]
		area += ((p1.x * p2.y) - (p2.x * p1.y))
	return area / 2.0

# math is from https://www.omnicalculator.com/math/centroid
func get_centroid_px() -> Vector2:
	var c = Vector2()
	var points = get_closed_points()
	var n = points.size()
	for i in range(n - 1):
		var p1 = points[i]
		var p2 = points[i+1]
		var t = ((p1.x * p2.y) - (p2.x * p1.y))
		c.x += (p1.x + p2.x) * t
		c.y += (p1.y + p2.y) * t
	return c / (6.0 * get_signed_area_px())

func get_area_px() -> float:
	return abs(get_signed_area_px())

func get_area_ft() -> float:
	var px_per_ft = Utils.ft_to_px(1.0)
	return get_area_px() / (px_per_ft * px_per_ft)

func is_being_edited() -> bool:
	return picked and edit_mode != EditMode.None

func get_visual_center() -> Vector2:
	if point_count() == 0:
		return poly.global_position
	return poly.global_position + get_centroid_px()

func get_type_name() -> StringName:
	return TypeNames.POLYGON_NODE

func get_bounding_box() -> Rect2:
	if poly.polygon.size() == 0:
		return super.get_bounding_box()
	var box := Rect2(poly.polygon[0], Vector2(1,1))
	for idx in range(1, poly.polygon.size()):
		box = box.expand(poly.polygon[idx])
	return box

func serialize() -> Dictionary:
	var obj = super.serialize()
	var points_ft = []
	for point in poly.polygon:
		points_ft.append(Utils.vect2_to_pair(Utils.px_to_ft_vec(point)))
	obj[PROP_KEY_POINTS_FT] = points_ft
	obj[PROP_KEY_COLOR] = color.to_html(true) # with alpha = true
	return obj

func deserialize(obj) -> void:
	super.deserialize(obj)
	if ! is_inside_tree():
		await ready
	var points_ft = DictUtils.get_w_default(obj, PROP_KEY_POINTS_FT, [])
	for point in points_ft:
		add_point(Utils.ft_to_px_vec(Utils.pair_to_vect2(point)))
	color = DictUtils.get_w_default(obj, PROP_KEY_COLOR, color)

func _update_info_label():
	info_label.visible = point_count() > 2
	if not info_label.visible:
		return
	
	info_label.position = get_visual_center()
	info_label.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.text = "%s\n(%0.2f sq. ft)" % [user_label, get_area_ft()]

func _setup_cmn_edit_handle_signals(handle: EditorHandle) -> void:
	var button := handle.get_button()
	button.mouse_entered.connect(_on_handle_mouse_entered)
	button.mouse_exited.connect(_on_handle_mouse_exited)

func _update_edit_objects() -> void:
	if ! is_being_edited():
		return
	
	# ----------------------------------------------
	# rebuild the vertex handles
	
	for handle in _vertex_handles:
		handle.queue_free()
	_vertex_handles.clear()
	# add EditorHanlder's at each polygon control point
	for point_idx in point_count():
		var point : Vector2 = poly.polygon[point_idx]
		var new_handle : EditorHandle = EditorHandleScene.instantiate()
		$EditHandles.add_child(new_handle)
		new_handle.user_id = point_idx
		new_handle.normal_type = EditorHandle.HandleType.Sharp
		new_handle.modulate_on_hover = Color.AQUA
		new_handle.label_show_mode = EditorHandle.LabelShowMode.HoverOrPressed
		new_handle.position = point
		_setup_cmn_edit_handle_signals(new_handle)
		var handle_button := new_handle.get_button()
		handle_button.button_mask = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT
		handle_button.button_down.connect(_on_vertex_handle_button_down.bind(new_handle, false))
		_vertex_handles.push_back(new_handle)

	# ----------------------------------------------
	# rebuild the edit_path

	edit_path.curve.clear_points()
	for point in get_closed_points():
		edit_path.curve.add_point(point)
	add_point_handle.visible = false

func _enter_edit_state() -> void:
	_update_edit_objects()
	set_process(edit_mode == EditMode.Add || edit_mode == EditMode.Edit)

func _exit_edit_state() -> void:
	edit_path.curve.clear_points()
	add_point_handle.visible = false
	for handle in _vertex_handles:
		handle.queue_free()
	_vertex_handles.clear()
	set_process(false)

func _stop_vertex_movement() -> void:
	var undo_op : UndoController.UndoOperation = null
	if _is_new_vertex:
		undo_op = PolygonUndoOps.PointAdd.new(
			self,
			_handle_being_moved.user_id,  # idx
			_handle_being_moved.position) # point
	else:
		undo_op = PolygonUndoOps.PointMove.new(
			self,
			_handle_being_moved.user_id,  # idx
			_handle_init_pos,             # from_point
			_handle_being_moved.position) # to_point
	editor_handle_state_change.emit(self, _handle_being_moved, WorldObject.EditorHandleState.MoveStop)
	_handle_being_moved = null
	_is_new_vertex = false
	set_process_input(false)
	undoable_edit.emit(undo_op)

func _on_property_changed(_obj: WorldObject, property_key: StringName, _from: Variant, _to: Variant) -> void:
	if is_inside_tree() and property_key == WorldObject.PROP_KEY_USER_LABEL:
		_update_info_label()

func _on_picked_state_changed(_wobj: WorldObject, _new_state: bool) -> void:
	if ! is_inside_tree():
		return
	elif point_count() < 3:
		return
	
	if picked:
		_enter_edit_state()
	else:
		_exit_edit_state()

enum ClickAction {
		None, StartMove, Remove
	}

func _on_vertex_handle_button_down(handle: EditorHandle, is_new_vertex: bool) -> void:
	editor_handle_state_change.emit(self, handle, WorldObject.EditorHandleState.ButtonDown)
	var action := ClickAction.None
	if edit_mode == EditMode.Remove:
		action = ClickAction.Remove
	elif edit_mode == EditMode.Edit && Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		action = ClickAction.Remove
	elif edit_mode == EditMode.Edit && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		action = ClickAction.StartMove
	elif is_new_vertex: # adding new vertex case
		action = ClickAction.StartMove
	
	match action:
		ClickAction.None:
			pass
		ClickAction.StartMove:
			set_process_input(true)
			_handle_being_moved = handle
			_handle_init_pos = handle.position
			_is_new_vertex = is_new_vertex
			_mouse_init_pos = get_global_mouse_position()
			editor_handle_state_change.emit(self, _handle_being_moved, WorldObject.EditorHandleState.MoveStart)
		ClickAction.Remove:
			if point_count() <= 3:
				# polygons need to keep at least 3 points to still exist
				return
			var undo_op := PolygonUndoOps.PointRemove.new(
				self,
				handle.user_id,  # idx
				handle.position) # point
			remove_point(handle.user_id)
			undoable_edit.emit(undo_op)

# located the next vertex point follow the offset location of the curve.
# the return index is intended to be used with Curve2D.add_point().
# @param[in] curve - the curve to search over
# @param[in] to_offset - the the offset distance on the curve to search
# relative to.
# @return the found index
func _curve2d_find_insert_idx(curve: Curve2D, to_offset: float) -> int:
	for idx in range(curve.point_count):
		var point := curve.get_point_position(idx)
		var point_offset := curve.get_closest_offset(point)
		if point_offset >= to_offset:
			return idx
	return curve.point_count - 1

func _on_add_point_handle_button_down() -> void:
	var insert_offset := path_follow.progress
	var insert_idx := _curve2d_find_insert_idx(edit_path.curve, path_follow.progress)
	if insert_idx >= 1:
		add_point_handle.visible = false
		var new_point := edit_path.curve.sample_baked(insert_offset)
		insert_point(insert_idx, new_point)
		_on_vertex_handle_button_down(_vertex_handles[insert_idx], true)

func _on_handle_mouse_entered() -> void:
	short_term_position_locked = true

func _on_handle_mouse_exited() -> void:
	short_term_position_locked = false
