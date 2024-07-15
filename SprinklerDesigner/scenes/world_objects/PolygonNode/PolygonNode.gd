extends MoveableNode2D
class_name PolygonNode

const PERIMETER_WIDTH = 2

@onready var poly := $Polygon2D
@onready var coll_poly := $PickArea/CollisionPolygon2D

var _is_ready = false

func _ready():
	_is_ready = true

func _draw():
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

func add_point(point: Vector2):
	if ! _is_ready:
		await ready
	# can't do direct append of point onto polygon.
	# need to assign polygon with edited list of points
	var new_points = poly.polygon
	new_points.append(point)
	poly.polygon = new_points
	coll_poly.polygon = new_points
	queue_redraw()

func set_point(idx: int, point: Vector2):
	poly.polygon[idx] = point
	coll_poly.polygon[idx] = point
	queue_redraw()

func insert_point(at_idx: int, point: Vector2):
	var new_points = poly.polygon
	new_points.insert_at(at_idx, point)
	poly.polygon = new_points
	coll_poly.polygon = new_points
	queue_redraw()

func remove_point(idx: int):
	# can't do direct remove of point in polygon.
	# need to assign polygon with edited list of points
	var new_points = poly.polygon
	new_points.remove_at(idx)
	poly.polygon = new_points
	coll_poly.polygon = new_points
	queue_redraw()

func point_count() -> int:
	return poly.polygon.size()

func get_subclass() -> String:
	return "PolygonNode"

func serialize():
	var obj = super.serialize()
	var points_ft = []
	for point in poly.polygon:
		points_ft.append(Utils.vect2_to_pair(Utils.px_to_ft_vec(point)))
	obj['points_ft'] = points_ft
	return obj

func deserialize(obj):
	super.deserialize(obj)
	var points_ft = Utils.dict_get(obj, 'points_ft', [])
	for point in points_ft:
		add_point(Utils.ft_to_px_vec(Utils.pair_to_vect2(point)))
