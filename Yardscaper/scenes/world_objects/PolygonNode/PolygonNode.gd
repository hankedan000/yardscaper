extends WorldObject
class_name PolygonNode

const PERIMETER_WIDTH = 2

const PROP_KEY_COLOR = &"color"
const PROP_KEY_POINTS_FT = &"points_ft"

@export var EditorHandleScene : PackedScene = null

@onready var poly             : Polygon2D = $Polygon2D
@onready var coll_poly        : CollisionPolygon2D = $PickArea/CollisionPolygon2D
@onready var edit_path        : Path2D = $EditPath
@onready var path_follow      : PathFollow2D = $EditPath/PathFollow2D
@onready var add_point_handle : EditorHandle = $EditPath/PathFollow2D/AddPointHandle

var color := Color.MEDIUM_AQUAMARINE:
	set(value):
		var old_value = color
		color = value
		if old_value != color:
			property_changed.emit(self, PROP_KEY_COLOR, old_value, color)
		queue_redraw()

var is_editable : bool = true

var _handle_being_moved : EditorHandle = null
var _handle_init_pos : Vector2 = Vector2() # init position when starting move
var _mouse_init_pos : Vector2 = Vector2() # init position when starting move
var _vertex_handles : Array[EditorHandle] = []

func _ready() -> void:
	super._ready()
	set_process(false)
	set_process_input(false)
	is_editable = true
	_setup_cmn_edit_handle_signals(add_point_handle)
	add_point_handle.get_button().button_down.connect(_on_add_point_handle_button_down)
	add_point_handle.normal_type = EditorHandle.HandleType.None
	add_point_handle.hover_type = EditorHandle.HandleType.Add

func _draw():
	poly.color = color
	if picked or hovering:
		var perim_color = Globals.SELECT_COLOR if picked else Globals.HOVER_COLOR
		var first_point = null
		var prev_point = null
		for point in poly.polygon:
			if first_point == null:
				first_point = point
			if prev_point:
				draw_line(prev_point, point, perim_color, PERIMETER_WIDTH)
			prev_point = point
		if prev_point && first_point:
			draw_line(prev_point, first_point, perim_color, PERIMETER_WIDTH)

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
	var closest_offset := edit_path.curve.get_closest_offset(world_mouse_pos)
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
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && ! event.pressed:
			# stop moving the newly added point
			_handle_being_moved = null
			set_process_input(false)

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
	return is_editable and picked

func get_visual_center() -> Vector2:
	if point_count() == 0:
		return poly.global_position
	return poly.global_position + get_centroid_px()

func get_subclass() -> String:
	return "PolygonNode"

func serialize():
	var obj = super.serialize()
	var points_ft = []
	for point in poly.polygon:
		points_ft.append(Utils.vect2_to_pair(Utils.px_to_ft_vec(point)))
	obj[PROP_KEY_POINTS_FT] = points_ft
	obj[PROP_KEY_COLOR] = color.to_html(true) # with alpha = true
	return obj

func deserialize(obj):
	super.deserialize(obj)
	var points_ft = Utils.dict_get(obj, PROP_KEY_POINTS_FT, [])
	for point in points_ft:
		add_point(Utils.ft_to_px_vec(Utils.pair_to_vect2(point)))
	color = Utils.dict_get(obj, PROP_KEY_COLOR, color)

func _update_info_label():
	info_label.visible = point_count() > 2
	if not info_label.visible:
		return
	
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.text = "%s\n(%0.2f sq. ft)" % [user_label, get_area_ft()]
	_reposition_info_label()

func _reposition_info_label() -> void:
	# compute bounding box size of the new label's text string
	var text_size := Utils.get_label_text_size(info_label, info_label.text)
	# position the label in center of the polygon
	info_label.global_position = get_visual_center() - (text_size / 2.0)

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
		new_handle.position = point
		_setup_cmn_edit_handle_signals(new_handle)
		new_handle.get_button().button_down.connect(_on_vertex_handle_button_down.bind(new_handle))
		_vertex_handles.push_back(new_handle)

	# ----------------------------------------------
	# rebuild the edit_path

	edit_path.curve.clear_points()
	for point in get_closed_points():
		edit_path.curve.add_point(point)

func _enter_edit_state() -> void:
	_update_edit_objects()
	set_process(true)

func _exit_edit_state() -> void:
	edit_path.curve.clear_points()
	add_point_handle.visible = false
	for handle in _vertex_handles:
		handle.queue_free()
	_vertex_handles.clear()
	set_process(false)

# overrides WorldObject::on_zoom_changed()
func on_zoom_changed(new_zoom: float, inv_scale: Vector2) -> void:
	super.on_zoom_changed(new_zoom, inv_scale)
	_reposition_info_label()

func _on_property_changed(_obj: WorldObject, property_key: StringName, _from: Variant, _to: Variant) -> void:
	if is_inside_tree() and property_key == WorldObject.PROP_KEY_USER_LABEL:
		_update_info_label()

func _on_picked_state_changed() -> void:
	if ! is_inside_tree():
		return
	elif point_count() < 3:
		return
	
	if is_editable and picked:
		_enter_edit_state()
	elif is_editable and ! picked:
		_exit_edit_state()

func _on_vertex_handle_button_down(handle: EditorHandle) -> void:
	set_process_input(true)
	_handle_being_moved = handle
	_handle_init_pos = handle.position
	_mouse_init_pos = get_global_mouse_position()

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
		_on_vertex_handle_button_down(_vertex_handles[insert_idx])

func _on_handle_mouse_entered() -> void:
	short_term_position_locked = true

func _on_handle_mouse_exited() -> void:
	short_term_position_locked = false
