extends WorldObject
class_name PipeNode

const BODY_RADIUS_FT = 3.0 / 12.0 # 6in diameter

@onready var draw_layer := $ManualDrawLayer
@onready var magnet_area : MagneticArea = $MagneticArea

var fnode : FNode = null

# @return true if initialization was successful, false otherwise
func _init_pipe_node(new_parent_project: Project) -> bool:
	if ! _init_world_obj(new_parent_project):
		return false
	
	fnode = parent_project.fsys.alloc_node()
	return true

func _ready() -> void:
	super._ready()
	
	var body_radius_px := get_body_radius_px()
	var c_shape := pick_coll_shape.shape as CircleShape2D
	c_shape.radius = body_radius_px
	magnet_area.set_radius(body_radius_px)

func _draw() -> void:
	draw_layer.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_predelete()

func get_subclass() -> String:
	return "PipeNode"

func get_tooltip_text() -> String:
	var text : String = "%s" % user_label
	if ! is_instance_valid(fnode):
		return text
	
	text += " (%s)" % fnode
	text += "\nnet pressure: %s" % Utils.pretty_fvar(fnode.h_psi, Utils.DISP_UNIT_PSI)
	text += "\nexternal flow: %s" % Utils.pretty_fvar(fnode.q_ext_cfs, Utils.DISP_UNIT_GPM, Utils.cftps_to_gpm)
	text += "\nelevation: %s %s" % [fnode.el_ft, Utils.DISP_UNIT_FT]
	return text

func get_body_radius_px() -> float:
	return Utils.ft_to_px(BODY_RADIUS_FT)

func _predelete() -> void:
	if is_instance_valid(parent_project):
		parent_project.fsys.free_node(fnode)

# Overriding the WorldObject's method so we can filter the request through the
# MagneticArea first. Actual position updates will occur via the
# _on_magnetic_area_position_change_request() signal handler.
func _apply_global_position(new_global_pos: Vector2) -> void:
	magnet_area.try_position_change(new_global_pos)

func _on_magnetic_area_position_change_request(new_global_position: Vector2) -> void:
	global_position = new_global_position
