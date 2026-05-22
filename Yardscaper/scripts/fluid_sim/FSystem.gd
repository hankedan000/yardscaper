class_name FSystem extends RefCounted

var fluid_viscocity_k : float = FluidMath.WATER_VISCOCITY_K
var fluid_density_slugft3 : float = FluidMath.WATER_MASS_DENSITY

var _pipes : Array[FPipe] = []
var _nodes : Array[FNode] = []

var _next_pipe_id : int = 0
var _next_node_id : int = 0
var _max_el_ft : float = 0.0 # highest elevation of all nodes in the system
var _max_h_psi := Var.new(null, 'max_h_psi')
var _min_h_psi := Var.new(null, 'min_h_psi')
var _max_q_cfs := Var.new(null, 'max_q_cfs')
var _min_q_cfs := Var.new(null, 'min_q_cfs')

func get_next_pipe_id() -> int:
	var pid := _next_pipe_id
	_next_pipe_id += 1
	return pid

func get_next_node_id() -> int:
	var nid := _next_node_id
	_next_node_id += 1
	return nid

func get_pipes() -> Array[FPipe]:
	return _pipes.duplicate()

func get_nodes() -> Array[FNode]:
	return _nodes.duplicate()

func get_pipe_count() -> int:
	return _pipes.size()

func get_node_count() -> int:
	return _nodes.size()

func get_entity_count() -> int:
	return get_pipe_count() + get_node_count()

func max_el_ft() -> float:
	return _max_el_ft

func max_h_psi() -> float:
	# fast path: return cached value
	if _max_h_psi.state == Var.State.Known:
		return _max_h_psi.value
	
	if _nodes.size() == 0:
		_max_h_psi.set_known(0.0)
		return 0.0
	
	# iterate over all nodes and find the max solved pressure
	var local_max_h_psi := Globals.PRESSURE_MIN_PSI
	for node in _nodes:
		if node.h_psi.state != Var.State.Unknown:
			local_max_h_psi = max(local_max_h_psi, node.h_psi.value)
	
	# didn't find a solved pressure, so just default to 0
	if local_max_h_psi == Globals.PRESSURE_MIN_PSI:
		local_max_h_psi = 0.0
	_max_h_psi.set_known(local_max_h_psi)
	return local_max_h_psi

func min_h_psi() -> float:
	# fast path: return cached value
	if _min_h_psi.state == Var.State.Known:
		return _min_h_psi.value
	
	if _nodes.size() == 0:
		_min_h_psi.set_known(0.0)
		return 0.0
	
	# iterate over all nodes and find the min solved pressure
	var local_min_h_psi := Globals.PRESSURE_MAX_PSI
	for node in _nodes:
		# FIXME all these searchs should be happening at the subsystem level
		# and not over the whole system. as a workaround, i'm ignoring values
		# of 0.0 so that system's that are islanded or not setup with a flow
		# source won't impact the min.
		if node.h_psi.state != Var.State.Unknown && node.h_psi.value != 0.0:
			local_min_h_psi = min(local_min_h_psi, node.h_psi.value)
	
	# didn't find a solved pressure, so just default to 0
	if local_min_h_psi == Globals.PRESSURE_MAX_PSI:
		local_min_h_psi = 0.0
	_min_h_psi.set_known(local_min_h_psi)
	return local_min_h_psi

func max_q_cfs() -> float:
	# fast path: return cached value
	if _max_q_cfs.state == Var.State.Known:
		return _max_q_cfs.value
	
	if _pipes.size() == 0:
		_max_q_cfs.set_known(0.0)
		return 0.0
	
	# iterate over all nodes and find the max solved flow
	var MIN_CFS := Utils.gpm_to_cftps(Globals.FLOW_MIN_GPM)
	var local_max_q_cfs := MIN_CFS
	for pipe in _pipes:
		if pipe.q_cfs.state != Var.State.Unknown:
			local_max_q_cfs = max(local_max_q_cfs, pipe.q_cfs.value)
	
	# didn't find a solved flow, so just default to 0
	if local_max_q_cfs == MIN_CFS:
		local_max_q_cfs = 0.0
	_max_q_cfs.set_known(local_max_q_cfs)
	return local_max_q_cfs

func min_q_cfs() -> float:
	# fast path: return cached value
	if _min_q_cfs.state == Var.State.Known:
		return _min_q_cfs.value
	
	if _pipes.size() == 0:
		_min_q_cfs.set_known(0.0)
		return 0.0
	
	# iterate over all nodes and find the min solved flow
	var MAX_CFS := Utils.gpm_to_cftps(Globals.FLOW_MAX_GPM)
	var local_min_q_cfs := MAX_CFS
	for pipe in _pipes:
		if pipe.q_cfs.state != Var.State.Unknown:
			local_min_q_cfs = min(local_min_q_cfs, pipe.q_cfs.value)
	
	# didn't find a solved flow, so just default to 0
	if local_min_q_cfs == MAX_CFS:
		local_min_q_cfs = 0.0
	_min_q_cfs.set_known(local_min_q_cfs)
	return local_min_q_cfs

func alloc_pipe() -> FPipe:
	var pipe := FPipe.new(self, get_next_pipe_id())
	_pipes.append(pipe)
	return pipe

func alloc_node() -> FNode:
	var node := FNode.new(self, get_next_node_id())
	_nodes.append(node)
	_update_max_elevation()
	return node

func free_pipe(p: FPipe) -> void:
	if is_instance_valid(p):
		_pipes.erase(p)
		p._predelete()
		p.free.call_deferred()

func free_node(n: FNode) -> void:
	if is_instance_valid(n):
		_nodes.erase(n)
		n._predelete()
		n.free.call_deferred()

func reset_solved_vars(clear_values: bool = false) -> void:
	for node in _nodes:
		node.reset_solved_vars(clear_values)
	for pipe in _pipes:
		pipe.reset_solved_vars(clear_values)
	_max_h_psi.reset()
	_min_h_psi.reset()
	_max_q_cfs.reset()
	_min_q_cfs.reset()

func clear() -> void:
	for p in _pipes:
		free_pipe(p)
	_pipes.clear()
	_next_pipe_id = 0
	for n in _nodes:
		free_node(n)
	_nodes.clear()
	_next_node_id = 0
	_max_el_ft = 0
	reset_solved_vars()

func _update_max_elevation() -> void:
	if _nodes.is_empty():
		_max_el_ft = 0.0
		return
	
	for i in range(_nodes.size()):
		if i == 0:
			_max_el_ft = _nodes[i].el_ft
		else:
			_max_el_ft = max(_max_el_ft, _nodes[i].el_ft)

func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE:
		return
	elif ! is_instance_valid(self):
		return
	
	# free all of our entities
	clear()
