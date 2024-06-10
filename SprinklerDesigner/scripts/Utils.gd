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
