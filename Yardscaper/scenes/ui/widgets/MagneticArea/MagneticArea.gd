class_name MagneticArea
extends Area2D

# a signal that is fired upon a requested position change from a 'collector'
# magnet. if this signal is not attached to anything, then the global position
# change will be applied immediately.
signal position_change_request(new_global_position: Vector2)
signal attachment_changed(collector: MagneticArea, collected: MagneticArea, attached: bool)

const POS_CHANGE_TOL_PX : float = 1.0

@export_flags_2d_physics var magnetic_physics_mask := 0:
	set(new_value):
		collision_layer = new_value
		collision_mask = new_value
	get():
		return collision_layer

# if true, this magnet will collect other magnets. if this magnet is moved, then
# it will request it's collected magnets to be moved as well.
@export var is_collector : bool = false:
	set(new_value):
		if is_collector == new_value:
			return # no change
		is_collector = new_value
		_update_collector_state()

# this flag only pertains to non-collectors. if true, the magnet won't be
# collected by other magnets even if it's within range.
@export var disable_collection : bool = false

@onready var _coll_shape : CollisionShape2D = $CollisionShape2D
@onready var _circle_shape : CircleShape2D = _coll_shape.shape

var _my_collector : MagneticArea = null # the magnet that 'holds' us in a collection
var _collection : Array[MagneticArea] = [] # held magnets if marked as a 'collector'
var _in_position_change_try := false # used to avoid recursive tries
var _last_requested_global_position := Vector2()
var _deletion_imminent := false
var _undo_node_ref_prior_to_deletion := UndoController.TreePathNodeRef.new()

func _ready() -> void:
	_update_collector_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_predelete()
	elif what == Node.NOTIFICATION_EXIT_TREE:
		_exit_tree()

func set_radius(radius_px: float) -> void:
	_circle_shape.radius = radius_px

func get_radius() -> float:
	return _circle_shape.radius

func mark_deletion_imminent() -> void:
	_deletion_imminent = true

func get_collector() -> MagneticArea:
	return _my_collector

func get_collection() -> Array[MagneticArea]:
	return _collection.duplicate()

func get_attachment_count() -> int:
	return _collection.size()

func is_collected() -> bool:
	return is_instance_valid(_my_collector)

func is_collectable(ignore_disable: bool = false) -> bool:
	if is_collector:
		return false
	elif is_collected():
		return false
	elif ! ignore_disable && disable_collection:
		return false
	return true

# @param[in] other - the magnet to collect
# @param[in] force - will make the collection occur regardless if the other
# magnet has its disable_collection flag set. this should only be used
# sparingly. As an example, if you are restoring a previously broken attachment,
# you know the magnet were attached previously, so you can safely ignore the
# disable flag when restoring the attachment.
func collect(other: MagneticArea, ignore_disable: bool = false) -> void:
	if ! is_collector:
		push_warning("this magnet is not marked as a collector")
		return
	elif ! is_instance_valid(other):
		push_warning("other magnet is not valid")
		return
	elif ! other.is_collectable(ignore_disable):
		# could already collected (even by us), or collection is disabled
		return
	
	_collection.push_back(other)
	other._my_collector = self
	other.attachment_changed.emit(self, other, true)
	attachment_changed.emit(self, other, true)

func uncollect(other: MagneticArea) -> void:
	if ! is_collector:
		push_warning("this magnet is not marked as a collector. ignoring.")
		return
	elif ! is_instance_valid(other):
		push_warning("other magnet is not valid")
		return
	elif ! (other in _collection):
		push_warning("other manget is not collected my this magnet")
		return
	
	_collection.erase(other)
	other._my_collector = null
	other.attachment_changed.emit(self, other, false)
	attachment_changed.emit(self, other, false)

# @param[in] new_global_position - the new global position to try assigning
# @return the position that was actually assigned due to potential magnetic
# effects
func try_position_change(new_global_position: Vector2) -> Vector2:
	if _in_position_change_try:
		return _last_requested_global_position
	
	_in_position_change_try = true
	if is_collector:
		_try_position_change_collector(new_global_position)
	else:
		_try_position_change_noncollector(new_global_position)
	_in_position_change_try = false
	return _last_requested_global_position

func get_undo_node_ref() -> UndoController.TreePathNodeRef:
	if _undo_node_ref_prior_to_deletion.is_valid():
		return _undo_node_ref_prior_to_deletion
	return UndoController.TreePathNodeRef.new(self)

func _try_position_change_collector(new_global_position: Vector2) -> void:
	_request_position_change(new_global_position)
	
	# request position updates for our collected magnets
	var dead_magnets : Array[MagneticArea] = []
	for other in _collection:
		if ! is_instance_valid(other):
			dead_magnets.push_back(other)
			continue
		other._request_position_change(global_position)
	
	# purge any dead magnets from our collection
	for dead_magnet in dead_magnets:
		_collection.erase(dead_magnet)

func _try_position_change_noncollector(new_global_position: Vector2) -> void:
	# can request a position update immedately if the magnet isn't collected
	if ! is_collected():
		_request_position_change(new_global_position)
		return
		
	# since magnet is magnetized to another (ie. collected), we need to see if
	# new position is far enough away to demagnetize it before we can apply
	# the new position.
	var collector_global_pos := _my_collector.global_position
	var unsnap_dist := get_radius() + _my_collector.get_radius()
	var pos_dist := (new_global_position - collector_global_pos).length()
	if pos_dist > unsnap_dist:
		# unsnap the magnet!
		_my_collector.uncollect(self)
		_request_position_change(new_global_position)
	else:
		# snap the magnet position to the collector's position instead. there's
		# no need to call collect() because that will occur automatically via
		# the area_entered() signal
		_request_position_change(collector_global_pos)

func _update_collector_state() -> void:
	_release_all_attachments()
	monitoring = is_collector
	monitorable = ! is_collector
	if is_collector && ! area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	elif ! is_collector && area_entered.is_connected(_on_area_entered):
		area_entered.disconnect(_on_area_entered)

func _predelete() -> void:
	# cleanup any magnetic attachments upon deletion
	_release_all_attachments()

func _exit_tree() -> void:
	# store path to ourselves if we're about to be deleted. this used for
	# magnet connection undo history later on.
	if _deletion_imminent:
		_undo_node_ref_prior_to_deletion = UndoController.TreePathNodeRef.new(self)

func _release_all_attachments() -> void:
	if is_instance_valid(_my_collector):
		_my_collector.uncollect(self)
	for other in _collection.duplicate():
		if is_instance_valid(other):
			uncollect(other)

# should only be called directly by a 'collector' magnet when it is updating
# all its collected magnets follow its position. other callers should
# probably use try_position_change().
func _request_position_change(new_global_position: Vector2) -> void:
	if position_change_request.get_connections().size() > 0:
		position_change_request.emit(new_global_position)
	else:
		global_position = new_global_position

func _on_area_entered(area: Area2D) -> void:
	var magnet := area as MagneticArea
	if ! magnet.is_collected():
		collect(magnet)
