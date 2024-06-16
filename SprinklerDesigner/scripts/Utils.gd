extends Node

const PX_PER_FT = 12 # 1px per inch

func ft_to_px(ft: float):
	return ft * PX_PER_FT

func px_to_ft(px: float):
	return px / PX_PER_FT

func ft_to_px_vec(ft: Vector2):
	return Vector2(ft_to_px(ft.x), ft_to_px(ft.y))

func px_to_ft_vec(px: Vector2):
	return Vector2(px_to_ft(px.x), px_to_ft(px.y))

func pretty_dist(dist_ft: float):
	var whole_ft = floor(dist_ft) if dist_ft >= 0 else ceil(dist_ft)
	var whole_in = round(abs(dist_ft - whole_ft) * 12.0)
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
