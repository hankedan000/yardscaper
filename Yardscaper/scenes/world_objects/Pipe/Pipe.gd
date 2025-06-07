class_name Pipe
extends DistanceMeasurement

signal flow_source_changed()

const PROP_KEY_DIAMETER_INCHES = &'diameter_inches'
const PROP_KEY_IS_FLOW_SRC = &'is_flow_source'
const PROP_KEY_SRC_PRESSURE_PSI = &'src_pressure_psi'
const PROP_KEY_SRC_FLOW_RATE_GPM = &'src_flow_rate_gpm'
const PROP_KEY_PIPE_COLOR = &'pipe_color'
const PROP_KEY_FLOW_SRC_POS_INFO = &'flow_src_pos_info'

@onready var path : Path2D = $Path2D
@onready var flow_src : PipeFlowSource = $FlowSource

var diameter_inches : float = 0.75:
	set(value):
		var old_value = diameter_inches
		diameter_inches = value
		if _check_and_emit_prop_change(PROP_KEY_DIAMETER_INCHES, old_value):
			queue_redraw()

var is_flow_source : bool = false:
	set(value):
		var old_value = is_flow_source
		is_flow_source = value
		if _check_and_emit_prop_change(PROP_KEY_IS_FLOW_SRC, old_value):
			queue_redraw()

var src_pressure_psi : float = 60.0:
	set(value):
		var old_value = src_pressure_psi
		src_pressure_psi = value
		if _check_and_emit_prop_change(PROP_KEY_SRC_PRESSURE_PSI, old_value):
			queue_redraw()

var src_flow_rate_gpm : float = 50.0:
	set(value):
		var old_value = src_flow_rate_gpm
		src_flow_rate_gpm = value
		if _check_and_emit_prop_change(PROP_KEY_SRC_FLOW_RATE_GPM, old_value):
			queue_redraw()

var pipe_color : Color = Color.WHITE_SMOKE:
	set(value):
		var old_value = pipe_color
		pipe_color = value
		if _check_and_emit_prop_change(PROP_KEY_PIPE_COLOR, old_value):
			queue_redraw()

var _sim : FluidSimulator = null
var _do_default_flow_src_positioning : bool = true
var _flow_src_pos_info_from_disk : PipeFlowSource.PositionInfo = null

func _ready():
	super._ready()
	color = Color.WHITE
	point_a_handle.user_text = "Feed"
	point_b_handle.user_text = "Drain"
	point_a_handle.show_on_hover = EditorHandle.HoverShowType.UserText
	point_b_handle.show_on_hover = EditorHandle.HoverShowType.UserText
	flow_src.parent_pipe = self
	_update_path() # match path to restored point_a and point_b values

func _draw() -> void:
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
	_update_path()
	
	# draw the pipe as line
	draw_line(point_a, point_b, pipe_color, diameter_px)
	
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

func get_sim() -> FluidSimulator:
	return _sim

func get_subclass() -> String:
	return "Pipe"

func serialize():
	var obj = super.serialize()
	obj[PROP_KEY_DIAMETER_INCHES] = diameter_inches
	obj[PROP_KEY_IS_FLOW_SRC] = is_flow_source
	obj[PROP_KEY_SRC_PRESSURE_PSI] = src_pressure_psi
	obj[PROP_KEY_SRC_FLOW_RATE_GPM] = src_flow_rate_gpm
	obj[PROP_KEY_PIPE_COLOR] = pipe_color.to_html(true)
	obj[PROP_KEY_FLOW_SRC_POS_INFO] = flow_src.get_position_info().to_dict()
	return obj

func deserialize(obj):
	super.deserialize(obj)
	diameter_inches = DictUtils.get_w_default(obj, PROP_KEY_DIAMETER_INCHES, 0.5)
	is_flow_source = DictUtils.get_w_default(obj, PROP_KEY_IS_FLOW_SRC, false)
	src_pressure_psi = DictUtils.get_w_default(obj, PROP_KEY_SRC_PRESSURE_PSI, 60.0)
	src_flow_rate_gpm = DictUtils.get_w_default(obj, PROP_KEY_SRC_FLOW_RATE_GPM, 50.0)
	pipe_color = DictUtils.get_w_default(obj, PROP_KEY_PIPE_COLOR, Color.WHITE_SMOKE)
	var pos_info_dict := DictUtils.get_w_default(obj, PROP_KEY_FLOW_SRC_POS_INFO, null) as Dictionary
	if pos_info_dict:
		_flow_src_pos_info_from_disk = PipeFlowSource.PositionInfo.from_dict(pos_info_dict)

# called by the FluidSimulator once it restores all objects from disk
func init_flow_source(all_pipes: Array[Pipe]) -> void:
	if _flow_src_pos_info_from_disk == null:
		return # nothing to restore
		
	flow_src.apply_position_info(all_pipes, _flow_src_pos_info_from_disk)
	_flow_src_pos_info_from_disk = null
	_do_default_flow_src_positioning = false
	
func _update_handles() -> void:
	# call super method that updates point a/b handle positions and visibility
	super._update_handles()
	
	# update our flow source handle's position and visibility
	if is_flow_source:
		# the pipe itself is a flow source, so no need to show the handle
		flow_src.visible = false
	else:
		# if flow source isn't connected to a source pipe yet, then position
		# handle 1ft away from pipe's feed
		if flow_src.source_pipe == null && _do_default_flow_src_positioning:
			_position_flow_src_near_feed(1.0)
		
		flow_src.visible = picked && ! position_locked

func _position_flow_src_near_feed(offset_ft: float) -> void:
	var pipe_dir := (point_b - point_a).normalized()
	var offset_vect = pipe_dir * Utils.ft_to_px(offset_ft)
	flow_src.position = point_a - offset_vect

func _update_path() -> void:
	path.curve.set_point_position(0, point_a)
	path.curve.set_point_position(1, point_b)

func _on_flow_source_moved(_old_pos: Vector2, _new_pos: Vector2) -> void:
	_do_default_flow_src_positioning = false

func _on_flow_source_attached(_new_src: Pipe) -> void:
	flow_source_changed.emit()

func _on_flow_source_dettached(_old_src: Pipe) -> void:
	flow_source_changed.emit()
