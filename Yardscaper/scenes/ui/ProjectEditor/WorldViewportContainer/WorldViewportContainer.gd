extends Control
class_name WorldViewportContainer

signal world_object_reordered(from_idx: int, to_idx: int)
signal pan_state_changed(panning: bool)

const MAJOR_LINE_WIDTH := 1
const ORIGIN_VERT_COLOR := Color.LIME_GREEN
const ORIGIN_HORZ_COLOR := Color.INDIAN_RED

@onready var viewport          : Viewport = $ViewportContainer/Viewport
@onready var objects           := $ViewportContainer/Viewport/Objects
@onready var pan_zoom_ctrl     : PanZoomController = $ViewportContainer/Viewport/PanZoomController
@onready var camera2d          : Camera2D = $ViewportContainer/Viewport/Camera2D
@onready var cursor            : Area2D = $ViewportContainer/Viewport/Cursor
@onready var tooltip_label     : Label = $ViewportContainer/Viewport/ToolTipLabel
@onready var cursor_pos_label  : Label = $CursorPositionLabel

var show_grid = true:
	set(value):
		show_grid = value
		queue_redraw()

var show_origin = true:
	set(value):
		show_origin = value
		queue_redraw()

var show_cursor_position_label = true:
	set(value):
		show_cursor_position_label = value
		cursor_pos_label.visible = value

var show_cursor_crosshairs = false:
	set(value):
		show_cursor_crosshairs = value
		queue_redraw()

var major_spacing_ft : Vector2 = Vector2(5, 5):
	set(value):
		major_spacing_ft = value
		queue_redraw()

var major_line_color : Color = Color.LIGHT_SLATE_GRAY:
	set(value):
		major_line_color = value
		queue_redraw()

func _draw():
	if show_grid:
		_draw_grid(major_spacing_ft, major_line_color, MAJOR_LINE_WIDTH)
	if show_origin:
		_draw_origin()
	if show_cursor_crosshairs:
		_draw_cursor_crosshairs()

func show_tooltip(text: String) -> void:
	tooltip_label.text = text
	tooltip_label.size = Utils.get_label_text_size(tooltip_label, text)
	tooltip_label.position = cursor.position
	tooltip_label.show()

func hide_tooltip() -> void:
	if is_instance_valid(tooltip_label):
		tooltip_label.hide()

# move a world object from one position to another
# @return true if move was applied, false otherwise
func reorder_world_object(from_idx: int, to_idx: int) -> bool:
	var object_count = objects.get_child_count()
	if from_idx < 0 or from_idx >= object_count:
		push_warning("from_idx (%d) out of range. object_count = %d" % [from_idx, object_count])
		return false
	elif to_idx < 0 or to_idx >= object_count:
		push_warning("to_idx (%d) out of range. object_count = %d" % [to_idx, object_count])
		return false
	elif from_idx == to_idx:
		push_warning("move request does nothing")
		return false
	var obj = objects.get_child(from_idx)
	objects.move_child(obj, to_idx)
	world_object_reordered.emit(from_idx, to_idx)
	return true

func get_zoom() -> float:
	return camera2d.zoom.x

# move a world object to another draw order index
# @return -1 if obj doesn't exist, else the object's order index
func get_object_order_idx(obj: WorldObject) -> int:
	var children = objects.get_children()
	return children.find(obj, 0)

func get_image_of_current_view() -> Image:
	return viewport.get_texture().get_image()

func get_zone_images(zone_rects: Array[Rect2]) -> Array[Image]:
	# create a new vieport that we can use for rendering
	var export_viewport := SubViewport.new()
	export_viewport.size = viewport.size
	export_viewport.disable_3d = true
	export_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(export_viewport)
	
	# create a camera for the viewport
	var export_camera := Camera2D.new()
	export_camera.position = camera2d.position
	export_camera.zoom = camera2d.zoom
	export_viewport.add_child(export_camera)
	
	# duplicate all the WorldObjects into the new viewport
	for obj in objects.get_children():
		export_viewport.add_child(obj.duplicate())
	
	var imgs: Array[Image] = []
	
	for zone_rect in zone_rects:
		Utils.fit_camera_to_rect(export_camera, zone_rect, 0.1)
		
		# i expected to wait for at least 1 frame so it could rerender, but
		# for some reason it needed 2 frames.
		await get_tree().process_frame
		await get_tree().process_frame
		
		imgs.push_back(export_viewport.get_texture().get_image())
	
	export_viewport.queue_free()
	
	return imgs

func global_xy_to_pos_in_world(global_pos: Vector2) -> Vector2:
	var pos_rel_to_world := global_pos - self.global_position
	return pan_zoom_ctrl.local_pos_to_world(pos_rel_to_world)

func get_pickable_under_cursor() -> WorldObject:
	# build a list of pickable WorldObjects that are under the mouse
	var pickable_objs : Array[WorldObject] = []
	for pick_area in cursor.get_overlapping_areas():
		var pick_obj := pick_area.get_parent() as WorldObject
		if ! is_instance_valid(pick_obj):
			continue
		elif ! is_instance_valid(pick_obj.world):
			continue
		elif not pick_obj.visible:
			continue
		pickable_objs.push_back(pick_obj)
	
	# sort the array based on distance from mouse location to the obj's visual
	# center point. objects that is closest to the mouse will be first in list.
	pickable_objs.sort_custom(_sort_by_dist_to_poi.bind(cursor.global_position))
	if pickable_objs.is_empty():
		return null
	return pickable_objs[0]

# custom sort function to order objects based on a distant to Poin Of Interest
# @param[in] a - the first object
# @param[in] b - the second object
# @param[in] poi - the global position represent the Point Of Interest
# @return true if a is closer, false if b is closer
static func _sort_by_dist_to_poi(a: WorldObject, b: WorldObject, poi: Vector2) -> bool:
	var vec_to_a := poi - a.get_visual_center()
	var vec_to_b := poi - b.get_visual_center()
	return vec_to_a.length_squared() < vec_to_b.length_squared()

# @param[in] rect - the rectangle to fit the view to
# @param[in] padding - ratio to grow the box by on each side
func fit_view_to_rect(rect: Rect2, padding: float = 0.0) -> void:
	Utils.fit_camera_to_rect(camera2d, rect, padding)
	queue_redraw()

func _draw_origin():
	var origin_pos_local = pan_zoom_ctrl.world_pos_to_local(Vector2(0, 0))
	var visible_rect_size := viewport.get_visible_rect().size
	if origin_pos_local.x >= 0 and origin_pos_local.x < visible_rect_size.x:
		_draw_vert_lines(
			origin_pos_local.x,  # start_x
			0.0,                 # step,
			visible_rect_size.y, # height
			1,                   # n_lines,
			ORIGIN_VERT_COLOR,   # color
			MAJOR_LINE_WIDTH)    # line_width
	if origin_pos_local.y >= 0 and origin_pos_local.y < visible_rect_size.y:
		_draw_horz_lines(
			origin_pos_local.y,  # start_y
			0.0,                 # step
			visible_rect_size.x, # width
			1,                   # n_lines
			ORIGIN_HORZ_COLOR,   # color
			MAJOR_LINE_WIDTH)    # line_width

func _draw_cursor_crosshairs() -> void:
	var cursor_pos_local := pan_zoom_ctrl.world_pos_to_local(cursor.position) as Vector2
	var visible_rect_size := viewport.get_visible_rect().size
	_draw_horz_lines(
		cursor_pos_local.y, # start_y
		0.0,                # step
		visible_rect_size.x,# width
		1,                  # n_lines
		Color.WHITE,        # color
		1)                  # line_width
	_draw_vert_lines(
		cursor_pos_local.x, # start_x
		0.0,                # step
		visible_rect_size.y,# width
		1,                  # n_lines
		Color.WHITE,        # color
		1)                  # line_width

func _draw_grid(grid_spacing_ft: Vector2, color: Color, line_width: int):
	var visible_rect_size := viewport.get_visible_rect().size
	var visible_world_size := Utils.global_to_world_size_px(
		visible_rect_size, camera2d.zoom)
	
	var spacing_world := Utils.ft_to_px_vec(grid_spacing_ft)
	var vert_spacing_global := Utils.world_to_global_px(
		spacing_world.x, camera2d.zoom.x)
	var horz_spacing_global := Utils.world_to_global_px(
		spacing_world.y, camera2d.zoom.y)
	var n_vert_lines = ceil(visible_world_size.x / spacing_world.x)
	var n_horz_lines = ceil(visible_world_size.y / spacing_world.y)
	
	var upper_left_pos_world = pan_zoom_ctrl.local_pos_to_world(Vector2(0, 0))
	var first_major_grid_pos_world := Vector2(
		ceil(upper_left_pos_world.x / spacing_world.x) * spacing_world.x,
		ceil(upper_left_pos_world.y / spacing_world.y) * spacing_world.y)
	var first_major_grid_pos_local := Vector2(
		(first_major_grid_pos_world.x - upper_left_pos_world.x) * camera2d.zoom.x,
		(first_major_grid_pos_world.y - upper_left_pos_world.y) * camera2d.zoom.y)
	_draw_vert_lines(
		first_major_grid_pos_local.x,
		vert_spacing_global, # step (px)
		visible_rect_size.y, # height (px)
		n_vert_lines, # n_lines
		color,
		line_width);
	_draw_horz_lines(
		first_major_grid_pos_local.y,
		horz_spacing_global, # step (px)
		visible_rect_size.x, # width (px)
		n_horz_lines, # n_lines
		color,
		line_width);

func _draw_vert_lines(start_x: float, step: float, height: float, n_lines: int, color: Color, line_width: int):
	for i in range(n_lines):
		var x_pos = start_x + step * i
		draw_line(
			Vector2(x_pos, 0),
			Vector2(x_pos, height),
			color,
			line_width)

func _draw_horz_lines(start_y: float, step: float, width: float, n_lines: int, color: Color, line_width: int):
	for i in range(n_lines):
		var y_pos = start_y + step * i
		draw_line(
			Vector2(0, y_pos),
			Vector2(width, y_pos),
			color,
			line_width)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var pos_in_world_px = global_xy_to_pos_in_world(event.global_position)
		var pos_in_world_ft = Utils.px_to_ft_vec(pos_in_world_px)
		var x_pretty = Utils.pretty_dist(pos_in_world_ft.x)
		var y_pretty = Utils.pretty_dist(pos_in_world_ft.y)
		cursor.position = pos_in_world_px
		cursor_pos_label.text = "%s, %s" % [x_pretty, y_pretty]
		
		if show_cursor_crosshairs:
			queue_redraw()

func _on_pan_zoom_controller_pan_changed(_delta: Vector2) -> void:
	queue_redraw() # to redraw grid & origin

func _on_pan_zoom_controller_pan_state_changed(panning: bool) -> void:
	pan_state_changed.emit(panning)

func _on_pan_zoom_controller_zoom_changed(_old_zoom: float, new_zoom: float) -> void:
	queue_redraw() # to redraw grid & origin
	
	# scale the cursor so that it always stays at the same size,
	# regardless of zoom level.
	var inv_scale := Vector2(1.0, 1.0) * (1.0 / new_zoom)
	cursor.scale = inv_scale
	tooltip_label.scale = inv_scale
	
	for gizmo in get_tree().get_nodes_in_group(&"gizmos") as Array[Node2D]:
		gizmo.on_zoom_changed(new_zoom, inv_scale)
