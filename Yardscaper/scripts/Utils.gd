extends Node

const PX_PER_FT : float = 12.0 # 1px per inch
const INCHES_PER_FT : float = 12.0

func ft_to_px(ft: float) -> float:
	return ft * PX_PER_FT

func px_to_ft(px: float) -> float:
	return px / PX_PER_FT

func ft_to_px_vec(ft: Vector2) -> Vector2:
	return Vector2(ft_to_px(ft.x), ft_to_px(ft.y))

func px_to_ft_vec(px: Vector2) -> Vector2:
	return Vector2(px_to_ft(px.x), px_to_ft(px.y))

func pretty_dist(dist_ft: float) -> String:
	# round dist_ft to nearest inch
	dist_ft = round(dist_ft * INCHES_PER_FT) / INCHES_PER_FT
	
	var whole_ft = floor(dist_ft) if dist_ft >= 0 else ceil(dist_ft)
	var whole_in = round(abs(dist_ft - whole_ft) * INCHES_PER_FT)
	return "%0.0f' %0.0f\"" % [whole_ft, whole_in]

func create_shortcut(letter: Key, ctrl: bool = false, shift: bool = false, alt: bool = false) -> Shortcut:
	var shortcut = Shortcut.new()

	var input_event = InputEventKey.new()

	input_event.keycode = letter
	input_event.ctrl_pressed = ctrl
	input_event.shift_pressed = shift
	input_event.alt_pressed = alt

	shortcut.events = [ input_event ]

	return shortcut

func world_to_global_px(px: float, zoom_factor: float) -> float:
	return px * zoom_factor

func global_to_world_px(px: float, zoom_factor: float) -> float:
	return px / zoom_factor

func world_to_global_size_px(size: Vector2, zoom: Vector2) -> Vector2:
	return Vector2(size.x * zoom.x, size.y * zoom.y)

func global_to_world_size_px(size: Vector2, zoom: Vector2) -> Vector2:
	return Vector2(size.x / zoom.x, size.y / zoom.y)

func vect2_to_pair(vec: Vector2) -> Array:
	return [vec.x, vec.y]

func pair_to_vect2(pair: Array) -> Vector2:
	return Vector2(pair[0], pair[1])

var _prev_cursor_shape : Input.CursorShape = Input.CURSOR_ARROW
var _curr_cursor_shape : Input.CursorShape = Input.CURSOR_ARROW

func push_cursor_shape(cursor_shape: Input.CursorShape) -> void:
	if cursor_shape != _curr_cursor_shape:
		_prev_cursor_shape = _curr_cursor_shape
		_curr_cursor_shape = cursor_shape
		Input.set_default_cursor_shape(cursor_shape)

func pop_cursor_shape() -> Input.CursorShape:
	if _prev_cursor_shape != _curr_cursor_shape:
		_curr_cursor_shape = _prev_cursor_shape
		_prev_cursor_shape = Input.CURSOR_ARROW
		Input.set_default_cursor_shape(_curr_cursor_shape)
	return _curr_cursor_shape

func get_label_text_size(label: Label, text: String, include_scale: bool = true) -> Vector2:
	var font := label.get_theme_font(&"font")
	var text_size := font.get_multiline_string_size(
		text,
		label.horizontal_alignment,
		(int)(label.size.x) if label.clip_text else -1, # width
		label.get_theme_font_size(&"font_size"),
		-1, # max_lines (unlimited)
		TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND,
		label.justification_flags,
		label.text_direction as TextServer.Direction,
		TextServer.ORIENTATION_HORIZONTAL)
	if include_scale:
		text_size.x *= label.scale.x
		text_size.y *= label.scale.y
	return text_size

func set_item_checked_by_id(popup: PopupMenu, id: int, checked: bool) -> void:
	var idx := popup.get_item_index(id)
	popup.set_item_checked(idx, checked)

func draw_sector(canvas: CanvasItem, center: Vector2, radius: float, angle_from: float, angle_to: float, n_points: int, color: Color) -> void:
	if n_points <= 2:
		printerr("n_points must be > 2. n_points = %d" % [n_points])
		return

	var angle_step = (angle_to - angle_from) / (n_points - 1)
	var points = PackedVector2Array()
	points.push_back(center)
	for i in range(n_points):
		var angle_point = angle_from + i * angle_step
		points.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)

	canvas.draw_polygon(points, [color])
