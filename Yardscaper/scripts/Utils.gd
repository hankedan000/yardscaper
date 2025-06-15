class_name Utils
extends Object

const PX_PER_FT : float = 12.0 # 1px per inch
const INCHES_PER_FT : float = 12.0
const CFTPS_PER_GPM : float = 0.0022280092365745
const SQINCH_PER_SQFT : float = 144.0

static func ft_to_inches(ft: float) -> float:
	return ft * INCHES_PER_FT

static func inches_to_ft(inches: float) -> float:
	return inches / INCHES_PER_FT

static func ft_to_px(ft: float) -> float:
	return ft * PX_PER_FT

static func px_to_ft(px: float) -> float:
	return px / PX_PER_FT

static func ft_to_px_vec(ft: Vector2) -> Vector2:
	return Vector2(ft_to_px(ft.x), ft_to_px(ft.y))

static func px_to_ft_vec(px: Vector2) -> Vector2:
	return Vector2(px_to_ft(px.x), px_to_ft(px.y))

# US gallons per minute to cubic ft per second
static func gpm_to_cftps(gpm: float) -> float:
	return gpm * CFTPS_PER_GPM

# cubic ft per second to US gallons per minute
static func cftps_to_gpm(cftps: float) -> float:
	return cftps / CFTPS_PER_GPM

# pounds per square inch to pounds per square ft
static func psi_to_psft(psi: float) -> float:
	return psi * SQINCH_PER_SQFT

# pounds per square ft to pounds per square inch
static func psft_to_psi(psft: float) -> float:
	return psft / SQINCH_PER_SQFT

static func pretty_dist(dist_ft: float) -> String:
	# round dist_ft to nearest inch
	dist_ft = round(dist_ft * INCHES_PER_FT) / INCHES_PER_FT
	
	var whole_ft = floor(dist_ft) if dist_ft >= 0 else ceil(dist_ft)
	var whole_in = round(abs(dist_ft - whole_ft) * INCHES_PER_FT)
	return "%0.0f' %0.0f\"" % [whole_ft, whole_in]

static func create_shortcut(letter: Key, ctrl: bool = false, shift: bool = false, alt: bool = false) -> Shortcut:
	var shortcut = Shortcut.new()

	var input_event = InputEventKey.new()

	input_event.keycode = letter
	input_event.ctrl_pressed = ctrl
	input_event.shift_pressed = shift
	input_event.alt_pressed = alt

	shortcut.events = [ input_event ]

	return shortcut

static func world_to_global_px(px: float, zoom_factor: float) -> float:
	return px * zoom_factor

static func global_to_world_px(px: float, zoom_factor: float) -> float:
	return px / zoom_factor

static func world_to_global_size_px(size: Vector2, zoom: Vector2) -> Vector2:
	return Vector2(size.x * zoom.x, size.y * zoom.y)

static func global_to_world_size_px(size: Vector2, zoom: Vector2) -> Vector2:
	return Vector2(size.x / zoom.x, size.y / zoom.y)

static func vect2_to_pair(vec: Vector2) -> Array:
	return [vec.x, vec.y]

static func pair_to_vect2(pair: Array) -> Vector2:
	return Vector2(pair[0], pair[1])

static func get_label_text_size(label: Label, text: String, include_scale: bool = true) -> Vector2:
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

static func set_item_checked_by_id(popup: PopupMenu, id: int, checked: bool) -> void:
	var idx := popup.get_item_index(id)
	popup.set_item_checked(idx, checked)

static func draw_sector(canvas: CanvasItem, center: Vector2, radius: float, angle_from: float, angle_to: float, n_points: int, color: Color) -> void:
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

class ClosestPointInfo:
	var global_position : Vector2 = Vector2()
	var progress : float = 0.0

static func find_closest_point_on_path(path: Path2D, global_point: Vector2) -> ClosestPointInfo:
	var info := ClosestPointInfo.new()
	var pos_in_path_space := global_point - path.global_position
	info.progress = path.curve.get_closest_offset(pos_in_path_space)
	info.global_position = path.global_position + path.curve.sample_baked(info.progress)
	return info

static func find_nearest_baked_point_index(path: Path2D, point: Vector2) -> int:
	var curve := path.curve
	if not curve:
		return -1

	var closest_index := -1
	var closest_distance := INF
	var baked_points := curve.get_baked_points()

	for i in baked_points.size():
		var dist := point.distance_squared_to(baked_points[i])
		if dist < closest_distance:
			closest_distance = dist
			closest_index = i

	return closest_index

static func reparent_as_submenu(menu: PopupMenu, new_parent_menu: PopupMenu, new_parent_item_id: int) -> void:
	var item_index := new_parent_menu.get_item_index(new_parent_item_id)
	if item_index < 0:
		push_error("couldn't find item_index for item_id %d" % new_parent_item_id)
		return
	menu.get_parent().remove_child(menu)
	new_parent_menu.set_item_submenu_node(item_index, menu)
