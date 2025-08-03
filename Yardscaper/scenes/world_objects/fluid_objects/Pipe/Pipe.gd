class_name Pipe extends DistanceMeasurement

const PROP_KEY_DIAMETER_FT                 := &'diameter_ft'
const PROP_KEY_PIPE_COLOR                  := &'pipe_color'
const PROP_KEY_MATERIAL_TYPE               := &'material_type'
const PROP_KEY_CUSTOM_SURFACE_ROUGHNESS_FT := &'custom_surface_roughness_ft'
const PROP_KEY_FPIPE_Q_CFS                 := &'fpipe.q_cfs'
const PROP_KEY_ENTRY_FITTING_TYPE          := &'entry_fitting_type'
const PROP_KEY_ENTRY_CUSTOM_K              := &'entry_custom_k'
const PROP_KEY_EXIT_FITTING_TYPE           := &'exit_fitting_type'
const PROP_KEY_EXIT_CUSTOM_K               := &'exit_custom_k'

const DEFAULT_DIAMETER_FT := 0.0416666666667 # 0.5in
const PVC_SURFACE_ROUGHNESS_FT := 0.000005

var diameter_ft : float = DEFAULT_DIAMETER_FT:
	set(value):
		var old_value = fpipe.d_ft
		fpipe.d_ft = value
		if _check_and_emit_prop_change(PROP_KEY_DIAMETER_FT, old_value):
			queue_redraw()
	get():
		return fpipe.d_ft

var pipe_color : Color = Globals.DEFAULT_PIPE_COLOR:
	set(value):
		var old_value = pipe_color
		pipe_color = value
		if _check_and_emit_prop_change(PROP_KEY_PIPE_COLOR, old_value):
			queue_redraw()

var material_type : PipeTables.MaterialType = PipeTables.MaterialType.PVC:
	set(value):
		var old_value = material_type
		material_type = value
		if material_type == PipeTables.MaterialType.CUSTOM:
			fpipe.E_ft = custom_surface_roughness_ft
		else:
			fpipe.E_ft = PipeTables.lookup_surface_roughness(material_type)
		if _check_and_emit_prop_change(PROP_KEY_MATERIAL_TYPE, old_value):
			# changing the material type can impact the minor losses
			_update_fpipe_minor_loss(true)  # entry
			_update_fpipe_minor_loss(false) # exit

var custom_surface_roughness_ft : float = 0.0:
	set(value):
		var old_value = custom_surface_roughness_ft
		custom_surface_roughness_ft = value
		if material_type == PipeTables.MaterialType.CUSTOM:
			fpipe.E_ft = custom_surface_roughness_ft
		if _check_and_emit_prop_change(PROP_KEY_CUSTOM_SURFACE_ROUGHNESS_FT, old_value):
			pass

var entry_fitting_type : PipeTables.FittingType = PipeTables.FittingType.NONE:
	set(value):
		var old_value = entry_fitting_type
		entry_fitting_type = value
		if _check_and_emit_prop_change(PROP_KEY_ENTRY_FITTING_TYPE, old_value):
			_update_fpipe_minor_loss(true) # is_entry

var entry_custom_k : float = 0.0:
	set(value):
		var old_value = entry_custom_k
		entry_custom_k = value
		if _check_and_emit_prop_change(PROP_KEY_ENTRY_CUSTOM_K, old_value):
			_update_fpipe_minor_loss(true) # is_entry

var exit_fitting_type : PipeTables.FittingType = PipeTables.FittingType.NONE:
	set(value):
		var old_value = exit_fitting_type
		exit_fitting_type = value
		if _check_and_emit_prop_change(PROP_KEY_EXIT_FITTING_TYPE, old_value):
			_update_fpipe_minor_loss(false) # is_entry

var exit_custom_k : float = 0.0:
	set(value):
		var old_value = exit_custom_k
		exit_custom_k = value
		if _check_and_emit_prop_change(PROP_KEY_EXIT_CUSTOM_K, old_value):
			_update_fpipe_minor_loss(false) # is_entry

var show_flow_arrows : bool = false:
	set(value):
		if show_flow_arrows == value:
			return
		show_flow_arrows = value
		queue_redraw()

var fpipe : FPipe = null

class PropertiesFromSave extends RefCounted:
	var diameter_ft = null

var _props_from_save := PropertiesFromSave.new()
var _defer_attach_undo_op := false
var _deferred_attach_undo_op : BaseNodeUndoOps.AttachmentChanged = null

# a method for the WorldObject to perform any necessary initialization logic
# after the Project has instantiated, but before it has deserialized it
func _init_world_obj() -> void:
	fpipe = parent_project.fsys.alloc_pipe()
	fpipe.user_metadata = FluidEntityMetadata.new(self, false)

func _ready():
	super._ready()
	color = Color.WHITE
	_setup_pipe_handle(point_a_handle, "Source")
	_setup_pipe_handle(point_b_handle, "Sink")
	
	# restore properties from save
	if _props_from_save.diameter_ft is float:
		diameter_ft = _props_from_save.diameter_ft
		_props_from_save.diameter_ft = null
	else:
		diameter_ft = DEFAULT_DIAMETER_FT

func _draw() -> void:
	if dist_px() < 1.0:
		return # nothing to draw
	
	const OUTLINE_PX := 2
	var diameter_px := Utils.ft_to_px(diameter_ft)
	
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

func get_type_name() -> StringName:
	return TypeNames.PIPE

func finish_move(cancel: bool = false) -> bool:
	if ! super.finish_move(cancel):
		return false
	elif cancel:
		return true # move was canceled, so no need to dettach from BaseNodes
	
	# moving the whole pipe should uncollect our handle magnets. this will also
	# break the fluid entity connections as well.
	_try_uncollect_pipe_handle(point_a_handle)
	_try_uncollect_pipe_handle(point_b_handle)
	return true

func get_tooltip_text() -> String:
	var text : String = "%s" % user_label
	if ! is_instance_valid(fpipe):
		return text
	
	text += " (%s)" % fpipe
	text += "\nlength: %f %s (%s)" % [fpipe.l_ft, Utils.DISP_UNIT_FT, Utils.pretty_dist(fpipe.l_ft)]
	text += "\ndiameter: %f %s" % [Utils.ft_to_inches(fpipe.d_ft), Utils.DISP_UNIT_IN]
	text += "\ncross-sectional area: %f %s" % [Utils.ft2_to_in2(fpipe.area_ft2()), Utils.DISP_UNIT_IN2]
	text += "\nmaterial: %s" % EnumUtils.to_str(PipeTables.MaterialType, material_type)
	text += "\nsurface roughness: %f %s (abs); %f (rel)" % [fpipe.E_ft, Utils.DISP_UNIT_FT, fpipe.relative_roughness()]
	text += "\nflow rate: %s" % Utils.pretty_fvar(fpipe.q_cfs, Utils.DISP_UNIT_GPM, Utils.cftps_to_gpm)
	text += "\nvelocity: %s" % Utils.pretty_fvar(fpipe.v_fps(), Utils.DISP_UNIT_FPS)
	text += "\nReynolds Number (Re): %s" % Utils.pretty_fvar(fpipe.Re(), Utils.DISP_UNIT_NONE)
	text += "\nDarcy friction coef: %s" % Utils.pretty_fvar(fpipe.f_darcy(), Utils.DISP_UNIT_NONE)
	text += "\nsrc pressure: %s" % Utils.pretty_fvar(fpipe.src_h_psi(), Utils.DISP_UNIT_PSI)
	text += "\nsink pressure: %s" % Utils.pretty_fvar(fpipe.sink_h_psi(), Utils.DISP_UNIT_PSI)
	text += "\nmajor loss: %s" % Utils.pretty_fvar(fpipe.major_loss_psi(), Utils.DISP_UNIT_PSI)
	text += "\nentry minor loss: %s" % Utils.pretty_fvar(fpipe.entry_minor_loss_psi(), Utils.DISP_UNIT_PSI)
	text += "\nexit minor loss: %s" % Utils.pretty_fvar(fpipe.exit_minor_loss_psi(), Utils.DISP_UNIT_PSI)
	text += "\nnet loss: %s" % Utils.pretty_fvar(fpipe.delta_h_psi(), Utils.DISP_UNIT_PSI)
	return text

func get_fluid_entity() -> FEntity:
	return fpipe

func serialize() -> Dictionary:
	var data = super.serialize()
	data[PROP_KEY_DIAMETER_FT] = diameter_ft
	data[PROP_KEY_PIPE_COLOR] = pipe_color.to_html(true)
	DictUtils.put_enum(data, PROP_KEY_MATERIAL_TYPE, PipeTables.MaterialType, material_type)
	data[PROP_KEY_CUSTOM_SURFACE_ROUGHNESS_FT] = custom_surface_roughness_ft
	Utils.add_fvar_knowns_into_dict(fpipe.q_cfs, PROP_KEY_FPIPE_Q_CFS, data)
	DictUtils.put_enum(data, PROP_KEY_ENTRY_FITTING_TYPE, PipeTables.FittingType, entry_fitting_type)
	data[PROP_KEY_ENTRY_CUSTOM_K] = entry_custom_k
	DictUtils.put_enum(data, PROP_KEY_EXIT_FITTING_TYPE, PipeTables.FittingType, exit_fitting_type)
	data[PROP_KEY_EXIT_CUSTOM_K] = exit_custom_k
	return data

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	_props_from_save.diameter_ft = DictUtils.get_w_default(data, PROP_KEY_DIAMETER_FT, DEFAULT_DIAMETER_FT)
	pipe_color = DictUtils.get_w_default(data, PROP_KEY_PIPE_COLOR, Globals.DEFAULT_PIPE_COLOR)
	material_type = DictUtils.get_enum_w_default(data, PROP_KEY_MATERIAL_TYPE, PipeTables.MaterialType, PipeTables.MaterialType.PVC)
	custom_surface_roughness_ft = DictUtils.get_w_default(data, PROP_KEY_CUSTOM_SURFACE_ROUGHNESS_FT, 0.0)
	Utils.get_fvar_knowns_from_dict(fpipe.q_cfs, PROP_KEY_FPIPE_Q_CFS, data)
	entry_fitting_type = DictUtils.get_enum_w_default(data, PROP_KEY_ENTRY_FITTING_TYPE, PipeTables.FittingType, PipeTables.FittingType.NONE)
	entry_custom_k = DictUtils.get_w_default(data, PROP_KEY_ENTRY_CUSTOM_K, 0.0)
	exit_fitting_type = DictUtils.get_enum_w_default(data, PROP_KEY_EXIT_FITTING_TYPE, PipeTables.FittingType, PipeTables.FittingType.NONE)
	exit_custom_k = DictUtils.get_w_default(data, PROP_KEY_EXIT_CUSTOM_K, 0.0)

func is_magnet_from_src_handle(magnet: MagneticArea) -> bool:
	return point_a_handle.get_magnet() == magnet

# override from DistanceMeasurement
func _update_info_label_text() -> void:
	var text := "L=%.3f%s" % [dist_ft(), Utils.DISP_UNIT_FT]
	#text += "; Q=%s" % Utils.pretty_fvar(fpipe.q_cfs, Utils.DISP_UNIT_GPM, Utils.cftps_to_gpm)
	info_label.text = text

func _setup_pipe_handle(handle: EditorHandle, user_text: String) -> void:
	handle.magnetic_physics_mask = 0x4 # TODO would be nice if could get mask by name from project settings
	handle.get_magnet().is_collector = false
	handle.get_magnet().disable_collection = true
	handle.get_magnet().position_change_request.connect(_on_magnetic_area_position_change_request.bind(handle))
	handle.user_text = user_text
	handle.label_text_mode = EditorHandle.LabelTextMode.UserText
	handle.get_button().button_down.connect(_on_magnetic_handle_button_down.bind(handle))
	handle.get_button().button_up.connect(_on_magnetic_handle_button_up.bind(handle))
	handle.get_magnet().attachment_changed.connect(_on_magnetic_area_attachment_changed)

# override this so we keep the fpipe's length in sync
func _set_point_position(handle: EditorHandle, new_position: Vector2, force_change:= false):
	super._set_point_position(handle, new_position, force_change)
	fpipe.l_ft = dist_ft()

func _update_fpipe_minor_loss(is_entry: bool) -> void:
	var fitting_type := entry_fitting_type if is_entry else exit_fitting_type
	var new_k_value := 0.0
	if fitting_type == PipeTables.FittingType.CUSTOM:
		new_k_value = entry_custom_k if is_entry else exit_custom_k
	elif fitting_type == PipeTables.FittingType.NONE:
		new_k_value = 0.0
	else:
		var res := PipeTables.lookup_minor_loss(material_type, fitting_type)
		new_k_value = res.loss_factor
	
	if is_entry:
		var old_value := fpipe.K_entry
		fpipe.K_entry = new_k_value
		fluid_property_changed.emit(self, &'fpipe.K_entry', old_value, new_k_value)
	else:
		var old_value := fpipe.K_exit
		fpipe.K_exit = new_k_value
		fluid_property_changed.emit(self, &'fpipe.K_exit', old_value, new_k_value)

func _try_uncollect_pipe_handle(handle: EditorHandle) -> void:
	var magnet := handle.get_magnet()
	if magnet.is_collected():
		magnet.get_collector().uncollect(magnet)

func _forward_attachment_change_to_fpipe(collector: MagneticArea, collected: MagneticArea, attached: bool) -> void:
	var collector_parents := Utils.get_magnet_parents(collector)
	var other_node := collector_parents.wobj as BaseNode
	if ! is_instance_valid(other_node):
		push_error("unable to determine BaseNode")
		return
	
	var node_type := FPipe.NODE_SRC if is_magnet_from_src_handle(collected) else FPipe.NODE_SINK
	if attached:
		fpipe.connect_node(other_node.fnode, node_type)
	else:
		fpipe.disconnect_node(other_node.fnode)

func _predelete() -> void:
	# marking this aids in MagneticArea collect/uncollect undo logic
	point_a_handle.get_magnet().mark_deletion_imminent()
	point_b_handle.get_magnet().mark_deletion_imminent()
	
	if is_instance_valid(fpipe):
		parent_project.fsys.free_pipe(fpipe)
	
	super._predelete()
	
func _on_magnetic_handle_button_down(handle: EditorHandle) -> void:
	_defer_attach_undo_op = true
	handle.get_magnet().disable_collection = false

func _on_magnetic_handle_button_up(handle: EditorHandle) -> void:
	_defer_attach_undo_op = false
	handle.get_magnet().disable_collection = true
	if _deferred_attach_undo_op != null:
		undoable_edit.emit(_deferred_attach_undo_op)
		_deferred_attach_undo_op = null

func _on_magnetic_area_position_change_request(new_global_position: Vector2, handle: EditorHandle) -> void:
	var new_position := new_global_position - global_position
	_set_point_position(handle, new_position, true)

func _on_magnetic_area_attachment_changed(collector: MagneticArea, collected: MagneticArea, attached: bool) -> void:
	_forward_attachment_change_to_fpipe(collector, collected, attached)
	
	var undo_op := BaseNodeUndoOps.AttachmentChanged.new(collector, collected, attached)
	if _defer_attach_undo_op:
		_deferred_attach_undo_op = undo_op
	else:
		undoable_edit.emit(undo_op)
