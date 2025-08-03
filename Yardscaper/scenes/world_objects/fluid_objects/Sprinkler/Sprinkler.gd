class_name Sprinkler extends BaseNode

const BODY_RADIUS_FT = 3.0 / 12.0
const DEFAULT_MIN_DIST_FT = 8.0
const DEFAULT_MAX_DIST_FT = 14.0
const DEFAULT_MIN_SWEEP_DEG = 0.0
const DEFAULT_MAX_SWEEP_DEG = 360.0

const PROP_KEY_DIST_FT = &"dist_ft"
const PROP_KEY_SWEEP_DEG = &"sweep_deg"
const PROP_KEY_MANUFACTURER = &"manufacturer"
const PROP_KEY_HEAD_MODEL = &"head_model"
const PROP_KEY_NOZZLE_OPTION = &"nozzle_option"
const PROP_KEY_BODY_COLOR = &"body_color"
const PROP_KEY_ZONE = &"zone"

@onready var draw_layer   := $ManualDrawLayer
@onready var rot_handle   : EditorHandle = $RotationHandle
@onready var sweep_handle : EditorHandle = $SweepHandle

static func is_set(value: float):
	return not is_nan(value)

var zone : int = 1 :
	set(value):
		var old_value = zone
		zone = value
		_check_and_emit_prop_change(PROP_KEY_ZONE, old_value)

var dist_ft : float = DEFAULT_MAX_DIST_FT :
	set(value):
		var old_value = dist_ft
		dist_ft = value
		_cap_values()
		if _check_and_emit_prop_change(PROP_KEY_DIST_FT, old_value):
			queue_redraw()

var sweep_deg : float = DEFAULT_MAX_SWEEP_DEG :
	set(value):
		var old_value = sweep_deg
		if value < 0.0:
			value += 360.0
		sweep_deg = int(round(value)) % 361
		_cap_values()
		_update_nozzle_loss()
		if _check_and_emit_prop_change(PROP_KEY_SWEEP_DEG, old_value):
			queue_redraw()

var manufacturer : String = "" :
	set(value):
		var old_value = manufacturer
		manufacturer = value
		_update_head_data()
		_cap_values()
		if _check_and_emit_prop_change(PROP_KEY_MANUFACTURER, old_value):
			queue_redraw()

var head_model : String = "" :
	set(value):
		var old_value = head_model
		head_model = value
		_update_head_data()
		_cap_values()
		if _check_and_emit_prop_change(PROP_KEY_HEAD_MODEL, old_value):
			queue_redraw()

var nozzle_option : String = "" :
	set(value):
		var old_value = nozzle_option
		nozzle_option = value
		_update_nozzle_loss()
		if _check_and_emit_prop_change(PROP_KEY_NOZZLE_OPTION, old_value):
			queue_redraw()

var show_min_dist := false :
	set(value):
		show_min_dist = value
		queue_redraw()

var show_max_dist := false :
	set(value):
		show_max_dist = value
		queue_redraw()

var show_water := true :
	set(value):
		show_water = value
		queue_redraw()

var body_color : Color = Color.BLACK :
	set(value):
		var old_value = body_color
		body_color = value
		if _check_and_emit_prop_change(PROP_KEY_BODY_COLOR, old_value):
			queue_redraw()

var _head_data : SprinklerHeadData = null

# we simulate the minor losses of the sprinkler nozzle by connecting the main
# 'fnode' we get from the BaseNode object to a node that vents to atmosphere
# via a narrow & short piece of pipe.
var _vent_fnode : FNode = null
var _nozzle_fpipe : FPipe = null

# variable used to track handle movement
var _handle_being_moved : EditorHandle = null
var _init_angle_to_mouse : float = 0.0
var _init_rotation : float = 0.0
var _init_sweep : float = 0.0

# a method for the WorldObject to perform any necessary initialization logic
# after the Project has instantiated, but before it has deserialized it
func _init_world_obj() -> void:
	super._init_world_obj()
	
	# allocate our vent node and have it release into atmosphere
	_vent_fnode = parent_project.fsys.alloc_node()
	_vent_fnode.user_metadata = FluidEntityMetadata.new(self, true)
	_vent_fnode.h_psi.set_known(0.0) # vents to atmospher
	
	# allocate and init our nozzle pipe and connect to between the vent and the
	# main 'fnode' that the user can connect pipes to.
	_nozzle_fpipe = parent_project.fsys.alloc_pipe()
	_nozzle_fpipe.user_metadata = FluidEntityMetadata.new(self, true)
	_nozzle_fpipe.d_ft = SprinklerFlowModel.DEFAULT_NOZZLE_DIAMETER_FT
	_nozzle_fpipe.l_ft = SprinklerFlowModel.DEFAULT_NOZZLE_LENGTH_FT
	_nozzle_fpipe.K_exit = 0.0 # updated later when we know what our _head_data is
	_nozzle_fpipe.connect_node(fnode, FPipe.NODE_SRC)
	_nozzle_fpipe.connect_node(_vent_fnode, FPipe.NODE_SINK)
	
	# what comes into the sprinkler will vent to atmosphere via '_nozzle_fpipe'
	fnode.q_ext_cfs.set_known(0.0)

func _ready() -> void:
	super._ready()
	set_process_input(false)
	
	rot_handle.get_button().button_down.connect(_on_handle_button_down.bind(rot_handle))
	rot_handle.get_button().button_up.connect(_on_handle_button_up)
	sweep_handle.get_button().button_down.connect(_on_handle_button_down.bind(sweep_handle))
	sweep_handle.get_button().button_up.connect(_on_handle_button_up)
	
	var body_radius_px := Utils.ft_to_px(Sprinkler.BODY_RADIUS_FT)
	magnet_area.set_radius(body_radius_px)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var delta_angle := _angle_to_mouse() - _init_angle_to_mouse
		if delta_angle < -PI:
			delta_angle += 2 * PI
		if _handle_being_moved == rot_handle:
			rotation = _init_rotation + delta_angle
		elif _handle_being_moved == sweep_handle:
			sweep_deg = rad_to_deg(_init_sweep + delta_angle)

func _draw() -> void:
	draw_layer.queue_redraw()

func _predelete() -> void:
	if is_instance_valid(_vent_fnode):
		parent_project.fsys.free_node(_vent_fnode)
	if is_instance_valid(_nozzle_fpipe):
		parent_project.fsys.free_pipe(_nozzle_fpipe)
	
	super._predelete()

func get_type_name() -> StringName:
	return TypeNames.SPRINKLER

func get_tooltip_text() -> String:
	var text : String = "%s" % user_label
	if ! is_instance_valid(fnode) || ! is_instance_valid(_vent_fnode):
		return text
	
	text += " (%s)" % fnode
	text += "\nmanufacturer: %s" % manufacturer
	text += "\nhead model: %s" % head_model
	if nozzle_option.length() > 0:
		text += "\nnozzle: %s" % head_model
	text += "\nnet pressure: %s" % Utils.pretty_fvar(fnode.h_psi, Utils.DISP_UNIT_PSI)
	text += "\nexternal flow: %s" % Utils.pretty_fvar(_vent_fnode.q_ext_cfs, Utils.DISP_UNIT_GPM, Utils.cftps_to_gpm)
	text += "\nelevation: %s %s" % [fnode.el_ft, Utils.DISP_UNIT_FT]
	return text

func get_bounding_box() -> Rect2:
	var box_width := Utils.ft_to_px(max_dist_ft() * 2.0)
	var box_size = Vector2(box_width, box_width)
	return Rect2(get_visual_center() - box_size / 2.0, box_size)

func serialize() -> Dictionary:
	var obj = super.serialize()
	obj[PROP_KEY_DIST_FT] = dist_ft
	obj[PROP_KEY_SWEEP_DEG] = int(sweep_deg)
	obj[PROP_KEY_MANUFACTURER] = manufacturer
	obj[PROP_KEY_HEAD_MODEL] = head_model
	obj[PROP_KEY_ZONE] = zone
	obj[PROP_KEY_BODY_COLOR] = body_color.to_html(true)
	return obj

func deserialize(obj: Dictionary) -> void:
	super.deserialize(obj)
	sweep_deg = DictUtils.get_w_default(obj, PROP_KEY_SWEEP_DEG, 360.0)
	manufacturer = DictUtils.get_w_default(obj, PROP_KEY_MANUFACTURER, "")
	head_model = DictUtils.get_w_default(obj, PROP_KEY_HEAD_MODEL, "")
	dist_ft = DictUtils.get_w_default(obj, PROP_KEY_DIST_FT, max_dist_ft)
	zone = DictUtils.get_w_default(obj, PROP_KEY_ZONE, 1)
	body_color = DictUtils.get_w_default(obj, PROP_KEY_BODY_COLOR, body_color)

func min_dist_ft() -> float:
	if _head_data == null:
		return DEFAULT_MIN_DIST_FT
	return _head_data.min_dist_ft

func max_dist_ft() -> float:
	if _head_data == null:
		return DEFAULT_MAX_DIST_FT
	return _head_data.max_dist_ft

func min_sweep_deg() -> float:
	if _head_data == null:
		return DEFAULT_MIN_SWEEP_DEG
	return _head_data.min_sweep_deg

func max_sweep_deg() -> float:
	if _head_data == null:
		return DEFAULT_MAX_SWEEP_DEG
	return _head_data.max_sweep_deg

func get_head_data() -> SprinklerHeadData:
	return _head_data

func _update_head_data() -> void:
	_head_data = null
	var manu_data := TheSprinklerDB.get_manufacturer(manufacturer)
	if ! is_instance_valid(manu_data):
		return
	_head_data = manu_data.get_head(head_model)
	_update_nozzle_loss()

func _update_nozzle_loss() -> void:
	var new_minor_loss : float = 0.0
	if is_instance_valid(_head_data):
		var res := _head_data.flow_model.get_minor_loss(self)
		new_minor_loss = res.value
	
	_nozzle_fpipe.K_exit = new_minor_loss

func _cap_values():
	if dist_ft < min_dist_ft():
		dist_ft = min_dist_ft()
	elif dist_ft > max_dist_ft():
		dist_ft = max_dist_ft()
	
	if sweep_deg < min_sweep_deg():
		sweep_deg = min_sweep_deg()
	elif sweep_deg > max_sweep_deg():
		sweep_deg = max_sweep_deg()

# @return return angle to current mouse location in range of 0 to 2PI;
# where 0 is global right, and the angle increases clockwise.
func _angle_to_mouse() -> float:
	var angle := (get_global_mouse_position() - global_position).angle()
	if angle < 0.0:
		angle = (PI * 2) + angle
	return angle

func _on_picked_state_changed(_wobj: WorldObject, _new_state: bool) -> void:
	show_min_dist = picked
	show_max_dist = picked

func _on_handle_button_down(handle: EditorHandle) -> void:
	_handle_being_moved = handle
	_init_angle_to_mouse = _angle_to_mouse()
	_init_rotation = rotation
	_init_sweep = deg_to_rad(sweep_deg)
	set_process_input(true)
	
	# defer property chang events until we're done with move operation
	if handle == rot_handle:
		deferred_prop_change.push(PROP_KEY_ROTATION_DEG)
	elif handle == sweep_handle:
		deferred_prop_change.push(PROP_KEY_SWEEP_DEG)

func _on_handle_button_up() -> void:
	var old_handle := _handle_being_moved
	_handle_being_moved = null
	set_process_input(false)
	
	if old_handle == rot_handle:
		deferred_prop_change.pop(PROP_KEY_ROTATION_DEG)
	elif old_handle == sweep_handle:
		deferred_prop_change.pop(PROP_KEY_SWEEP_DEG)
