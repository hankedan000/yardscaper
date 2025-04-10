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

func dict_get(dict: Dictionary, key: Variant, default_value=null):
	if dict.has(key):
		return dict[key]
	return default_value

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

func to_json_file(obj, filepath: String, indent="  ", sort_key=true, full_precision=true) -> bool:
	var obj_str = JSON.stringify(obj, indent,  sort_key, full_precision)
	var json_file = FileAccess.open(filepath, FileAccess.WRITE)
	if json_file:
		json_file.store_string(obj_str)
		json_file.close()
	else:
		push_error("failed to save to '%s'" % [filepath])
		return false
	return true

func from_json_file(filepath: String):
	var json_file = FileAccess.open(filepath, FileAccess.READ)
	if json_file == null:
		push_error("failed to open json file '%s'" % [filepath])
		return null
	var obj_str = json_file.get_as_text()
	var json = JSON.new()
	if json.parse(obj_str) == OK:
		return json.data
	push_error("failed to parse JSON object from str '%s'" % [obj_str])
	return null

func vect2_to_pair(vec: Vector2) -> Array:
	return [vec.x, vec.y]

func pair_to_vect2(pair: Array) -> Vector2:
	return Vector2(pair[0], pair[1])

func is_dir_empty(path: String) -> bool:
	var dir := DirAccess.open(path)
	if not dir:
		return false
		
	dir.include_hidden = false
	dir.include_navigational = false
	if dir.get_directories().size() > 0:
		return false
	elif dir.get_files().size() > 0:
		return false
	return true

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

func get_label_text_size(label: Label, text: String) -> Vector2:
	var font := label.get_theme_font(&"font")
	return font.get_multiline_string_size(
		text,
		label.horizontal_alignment,
		(int)(label.size.x) if label.clip_text else -1, # width
		label.get_theme_font_size(&"font_size"),
		-1, # max_lines (unlimited)
		TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND,
		label.justification_flags,
		label.text_direction as TextServer.Direction,
		TextServer.ORIENTATION_HORIZONTAL)

func set_item_checked_by_id(popup: PopupMenu, id: int, checked: bool) -> void:
	var idx := popup.get_item_index(id)
	popup.set_item_checked(idx, checked)
