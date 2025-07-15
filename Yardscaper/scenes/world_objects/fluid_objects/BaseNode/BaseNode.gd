class_name BaseNode extends WorldObject

const PROP_KEY_PIPE_CONNECTIONS := &'pipe_connections'

@onready var magnet_area : MagneticArea = $MagneticArea

var fnode : FNode = null

class PropsFromSave extends RefCounted:
	var pipe_connections : Array = []

var _props_from_save : PropsFromSave = PropsFromSave.new()

func _ready() -> void:
	super._ready()
	var cshape := pick_coll_shape.shape as CircleShape2D
	cshape.radius = magnet_area.get_radius()

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

func serialize():
	var obj = super.serialize()
	obj[PROP_KEY_PIPE_CONNECTIONS] = _build_pipe_connection_list()
	return obj

func deserialize(obj):
	super.deserialize(obj)
	_props_from_save.pipe_connections = DictUtils.get_w_default(obj, PROP_KEY_PIPE_CONNECTIONS, [])

# called by Project when it's posible for us to restore our pipe connections
# from deserialized save state.
func restore_pipe_connections() -> void:
	if ! is_instance_valid(parent_project):
		push_error("parent_project must be valid")
		return
	
	for conn in _props_from_save.pipe_connections:
		# fetch the pipe for the connection
		var pipe_ulabel := conn[&'user_label'] as String
		var pipe := parent_project.get_obj_by_user_label(pipe_ulabel) as Pipe
		if ! is_instance_valid(pipe):
			push_error("failed to get valid pipe with user_label '%s'" % pipe_ulabel)
			continue
		
		# make the connection via the magnetic nodes (actual fluid sim object
		# connection will be made automatically). we stash then restore the
		# disable_collection property because EditorHandle keep their magnets
		# disabled unless they're being moved.
		var is_src := conn[&'is_src'] as bool
		var pipe_magnet := pipe.point_a_handle.get_magnet() if is_src else pipe.point_b_handle.get_magnet()
		var old_disable := pipe_magnet.disable_collection # save
		pipe_magnet.disable_collection = false
		magnet_area.collect(pipe_magnet)
		pipe_magnet.disable_collection = old_disable # restore
	
	_props_from_save.pipe_connections.clear()

func get_attached_pipes() -> Array[Pipe]:
	var pipes : Array[Pipe] = []
	for magnet in magnet_area.get_collection():
		var magnets_pipe := _get_magnets_world_object(magnet) as Pipe
		if is_instance_valid(magnets_pipe):
			pipes.push_back(magnets_pipe)
	return pipes

func get_attachment_count() -> int:
	return magnet_area.get_attachment_count()

func _build_pipe_connection_list() -> Array[Dictionary]:
	var list_out : Array[Dictionary] = []
	for pipe in get_attached_pipes():
		list_out.push_back({
			&'user_label' : pipe.user_label,
			&'is_src' : pipe.fpipe.src_node == fnode
		})
	return list_out

func _predelete() -> void:
	# disconnect this signal because freeing our fnode will trigger attachment
	# disconnects that we can't and shouldn't be handling
	magnet_area.attachment_changed.disconnect(_on_magnetic_area_attachment_changed)
	
	if is_instance_valid(parent_project):
		parent_project.fsys.free_node(fnode)
	
	super._predelete()

# Overriding the WorldObject's method so we can filter the request through the
# MagneticArea first. Actual position updates will occur via the
# _on_magnetic_area_position_change_request() signal handler.
func apply_global_position(new_global_pos: Vector2) -> void:
	magnet_area.try_position_change(new_global_pos)

static func _get_magnets_world_object(magnet: MagneticArea) -> WorldObject:
	var mag_parent := magnet.get_parent()
	while is_instance_valid(mag_parent) && ! (mag_parent is WorldObject):
		mag_parent = mag_parent.get_parent()
	return mag_parent

func _on_magnetic_area_position_change_request(new_global_position: Vector2) -> void:
	global_position = new_global_position

func _on_magnetic_area_attachment_changed(_collector: MagneticArea, collected: MagneticArea, attached: bool) -> void:
	var other_pipe := _get_magnets_world_object(collected) as Pipe
	if ! is_instance_valid(other_pipe):
		return
	
	var node_type := FPipe.NODE_SRC if other_pipe.is_magnet_from_src_handle(collected) else FPipe.NODE_SINK
	if attached:
		other_pipe.fpipe.connect_node(fnode, node_type)
	else:
		other_pipe.fpipe.disconnect_node(fnode)
