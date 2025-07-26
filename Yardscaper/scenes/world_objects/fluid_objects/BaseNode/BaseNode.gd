class_name BaseNode extends WorldObject

const PROP_KEY_PIPE_CONNECTIONS := &'pipe_connections'
const PROP_KEY_FNODE_H_PSI := &'fnode.h_psi'
const PROP_KEY_FNODE_Q_EXT_CFS := &'fnode.q_ext_cfs'

@onready var magnet_area : MagneticArea = $MagneticArea

var fnode : FNode = null

class BaseNodePropsFromSave extends RefCounted:
	var pipe_connections : Array = []

var _base_node_props_from_save : BaseNodePropsFromSave = BaseNodePropsFromSave.new()

# a method for the WorldObject to perform any necessary initialization logic
# after the Project has instantiated, but before it has deserialized it
func _init_world_obj() -> void:
	fnode = parent_project.fsys.alloc_node()
	fnode.user_metadata = FluidEntityMetadata.new(self, false)
	
	# for brand new PipeNodes, be helpful to the user and set this to 0.0 since
	# the majority of the nodes they're making will be for connecting pipes
	# together which will have no external flows.
	fnode.q_ext_cfs.set_known(0.0)
	
func _ready() -> void:
	super._ready()
	var cshape := pick_coll_shape.shape as CircleShape2D
	cshape.radius = magnet_area.get_radius()

func get_type_name() -> StringName:
	return TypeNames.BASE_NODE

func start_move() -> void:
	super.start_move()
	_notify_attached_pipes_of_handle_move(true) # is_start=true

func finish_move(cancel: bool = false) -> bool:
	if ! super.finish_move(cancel):
		return false
	
	_notify_attached_pipes_of_handle_move(false) # is_start=false
	return true

func get_tooltip_text() -> String:
	var text : String = "%s" % user_label
	if ! is_instance_valid(fnode):
		return text
	
	text += " (%s)" % fnode
	text += "\nnet pressure: %s" % Utils.pretty_fvar(fnode.h_psi, Utils.DISP_UNIT_PSI)
	text += "\nexternal flow: %s" % Utils.pretty_fvar(fnode.q_ext_cfs, Utils.DISP_UNIT_GPM, Utils.cftps_to_gpm)
	text += "\nelevation: %s %s" % [fnode.el_ft, Utils.DISP_UNIT_FT]
	return text

func get_fluid_entity() -> FEntity:
	return fnode

func serialize() -> Dictionary:
	var data = super.serialize()
	Utils.add_fvar_knowns_into_dict(fnode.h_psi, PROP_KEY_FNODE_H_PSI, data)
	Utils.add_fvar_knowns_into_dict(fnode.q_ext_cfs, PROP_KEY_FNODE_Q_EXT_CFS, data)
	data[PROP_KEY_PIPE_CONNECTIONS] = _build_pipe_connection_list()
	return data

func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	Utils.get_fvar_knowns_from_dict(fnode.h_psi, PROP_KEY_FNODE_H_PSI, data)
	Utils.get_fvar_knowns_from_dict(fnode.q_ext_cfs, PROP_KEY_FNODE_Q_EXT_CFS, data)
	_base_node_props_from_save.pipe_connections = DictUtils.get_w_default(data, PROP_KEY_PIPE_CONNECTIONS, [])

# called by Project when it's posible for us to restore our pipe connections
# from deserialized save state.
func restore_pipe_connections() -> void:
	if ! is_instance_valid(parent_project):
		push_error("parent_project must be valid")
		return
	
	for conn in _base_node_props_from_save.pipe_connections:
		# fetch the pipe for the connection
		var pipe_ulabel := conn[&'user_label'] as String
		var pipe := parent_project.get_obj_by_user_label(pipe_ulabel) as Pipe
		if ! is_instance_valid(pipe):
			push_error("failed to get valid pipe with user_label '%s'" % pipe_ulabel)
			continue
		
		# make the connection via the magnetic nodes (actual fluid sim object
		# connection will be made automatically). 
		var is_src := conn[&'is_src'] as bool
		var pipe_magnet := pipe.point_a_handle.get_magnet() if is_src else pipe.point_b_handle.get_magnet()
		magnet_area.collect(pipe_magnet, true) # ignore_disable=true
	
	_base_node_props_from_save.pipe_connections.clear()

func get_attached_magnet_parents() -> Array[MagnetParents]:
	var parents_out : Array[MagnetParents] = []
	for magnet in magnet_area.get_collection():
		parents_out.push_back(_get_magnet_parents(magnet))
	return parents_out

func get_attachment_count() -> int:
	return magnet_area.get_attachment_count()

# This method notifies connected Pipes that we're starting or stopping a move
# operation on one of its editor handles. Doing so, allows the movement edit
# to get deferred until the operation is completed; thereby, preventing the
# undo history from being flooded with incrmental updates.
func _notify_attached_pipes_of_handle_move(is_start: bool) -> void:
	for mag_parents in get_attached_magnet_parents():
		var pipe := mag_parents.wobj as Pipe
		if ! is_instance_valid(pipe):
			continue
		if is_start:
			pipe.start_handle_move(mag_parents.handle)
		else:
			pipe.stop_handle_move()

func _build_pipe_connection_list() -> Array[Dictionary]:
	var list_out : Array[Dictionary] = []
	for mag_parents in get_attached_magnet_parents():
		var pipe := mag_parents.wobj as Pipe
		if ! is_instance_valid(pipe):
			continue
		
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

class MagnetParents extends RefCounted:
	var magnet : MagneticArea = null
	var handle : EditorHandle = null
	var wobj : WorldObject = null

static func _get_magnet_parents(magnet: MagneticArea) -> MagnetParents:
	var mag_parents := MagnetParents.new()
	mag_parents.magnet = magnet
	
	var mag_parent : Node = magnet.get_parent()
	while is_instance_valid(mag_parent):
		if mag_parent is EditorHandle:
			mag_parents.handle = mag_parent as EditorHandle
		elif mag_parent is WorldObject:
			mag_parents.wobj = mag_parent as WorldObject
			break
		mag_parent = mag_parent.get_parent()
	return mag_parents

func _on_magnetic_area_position_change_request(new_global_position: Vector2) -> void:
	global_position = new_global_position

func _on_magnetic_area_attachment_changed(collector: MagneticArea, collected: MagneticArea, attached: bool) -> void:
	undoable_edit.emit(
		BaseNodeUndoOps.AttachementChanged.new(collector, collected, attached))
	
	var other_pipe := _get_magnet_parents(collected).wobj as Pipe
	if ! is_instance_valid(other_pipe):
		return
	
	var node_type := FPipe.NODE_SRC if other_pipe.is_magnet_from_src_handle(collected) else FPipe.NODE_SINK
	if attached:
		other_pipe.fpipe.connect_node(fnode, node_type)
	else:
		other_pipe.fpipe.disconnect_node(fnode)
