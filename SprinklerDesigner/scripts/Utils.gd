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
