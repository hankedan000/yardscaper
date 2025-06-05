class_name Pipe
extends DistanceMeasurement

const PROP_KEY_DIAMETER_INCHES = &'diameter_inches'

var diameter_inches : float = 0.75:
	set(value):
		var old_value = diameter_inches
		diameter_inches = value
		if _check_and_emit_prop_change(PROP_KEY_DIAMETER_INCHES, old_value):
			queue_redraw()

func _ready():
	super._ready()
	color = Color.WHITE

func _draw():
	if dist_px() < 1.0:
		return # nothing to draw
	
	const OUTLINE_PX := 2
	var diameter_px := Utils.ft_to_px(Utils.inches_to_ft(diameter_inches))
	
	# update position/shape of the collision rectangle
	# probably not the best place to do this, but convenient and efficient
	var midpoint = mid_point()
	var delta_vec = point_b - point_a
	_coll_rect.size.x = delta_vec.length()
	_coll_rect.size.y = diameter_px
	pick_area.rotation = delta_vec.angle()
	pick_area.position = midpoint
	
	# draw indicator outline
	if picked or hovering:
		var indic_color = Globals.SELECT_COLOR if picked else Globals.HOVER_COLOR
		draw_line(point_a, point_b, indic_color, diameter_px + (OUTLINE_PX * 2))
	_update_handles()
	
	# draw the pipe as line
	draw_line(point_a, point_b, color, diameter_px)
	
	# draw distance label at midpoint of pipe
	var font : Font = ThemeDB.fallback_font
	var pretty_dist = Utils.pretty_dist(dist_ft())
	draw_string(
		font,
		midpoint,
		pretty_dist,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1, # width
		16, # font_size
		color)

func get_subclass() -> String:
	return "Pipe"

func serialize():
	var obj = super.serialize()
	return obj

func deserialize(obj):
	super.deserialize(obj)
