extends MoveableNode2D
class_name DistanceMeasurement

var color := Color.BLACK

var point_a := Vector2():
	set(value):
		point_a = value
		queue_redraw()

var point_b := Vector2():
	set(value):
		point_b = value
		queue_redraw()

func _draw():
	if dist_px() < 1.0:
		return # nothing to draw
	
	draw_line(point_a, point_b, color, 1)
	var font : Font = ThemeDB.fallback_font
	var pretty_dist = Utils.pretty_dist(dist_ft())
	draw_string(
		font,
		mid_point(),
		pretty_dist,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1, # width
		16, # font_size
		color)

func mid_point() -> Vector2:
	return point_a + ((point_b - point_a) / 2.0)

func dist_px() -> float:
	return point_a.distance_to(point_b)

func dist_ft() -> float:
	return Utils.px_to_ft(dist_px())

func get_subclass() -> String:
	return "DistanceMeasurement"

func serialize():
	var obj = super.serialize()
	obj['point_a_ft'] = Utils.vect2_to_pair(Utils.px_to_ft_vec(point_a))
	obj['point_b_ft'] = Utils.vect2_to_pair(Utils.px_to_ft_vec(point_b))
	return obj

func deserialize(obj):
	super.deserialize(obj)
	point_a = Utils.ft_to_px_vec(Utils.pair_to_vect2(obj['point_a_ft']))
	point_b = Utils.ft_to_px_vec(Utils.pair_to_vect2(obj['point_b_ft']))
