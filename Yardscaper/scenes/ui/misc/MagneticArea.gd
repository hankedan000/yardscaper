class_name MagneticArea
extends Area2D

# a signal that is fired upon a requested position change from a 'collector'
# magnet. if this signal is not attached to anything, then the global position
# change will be applied immediately.
signal position_change_request(new_global_position: Vector2)
signal attachment_changed(collector: MagneticArea, collected: MagneticArea, attached: bool)

const POS_CHANGE_TOL_PX : float = 1.0

# if true, this magnet will collect other magnets. if this magnet is moved, then
# it will request it's collected magnets to be moved as well.
@export var is_collector : bool = false:
	set(new_value):
		if is_collector == new_value:
			return # no change
		is_collector = new_value
		_update_collector_state()

@onready var _coll_shape : CollisionShape2D = $CollisionShape2D
@onready var _circle_shape : CircleShape2D = _coll_shape.shape

var _my_collector : MagneticArea = null # the magnet that 'holds' us in a collection
var _collection : Array[MagneticArea] = [] # held magnets if marked as a 'collector'

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_predelete()

func set_radius(radius_px: float) -> void:
	_circle_shape.radius = radius_px

func get_radius() -> float:
	return _circle_shape.radius

func is_collected() -> bool:
	return _my_collector != null

func collect(other: MagneticArea) -> void:
	if ! is_collector:
		push_warning("this magnet is not marked as a collector")
		return
	elif ! is_instance_valid(other):
		push_warning("other magnet is not valid")
		return
	elif other.is_collector:
		push_warning("other magnet is marked as a collector")
		return
	elif other.is_collected():
		push_warning("other is already in a collection")
		return
	elif other in _collection:
		push_warning("other is already in our collection")
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
	
func try_position_change(new_global_position: Vector2) -> void:
	if is_collector:
		_try_position_change_collector(new_global_position)
	else:
		_try_position_change_noncollector(new_global_position)

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
		# snap the magnet position to the collector's position instead
		_request_position_change(collector_global_pos)

func _update_collector_state() -> void:
	_release_all_attachments()
	print("is_collector = %s" % is_collector)
	monitoring = is_collector
	monitorable = ! is_collector
	if is_collector:
		area_entered.connect(_on_area_entered)
	elif area_entered.is_connected(_on_area_entered):
		area_entered.disconnect(_on_area_entered)

func _predelete() -> void:
	# cleanup any magnetic attachments upon deletion
	_release_all_attachments()

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
	print("area_entered = %s" % area)
	var magnet := area as MagneticArea
	if ! magnet.is_collected():
		collect(magnet)
