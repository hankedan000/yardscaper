class_name BaseNode extends WorldObject

@onready var magnet_area : MagneticArea = $MagneticArea

var fnode : FNode = null

func get_type_name() -> StringName:
	return TypeNames.BASE_NODE

func get_tooltip_text() -> String:
	var text : String = "%s" % user_label
	if ! is_instance_valid(fnode):
		return text
	
	text += " (%s)" % fnode
	text += "\nnet pressure: %s" % Utils.pretty_fvar(fnode.h_psi, Utils.DISP_UNIT_PSI)
	text += "\nexternal flow: %s" % Utils.pretty_fvar(fnode.q_ext_cfs, Utils.DISP_UNIT_GPM, Utils.cftps_to_gpm)
	text += "\nelevation: %s %s" % [fnode.el_ft, Utils.DISP_UNIT_FT]
	return text

func _predelete() -> void:
	if is_instance_valid(parent_project):
		parent_project.fsys.free_node(fnode)
	
	super._predelete()

# Overriding the WorldObject's method so we can filter the request through the
# MagneticArea first. Actual position updates will occur via the
# _on_magnetic_area_position_change_request() signal handler.
func _apply_global_position(new_global_pos: Vector2) -> void:
	magnet_area.try_position_change(new_global_pos)

func _on_magnetic_area_position_change_request(new_global_position: Vector2) -> void:
	global_position = new_global_position
