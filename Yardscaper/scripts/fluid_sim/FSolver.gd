class_name FSolver extends Object

static func make_sub_systems(fsys: FSystem) -> Array[FSubSystem]:
	var systems : Array[FSubSystem] = []
	
	# make a frontier of unexplored entities. then recursively explore the
	# nodes while building FSubSystems of intra-connected entities.
	var frontier := FSubSystem.new()
	frontier.add_entities(fsys.get_pipes())
	frontier.add_entities(fsys.get_nodes())
	while frontier.nodes.size() > 0:
		var subsys := FSubSystem.new()
		_explore_node(frontier.nodes[0], frontier, subsys)
		systems.push_back(subsys)
	
	# for completeness, add any unconnected pipes to their own FSubSystem
	if frontier.pipes.size() > 0:
		var subsys := FSubSystem.new()
		for p in frontier.pipes:
			subsys.pipes.push_back(p)
		systems.push_back(subsys)
	
	return systems

static func _basic_console_printer(iter: int, x: Array[float], ssys: FSubSystem) -> void:
	var dbg_str := "iter[%d] - " % iter
	var comma := ""
	for i in range(x.size()):
		var uvar := ssys.unknown_vars[i]
		dbg_str += "%s%s=%f" % [comma, uvar.get_name_with_entity(), uvar.value]
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
	var sub_systems : Array[FSubSystem] = []
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

static func solve_sub_system(ssys: FSubSystem, settings:=Settings.new()) -> Math.FSolveResult:
	if ! is_instance_valid(ssys):
		return Math.FSolveResult.new()
	
	# make sure system is Well constrainted
	var ctype := ssys.constrain_type()
	if ctype != FSubSystem.ConstrainType.Well:
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

static func _is_explored(fentity, frontier: FSubSystem):
	if fentity is FNode:
		return ! (fentity in frontier.nodes)
	else:
		return ! (fentity in frontier.pipes)

static func _explore_node(node: FNode, frontier: FSubSystem, subsys: FSubSystem) -> void:
	if ! is_instance_valid(node):
		return
	elif _is_explored(node, frontier):
		return
	
	frontier.nodes.erase(node)
	subsys.add_entity(node)
	for p in node.connected_pipes:
		_explore_pipe(p, frontier, subsys)

static func _explore_pipe(pipe: FPipe, frontier: FSubSystem, subsys: FSubSystem) -> void:
	if _is_explored(pipe, frontier):
		return
	
	frontier.pipes.erase(pipe)
	subsys.add_entity(pipe)
	_explore_node(pipe.src_node, frontier, subsys)
	_explore_node(pipe.sink_node, frontier, subsys)

static func _fsolve_subsystem(x: PackedFloat64Array, y_out: PackedFloat64Array, ssys: FSubSystem) -> void:
	# substitute our latest guesses into the unknown variables
	for i in range(x.size()):
		ssys.unknown_vars[i].value = x[i]
	
	# re-evaluate all of the equations in the FSubSystem and returns results
	var n_eq := ssys.equations.size()
	for e in range(n_eq):
		y_out[e] = ssys.equations[e].call()
