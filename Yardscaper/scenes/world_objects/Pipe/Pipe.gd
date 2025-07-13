class_name Pipe
extends DistanceMeasurement

const PROP_KEY_DIAMETER_INCHES = &'diameter_inches'
const PROP_KEY_PIPE_COLOR = &'pipe_color'
const PROP_KEY_MATERIAL_TYPE = &'material_type'
const PROP_KEY_CUSTOM_SURFACE_ROUGHNESS_FT = &'custom_surface_roughness_ft'

const PVC_SURFACE_ROUGHNESS_FT := 0.000005

var diameter_inches : float = 0.75:
	set(value):
		var old_value = diameter_inches
		diameter_inches = value
		if _check_and_emit_prop_change(PROP_KEY_DIAMETER_INCHES, old_value):
			queue_redraw()

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
			pass

var custom_surface_roughness_ft : float = 0.0:
	set(value):
		var old_value = custom_surface_roughness_ft
		custom_surface_roughness_ft = value
		if _check_and_emit_prop_change(PROP_KEY_CUSTOM_SURFACE_ROUGHNESS_FT, old_value):
			pass

var show_flow_arrows : bool = false:
	set(value):
		if show_flow_arrows == value:
			return
		show_flow_arrows = value
		queue_redraw()

var fpipe : FPipe = null

# @return true if initialization was successful, false otherwise
func _init_pipe(new_parent_project: Project) -> bool:
	if ! _init_world_obj(new_parent_project):
		return false
	
	fpipe = parent_project.fsys.alloc_pipe()
	return true

func _ready():
	super._ready()
	color = Color.WHITE
	_setup_pipe_handle(point_a_handle, "Feed")
	_setup_pipe_handle(point_b_handle, "Drain")

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
	
	# draw the pipe body
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_predelete()

func get_subclass() -> String:
	return "Pipe"

func serialize():
	var obj = super.serialize()
	obj[PROP_KEY_DIAMETER_INCHES] = diameter_inches
	obj[PROP_KEY_PIPE_COLOR] = pipe_color.to_html(true)
	obj[PROP_KEY_MATERIAL_TYPE] = EnumUtils.to_str(PipeTables.MaterialType, material_type)
	obj[PROP_KEY_CUSTOM_SURFACE_ROUGHNESS_FT] = custom_surface_roughness_ft
	return obj

func deserialize(obj):
	super.deserialize(obj)
	diameter_inches = DictUtils.get_w_default(obj, PROP_KEY_DIAMETER_INCHES, 0.5)
	pipe_color = DictUtils.get_w_default(obj, PROP_KEY_PIPE_COLOR, Color.WHITE_SMOKE)
	var material_type_str = DictUtils.get_w_default(obj, PROP_KEY_MATERIAL_TYPE, '') as String
	material_type = EnumUtils.from_str(PipeTables.MaterialType, PipeTables.MaterialType.PVC, material_type_str) as PipeTables.MaterialType
	custom_surface_roughness_ft = DictUtils.get_w_default(obj, PROP_KEY_CUSTOM_SURFACE_ROUGHNESS_FT, 0.0)

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

func _setup_pipe_handle(handle: EditorHandle, user_text: String) -> void:
	handle.magnetic_physics_mask = 0x4 # TODO would be nice if could get mask by name from project settings
	handle.get_magnet().is_collector = false
	handle.get_magnet().disable_collection = true
	handle.get_magnet().position_change_request.connect(_on_magnetic_area_position_change_request.bind(handle))
	handle.user_text = user_text
	handle.label_text_mode = EditorHandle.LabelTextMode.UserText
	handle.get_button().button_down.connect(_on_magnetic_handle_button_down.bind(handle))
	handle.get_button().button_up.connect(_on_magnetic_handle_button_up.bind(handle))

func _predelete() -> void:
	if is_instance_valid(parent_project):
		parent_project.fsys.free_pipe(fpipe)
	
func _on_magnetic_handle_button_down(handle: EditorHandle) -> void:
	handle.get_magnet().disable_collection = false

func _on_magnetic_handle_button_up(handle: EditorHandle) -> void:
	handle.get_magnet().disable_collection = true

func _on_magnetic_area_position_change_request(new_global_position: Vector2, handle: EditorHandle) -> void:
	var new_position := new_global_position - global_position
	_set_point_position(handle, new_position, true)
