class_name FSubSystem extends RefCounted

# Under constrained: unknown_vars > equation_count
# Well constrained:  unknown_vars == equation_count
# Over constrained:  unknown_vars < equation_count
enum ConstrainType {
	Under, Well, Over
}

var nodes : Array[FNode] = []
var pipes : Array[FPipe] = []
var unknown_vars : Array[Var] = []
var equations : Array[Callable] = []

var _max_el_ft : float = 0.0 # highest elevation of all nodes in the FSubSystem
var _max_h_psi := Var.new(null, 'max_h_psi')
var _min_h_psi := Var.new(null, 'min_h_psi')
var _max_q_cfs := Var.new(null, 'max_q_cfs')
var _min_q_cfs := Var.new(null, 'min_q_cfs')

static func get_entity_vars(e: FEntity) -> Array[Var]:
	if e is FPipe:
		return _get_pipe_vars(e)
	elif e is FNode:
		return [e.h_psi, e.q_ext_cfs]
	push_error("unsupported FEntity type")
	return []


func max_el_ft() -> float:
	return _max_el_ft

func max_h_psi() -> float:
	# fast path: return cached value
	if _max_h_psi.state == Var.State.Known:
		return _max_h_psi.value
	
	if nodes.size() == 0:
		_max_h_psi.set_known(0.0)
		return 0.0
	
	# iterate over all nodes and find the max solved pressure
	var local_max_h_psi := Globals.PRESSURE_MIN_PSI
	for node in nodes:
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
	
	if nodes.size() == 0:
		_min_h_psi.set_known(0.0)
		return 0.0
	
	# iterate over all nodes and find the min solved pressure
	var local_min_h_psi := Globals.PRESSURE_MAX_PSI
	for node in nodes:
		if node.h_psi.state != Var.State.Unknown:
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
	
	if pipes.size() == 0:
		_max_q_cfs.set_known(0.0)
		return 0.0
	
	# iterate over all nodes and find the max solved flow
	var MIN_CFS := Utils.gpm_to_cftps(Globals.FLOW_MIN_GPM)
	var local_max_q_cfs := MIN_CFS
	for pipe in pipes:
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
	
	if pipes.size() == 0:
		_min_q_cfs.set_known(0.0)
		return 0.0
	
	# iterate over all nodes and find the min solved flow
	var MAX_CFS := Utils.gpm_to_cftps(Globals.FLOW_MAX_GPM)
	var local_min_q_cfs := MAX_CFS
	for pipe in pipes:
		if pipe.q_cfs.state != Var.State.Unknown:
			local_min_q_cfs = min(local_min_q_cfs, pipe.q_cfs.value)
	
	# didn't find a solved flow, so just default to 0
	if local_min_q_cfs == MAX_CFS:
		local_min_q_cfs = 0.0
	_min_q_cfs.set_known(local_min_q_cfs)
	return local_min_q_cfs

func add_entity(e: FEntity) -> void:
	if e is FPipe:
		if e in pipes:
			return
		pipes.push_back(e)
		equations.push_back(_equation_pipe.bind(e))
	elif e is FNode:
		if e in nodes:
			return
		nodes.push_back(e)
		equations.push_back(_equation_node.bind(e))
		_update_max_elevation()
	else:
		push_error("unsupported entity type")
		return
	
	e.fsubsys = self
	var evars := get_entity_vars(e)
	for evar in evars:
		if evar.state == Var.State.Unknown and ! evar in unknown_vars:
			unknown_vars.push_back(evar)

func add_entities(arr: Array) -> void:
	for e in arr:
		add_entity(e as FEntity)

func constrain_type() -> ConstrainType:
	if unknown_vars.size() > equations.size():
		return ConstrainType.Under
	elif unknown_vars.size() == equations.size():
		return ConstrainType.Well
	return ConstrainType.Over

static func _get_pipe_vars(p: FPipe) -> Array[Var]:
	var out_vars : Array[Var] = [p.q_cfs]
	if ! is_instance_valid(p.src_node):
		out_vars.push_back(Var.new(p, "src_node_h_psi"))
		out_vars.push_back(Var.new(p, "src_node_q_ext_cfs"))
	if ! is_instance_valid(p.sink_node):
		out_vars.push_back(Var.new(p, "sink_node_h_psi"))
		out_vars.push_back(Var.new(p, "sink_node_q_ext_cfs"))
	return out_vars

func _equation_pipe(p: FPipe) -> float:
	# delta_h_psi is the net pressure drop across the pipe. we must
	# subtract the static pressure due to gravity to get the net dynamic
	# pressure due to losses accross the pipe.
	var dynamic_h_psi := p._flt_delta_h_psi() - p._flt_delta_static_h_psi()
	
	# calculate our net losses
	var _v_fps := p._flt_v_fps()
	var _Re := p._flt_Re(_v_fps)
	var _f_darcy := p._flt_f_darcy(_Re)
	var major_loss_psi := p._flt_major_loss_psi(_v_fps, _f_darcy, p.l_ft)
	var entry_minor_loss_psi := p._flt_entry_minor_loss_psi(_v_fps, _f_darcy)
	var exit_minor_loss_psi := p._flt_exit_minor_loss_psi(_v_fps, _f_darcy)
	var net_losses = major_loss_psi + entry_minor_loss_psi + exit_minor_loss_psi
	
	# all of our losses should equation to our dynamic_h across our pipe.
	# calutate the final equation where ... dynamic_h + net_losses = 0
	return dynamic_h_psi + net_losses

func _equation_node(n: FNode) -> float:
	# all of our net flow rates in/out of the node should equal 0
	var net_flow := n.q_ext_cfs.value
	for p in n.connected_pipes:
		var flow_sign := 1.0 if n.is_inward_pipe(p) else -1.0
		net_flow += p.q_cfs.value * flow_sign
	return net_flow

func _update_max_elevation() -> void:
	if nodes.is_empty():
		_max_el_ft = 0.0
		return
	
	for i in range(nodes.size()):
		if i == 0:
			_max_el_ft = nodes[i].el_ft
		else:
			_max_el_ft = max(_max_el_ft, nodes[i].el_ft)
