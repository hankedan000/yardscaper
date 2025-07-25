class_name FSolver extends Object

# Under constrained: unknown_vars > equation_count
# Well constrained:  unknown_vars == equation_count
# Over constrained:  unknown_vars < equation_count
enum ConstrainType {
	Under, Well, Over
}

# entities that are actually connected to each other within the full FSystem
class SubSystem extends RefCounted:
	var nodes : Array[FNode] = []
	var pipes : Array[FPipe] = []
	var unknown_vars : Array[Var] = []
	var equations : Array[Callable] = []

	static func get_entity_vars(e: FEntity) -> Array[Var]:
		if e is FPipe:
			return _get_pipe_vars(e)
		elif e is FNode:
			return [e.h_psi, e.q_ext_cfs]
		push_error("unsupported FEntity type")
		return []
	
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
		else:
			push_error("unsupported entity type")
			return
		
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
			out_vars.push_back(Var.new("%s_src_node_h_psi" % p))
			out_vars.push_back(Var.new("%s_src_node_q_ext_cfs" % p))
		if ! is_instance_valid(p.sink_node):
			out_vars.push_back(Var.new("%s_sink_node_h_psi" % p))
			out_vars.push_back(Var.new("%s_sink_node_q_ext_cfs" % p))
		return out_vars
	
	func _equation_pipe(p: FPipe) -> float:
		var delta_h_psi := p._flt_delta_h_psi()
		
		# calculate our net losses
		var _v_fps := p._flt_v_fps()
		var _Re := p._flt_Re(_v_fps)
		var _f_darcy := p._flt_f_darcy(_Re)
		var major_loss_psi := p._flt_major_loss_psi(_v_fps, _f_darcy)
		var entry_minor_loss_psi := p._flt_entry_minor_loss_psi(_v_fps)
		var exit_minor_loss_psi := p._flt_exit_minor_loss_psi(_v_fps)
		var net_losses = major_loss_psi + entry_minor_loss_psi + exit_minor_loss_psi
		
		# all of our losses should equation to our delta_h across our nodes
		# calutate the final equation where ... delta_h + net_losses = 0
		return delta_h_psi + net_losses
	
	func _equation_node(n: FNode) -> float:
		# all of our net flow rates in/out of the node should equal 0
		var net_flow := n.q_ext_cfs.value
		for p in n.connected_pipes:
			var flow_sign := 1.0 if n.is_inward_pipe(p) else -1.0
			net_flow += p.q_cfs.value * flow_sign
		return net_flow

static func make_sub_systems(fsys: FSystem) -> Array[SubSystem]:
	var systems : Array[SubSystem] = []
	
	# make a frontier of unexplored entities. then recursively explore the
	# nodes while building SubSystems of intra-connected entities.
	var frontier := SubSystem.new()
	frontier.add_entities(fsys.get_pipes())
	frontier.add_entities(fsys.get_nodes())
	while frontier.nodes.size() > 0:
		var subsys := SubSystem.new()
		_explore_node(frontier.nodes[0], frontier, subsys)
		systems.push_back(subsys)
	
	# for completeness, add any unconnected pipes to their own SubSystem
	if frontier.pipes.size() > 0:
		var subsys := SubSystem.new()
		for p in frontier.pipes:
			subsys.pipes.push_back(p)
		systems.push_back(subsys)
	
	return systems

static func _basic_console_printer(iter: int, x: Array[float], ssys: SubSystem) -> void:
	var dbg_str := "iter[%d] - " % iter
	var comma := ""
	for i in range(x.size()):
		var uvar := ssys.unknown_vars[i]
		dbg_str += "%s%s=%f" % [comma, uvar.name, uvar.value]
		comma = ", "
	print(dbg_str)

class Settings extends RefCounted:
	var tol          : float = 1e-9
	var max_iters    : int = 100
	var max_delta    : float = 1000.0
	var dbg_printer  : Callable = Callable()
	
	func set_basic_console_printer() -> void:
		dbg_printer = FSolver._basic_console_printer

class FSystemSolveResult extends RefCounted:
	var solved : bool = false
	var sub_systems : Array[SubSystem] = []
	var sub_system_results : Array[Math.FSolveResult] = []

static func solve_system(fsys: FSystem, settings:=Settings.new()) -> FSystemSolveResult:
	var res := FSystemSolveResult.new()
	if ! is_instance_valid(fsys):
		push_error("fsys must be valid")
		return res
	elif ! is_instance_valid(settings):
		push_error("settings must be valid")
		return res
	
	res.sub_systems = make_sub_systems(fsys)
	res.solved = true
	for ssys in res.sub_systems:
		var sres := solve_sub_system(ssys, settings)
		res.solved = res.solved && sres.converged
		res.sub_system_results.push_back(sres)
	return res

static func solve_sub_system(ssys: SubSystem, settings:=Settings.new()) -> Math.FSolveResult:
	if ! is_instance_valid(ssys):
		return Math.FSolveResult.new()
	
	# make sure system is Well constrainted
	var ctype := ssys.constrain_type()
	if ctype != ConstrainType.Well:
		return Math.FSolveResult.new()
	
	# solve the system of equations
	var x0 : Array[float] = []
	for uvar in ssys.unknown_vars:
		x0.push_back(uvar.value)
	var this_debug_printer := settings.dbg_printer.bind(ssys)
	var res := Math.fsolve(
		_fsolve_subsystem.bind(ssys), # f(x)
		x0,
		settings.tol,
		settings.max_iters,
		settings.max_delta,
		this_debug_printer)
	
	if res.converged:
		for uvar in ssys.unknown_vars:
			uvar.state = Var.State.Solved
	return res

static func _is_explored(fentity, frontier: SubSystem):
	if fentity is FNode:
		return ! (fentity in frontier.nodes)
	else:
		return ! (fentity in frontier.pipes)

static func _explore_node(node: FNode, frontier: SubSystem, subsys: SubSystem) -> void:
	if ! is_instance_valid(node):
		return
	elif _is_explored(node, frontier):
		return
	
	frontier.nodes.erase(node)
	subsys.add_entity(node)
	for p in node.connected_pipes:
		_explore_pipe(p, frontier, subsys)

static func _explore_pipe(pipe: FPipe, frontier: SubSystem, subsys: SubSystem) -> void:
	if _is_explored(pipe, frontier):
		return
	
	frontier.pipes.erase(pipe)
	subsys.add_entity(pipe)
	_explore_node(pipe.src_node, frontier, subsys)
	_explore_node(pipe.sink_node, frontier, subsys)

static func _fsolve_subsystem(x: PackedFloat64Array, y_out: PackedFloat64Array, ssys: SubSystem) -> void:
	# substitute our latest guesses into the unknown variables
	for i in range(x.size()):
		ssys.unknown_vars[i].value = x[i]
	
	# re-evaluate all of the equations in the SubSystem and returns results
	var n_eq := ssys.equations.size()
	for e in range(n_eq):
		y_out[e] = ssys.equations[e].call()
