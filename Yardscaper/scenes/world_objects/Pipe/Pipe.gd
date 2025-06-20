class_name Pipe
extends DistanceMeasurement

signal needs_rebake()

const PROP_KEY_DIAMETER_INCHES = &'diameter_inches'
const PROP_KEY_IS_FLOW_SRC = &'is_flow_source'
const PROP_KEY_SRC_PRESSURE_PSI = &'src_pressure_psi'
const PROP_KEY_SRC_FLOW_RATE_GPM = &'src_flow_rate_gpm'
const PROP_KEY_PIPE_COLOR = &'pipe_color'
const PROP_KEY_MATERIAL_TYPE = &'material_type'
const PROP_KEY_CUSTOM_SURFACE_ROUGHNESS_FT = &'custom_surface_roughness_ft'
const PROP_KEY_FLOW_SRC = &'flow_src'

const PVC_SURFACE_ROUGHNESS_FT := 0.000005

enum Colorize {
	Normal = 0,
	Pressure = 1,
	FlowRate = 2
}

@onready var path : Path2D = $Path2D
@onready var flow_src : PipeFlowSource = $FlowSource

var diameter_inches : float = 0.75:
	set(value):
		var old_value = diameter_inches
		diameter_inches = value
		if _check_and_emit_prop_change(PROP_KEY_DIAMETER_INCHES, old_value):
			queue_redraw()
			queue_rebake()

var is_flow_source : bool = false:
	set(value):
		var old_value = is_flow_source
		is_flow_source = value
		if _check_and_emit_prop_change(PROP_KEY_IS_FLOW_SRC, old_value):
			queue_redraw()
			queue_rebake()

var src_pressure_psi : float = 60.0:
	set(value):
		var old_value = src_pressure_psi
		src_pressure_psi = value
		if _check_and_emit_prop_change(PROP_KEY_SRC_PRESSURE_PSI, old_value):
			queue_redraw()
			queue_rebake()

var src_flow_rate_gpm : float = 50.0:
	set(value):
		var old_value = src_flow_rate_gpm
		src_flow_rate_gpm = value
		if _check_and_emit_prop_change(PROP_KEY_SRC_FLOW_RATE_GPM, old_value):
			queue_redraw()
			queue_rebake()

var pipe_color : Color = Color.WHITE_SMOKE:
	set(value):
		var old_value = pipe_color
		pipe_color = value
		if _check_and_emit_prop_change(PROP_KEY_PIPE_COLOR, old_value):
			queue_redraw()

var material_type : PipeTables.MaterialType = PipeTables.MaterialType.PVC:
	set(value):
		var old_value = material_type
		material_type = value
		if _check_and_emit_prop_change(PROP_KEY_MATERIAL_TYPE, old_value):
			queue_rebake()

var custom_surface_roughness_ft : float = 0.0:
	set(value):
		var old_value = custom_surface_roughness_ft
		custom_surface_roughness_ft = value
		if _check_and_emit_prop_change(PROP_KEY_CUSTOM_SURFACE_ROUGHNESS_FT, old_value):
			queue_rebake()

var show_flow_arrows : bool = false:
	set(value):
		if show_flow_arrows == value:
			return
		show_flow_arrows = value
		queue_redraw()

var colorize : Colorize = Colorize.Normal:
	set(value):
		if colorize == value:
			return
		colorize = value
		queue_redraw()

var _sim : FluidSimulator = null
var _flow_src_data_from_disk : Dictionary = {}
var _do_default_flow_src_positioning : bool = true
var _needs_rebake : bool = false
var _prev_point_a : Vector2 = Vector2()
var _prev_point_b : Vector2 = Vector2()

# A list of pipes that this pipe provides fluid flow too. The list is ordered
# based on where the pipe is along our path. Pipes with a progress of 0.0 will
# be first, and progress of 1.0 will be last.
var _feed_pipes_by_progress : Array[Pipe] = []

var _q_points : PackedFloat32Array = PackedFloat32Array() # volumetric flow (ft^3/s)
var _p_points : PackedFloat32Array = PackedFloat32Array() # pressure (lb/ft^2)

class FlowStats:
	var q : float = 0.0 # flow rate (ft^3/s)
	var p : float = 0.0 # pressure (lb/ft^2)

func _ready():
	super._ready()
	color = Color.WHITE
	point_a_handle.user_text = "Feed"
	point_b_handle.user_text = "Drain"
	point_a_handle.show_on_hover = EditorHandle.HoverShowType.UserText
	point_b_handle.show_on_hover = EditorHandle.HoverShowType.UserText
	flow_src.deserialize(_flow_src_data_from_disk)
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
	_check_and_update_path()
	
	# draw the pipe body
	if ! _needs_rebake && colorize != Colorize.Normal:
		_draw_colorized_pipe(diameter_px)
	else:
		# just show pipe as a simple line
		draw_line(point_a, point_b, pipe_color, diameter_px)
	
	if show_flow_arrows:
		_draw_flow_arrows()
	
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_predelete()

func get_sim() -> FluidSimulator:
	return _sim

func get_outward_flows() -> Array[PipeFlowSource]:
	var srcs : Array[PipeFlowSource] = []
	for child in path.get_children():
		if child is PipeFlowSource:
			srcs.append(child)
	return srcs

func is_rebake_needed() -> bool:
	return _needs_rebake

func get_subclass() -> String:
	return "Pipe"

func serialize():
	var obj = super.serialize()
	obj[PROP_KEY_DIAMETER_INCHES] = diameter_inches
	obj[PROP_KEY_IS_FLOW_SRC] = is_flow_source
	obj[PROP_KEY_SRC_PRESSURE_PSI] = src_pressure_psi
	obj[PROP_KEY_SRC_FLOW_RATE_GPM] = src_flow_rate_gpm
	obj[PROP_KEY_PIPE_COLOR] = pipe_color.to_html(true)
	obj[PROP_KEY_MATERIAL_TYPE] = EnumUtils.to_str(PipeTables.MaterialType, material_type)
	obj[PROP_KEY_CUSTOM_SURFACE_ROUGHNESS_FT] = custom_surface_roughness_ft
	obj[PROP_KEY_FLOW_SRC] = flow_src.serialize()
	return obj

func deserialize(obj):
	super.deserialize(obj)
	diameter_inches = DictUtils.get_w_default(obj, PROP_KEY_DIAMETER_INCHES, 0.5)
	is_flow_source = DictUtils.get_w_default(obj, PROP_KEY_IS_FLOW_SRC, false)
	src_pressure_psi = DictUtils.get_w_default(obj, PROP_KEY_SRC_PRESSURE_PSI, 60.0)
	src_flow_rate_gpm = DictUtils.get_w_default(obj, PROP_KEY_SRC_FLOW_RATE_GPM, 50.0)
	pipe_color = DictUtils.get_w_default(obj, PROP_KEY_PIPE_COLOR, Color.WHITE_SMOKE)
	var material_type_str = DictUtils.get_w_default(obj, PROP_KEY_MATERIAL_TYPE, '') as String
	material_type = EnumUtils.from_str(PipeTables.MaterialType, PipeTables.MaterialType.PVC, material_type_str) as PipeTables.MaterialType
	custom_surface_roughness_ft = DictUtils.get_w_default(obj, PROP_KEY_CUSTOM_SURFACE_ROUGHNESS_FT, 0.0)
	_flow_src_data_from_disk = DictUtils.get_w_default(obj, PROP_KEY_FLOW_SRC, {}) as Dictionary

# called by the FluidSimulator once it restores all objects from disk
func init_flow_source(all_pipes: Array[Pipe]) -> void:
	flow_src.init_flow_source(all_pipes)
	_do_default_flow_src_positioning = false

func get_feed_pipes_by_progress() -> Array[Pipe]:
	return _feed_pipes_by_progress.duplicate()

# @return pressure in lb/ft^2
func get_min_pressure() -> float:
	if _p_points.size() > 0:
		return _p_points[-1]
	return 0.0

# @return pressure in lb/ft^2
func get_max_pressure() -> float:
	if _p_points.size() > 0:
		return _p_points[0]
	return 0.0

# @return flow rate in ft^3/s
func get_min_flow() -> float:
	if _q_points.size() > 0:
		return _q_points[-1]
	return 0.0

# @return flow rate in ft^3/s
func get_max_flow() -> float:
	if _q_points.size() > 0:
		return _q_points[0]
	return 0.0

func get_flow_stats_at_progress(progress: float) -> FlowStats:
	var stats_out = FlowStats.new()
	var point := path.curve.sample_baked(progress)
	var idx := Utils.find_nearest_baked_point_index(path, point)
	if idx < 0:
		push_error("unable to find pressure at point")
	elif idx >= _p_points.size():
		push_error("idx extends past end of path _p_points")
	else:
		stats_out.q = _q_points[idx]
		stats_out.p = _p_points[idx]
	return stats_out

# @return hydraulic diamter in ft
func get_diam_h() -> float:
	return Utils.inches_to_ft(diameter_inches)

# @return hydaulic cross sectional area in ft^2
func get_area_h() -> float:
	return Math.area_circle(get_diam_h())

# @return surface roughness in ft
func get_surface_roughness() -> float:
	if material_type == PipeTables.MaterialType.Custom:
		return custom_surface_roughness_ft
	return PipeTables.lookup_surface_roughness(material_type)

# @return relative roughness k/D
func get_relative_roughness() -> float:
	return get_surface_roughness() / get_diam_h()

# called by FluidSimulator class when flow sources change
func rebake() -> void:
	_check_and_update_path()
	_needs_rebake = false
	var baked_points := path.curve.get_baked_points()
	_q_points.resize(baked_points.size())
	_p_points.resize(baked_points.size())
	
	var src_flow_stats := flow_src.get_flow_stats()
	var q := Utils.gpm_to_cftps(src_flow_rate_gpm) if is_flow_source else src_flow_stats.q
	var p := Utils.psi_to_psft(src_pressure_psi) if is_flow_source else src_flow_stats.p
	var diam_h := get_diam_h()
	var area_h := get_area_h()
	var prev_point := point_a
	var rel_roughness := get_relative_roughness()
	for idx in range(baked_points.size()):
		var curr_point := baked_points[idx]
		var l_ft := Utils.px_to_ft((curr_point - prev_point).length())
		_q_points[idx] = q
		_p_points[idx] = p
		var v := q / area_h # velocity
		var Re := FluidMath.reynolds(v, diam_h, FluidMath.WATER_VISCOCITY_K)
		var f_darcy := FluidMath.f_darcy(Re, rel_roughness)
		var major_loss := FluidMath.major_loss(f_darcy, l_ft, v, FluidMath.WATER_DENSITY, diam_h)
		p = max(0.0, p - major_loss)
		prev_point = curr_point
	if colorize != Colorize.Normal:
		queue_redraw()

func queue_rebake() -> void:
	if ! _needs_rebake:
		_needs_rebake = true
		needs_rebake.emit()

func _predelete() -> void:
	if is_instance_valid(flow_src):
		flow_src.detach_from_source()
		flow_src.queue_free()
	# remove our selves from simulator if we're still associated with one
	if is_instance_valid(_sim):
		_sim.remove_pipe(self)

func _check_and_update_path() -> void:
	if _prev_point_a != point_a || _prev_point_b != point_b:
		_prev_point_a = point_a
		_prev_point_b = point_b
		_update_path()

const ARROW_ANGLE_RAD := deg_to_rad(45)
const ARROW_LENGTH_PX := 4
const ARROW_WIDTH_PX := 1
const ARROW_COLOR := Color.AQUA
func _draw_flow_arrows() -> void:
	var arrow_base := (point_a - point_b).normalized() * ARROW_LENGTH_PX
	var flow_arrow_left := arrow_base.rotated(ARROW_ANGLE_RAD)
	var flow_arrow_right := arrow_base.rotated(-ARROW_ANGLE_RAD)
	for point in path.curve.get_baked_points():
		draw_line(point, point + flow_arrow_left, ARROW_COLOR, ARROW_WIDTH_PX)
		draw_line(point, point + flow_arrow_right, ARROW_COLOR, ARROW_WIDTH_PX)

func _draw_colorized_pipe(diameter_px: float) -> void:
	var min_value : float = 0.0
	var value_spread : float = 0.0
	var values = null
	match colorize:
		Colorize.Pressure:
			min_value = _sim.get_system_min_pressure()
			value_spread = _sim.get_system_max_pressure() - min_value
			values = _p_points
		Colorize.FlowRate:
			min_value = _sim.get_system_min_flow()
			value_spread = _sim.get_system_max_flow() - min_value
			values = _q_points
	
	_draw_gradient_pipe(min_value, value_spread, values, diameter_px)

const MIN_GRADIENT_COLOR = Color.BLUE
const MAX_GRADIENT_COLOR = Color.RED
func _draw_gradient_pipe(min_value: float, value_spread: float, values: PackedFloat32Array, diameter_px: float) -> void:
	var baked_points := path.curve.get_baked_points()
	if baked_points.size() < 2:
		return
	
	# avoid divide by zero in color_ratio calculation and just draw line
	if abs(value_spread) < 0.000000001:
		draw_line(point_a, point_b, MAX_GRADIENT_COLOR, diameter_px)
		return
	
	var prev_point : Vector2 = baked_points[0]
	for idx in range(1, baked_points.size()):
		var curr_point : Vector2 = baked_points[idx]
		var value_at_point := values[idx]
		var color_ratio := (value_at_point - min_value) / value_spread
		var seg_color := MIN_GRADIENT_COLOR.lerp(MAX_GRADIENT_COLOR, color_ratio)
		draw_line(prev_point, curr_point, seg_color, diameter_px)
		prev_point = curr_point

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

class CachedProgress:
	var follow : PathFollow2D = null
	var progress_ratio : float = 0.0
	
	func _init(f: PathFollow2D) -> void:
		follow = f
		progress_ratio = f.progress_ratio

func _update_path() -> void:
	# Store the old progress for PathFollow2D node's that reside on our path.
	# The engine doesn't update their position when the path is modified.
	# The fix is in Godot 4.4?? Currently on Godot 4.3 at time of writing this.
	# https://github.com/godotengine/godot/issues/85813
	var cache : Array[CachedProgress] = []
	for child in path.get_children():
		if child is PathFollow2D:
			cache.append(CachedProgress.new(child))
	path.curve.set_point_position(0, point_a)
	path.curve.set_point_position(1, point_b)
	for cache_entry in cache:
		cache_entry.follow.progress_ratio = cache_entry.progress_ratio
	queue_rebake()

static func _sort_by_ascending_progress(a: Pipe, b: Pipe) -> bool:
	return a.flow_src.progress < b.flow_src.progress

func _on_flow_source_moved(_old_pos: Vector2, _new_pos: Vector2) -> void:
	_do_default_flow_src_positioning = false
	queue_rebake()

func _on_flow_source_attached(new_src: Pipe) -> void:
	# append ourselves to the new pipe's feed list and resort it
	new_src._feed_pipes_by_progress.append(self)
	new_src._feed_pipes_by_progress.sort_custom(_sort_by_ascending_progress)
	queue_rebake()

func _on_flow_source_dettached(old_src: Pipe) -> void:
	# remove ourselves from the old pipe's feed list. no need to resort because
	# removal of a node should still preserve the ordering.
	old_src._feed_pipes_by_progress.erase(self)
	queue_rebake()

func _on_flow_source_flow_property_changed() -> void:
	queue_rebake()
