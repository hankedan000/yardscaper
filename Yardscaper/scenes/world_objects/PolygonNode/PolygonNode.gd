extends WorldObject
class_name PolygonNode

const PERIMETER_WIDTH = 2

const PROP_KEY_COLOR = &"color"
const PROP_KEY_POINTS_FT = &"points_ft"

@onready var poly := $Polygon2D
@onready var coll_poly := $PickArea/CollisionPolygon2D

var color := Color.MEDIUM_AQUAMARINE:
	set(value):
		var old_value = color
		color = value
		if old_value != color:
			property_changed.emit(self, PROP_KEY_COLOR, old_value, color)
		queue_redraw()

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

func add_point(point: Vector2):
	if ! _is_ready:
		await ready
	# can't do direct append of point onto polygon.
	# need to assign polygon with edited list of points
	var new_points : PackedVector2Array = poly.polygon
	new_points.append(point)
	poly.polygon = new_points
	coll_poly.polygon = new_points
	_update_info_label()
	queue_redraw()

func set_point(idx: int, point: Vector2):
	poly.polygon[idx] = point
	coll_poly.polygon[idx] = point
	_update_info_label()
	queue_redraw()

func insert_point(at_idx: int, point: Vector2):
	var new_points = poly.polygon
	new_points.insert_at(at_idx, point)
	poly.polygon = new_points
	coll_poly.polygon = new_points
	_update_info_label()
	queue_redraw()

func remove_point(idx: int):
	# can't do direct remove of point in polygon.
	# need to assign polygon with edited list of points
	var new_points = poly.polygon
	new_points.remove_at(idx)
	poly.polygon = new_points
	coll_poly.polygon = new_points
	_update_info_label()
	queue_redraw()

func point_count() -> int:
	return poly.polygon.size()

func get_closed_points() -> PackedVector2Array:
	var points = poly.polygon # returns a copy
	if points.size() >= 1:
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

# overrides WorldObject::on_zoom_changed()
func on_zoom_changed(new_zoom: Vector2, inv_new_zoom: Vector2) -> void:
	super.on_zoom_changed(new_zoom, inv_new_zoom)
	_reposition_info_label()

func _on_property_changed(_obj: WorldObject, property_key: StringName, _from: Variant, _to: Variant) -> void:
	if is_inside_tree() and property_key == WorldObject.PROP_KEY_USER_LABEL:
		_update_info_label()
