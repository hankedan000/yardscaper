class_name FSolver
extends Object

# entities that are actually connected to each other within the full FSystem
class SubSystem:
	var nodes : Array[FNode] = []
	var pipes : Array[FPipe] = []

class UnknownCounter:
	var num_unknown : int = 0
	var num_total : int = 0
	
	func incr(is_unknown: bool) -> void:
		num_total += 1
		if is_unknown:
			num_unknown += 1

# Under constrained: unknown_vars > equation_count
# Well constrained:  unknown_vars == equation_count
# Over constrained:  unknown_vars < equation_count
enum ConstrainType {
	Under, Well, Over
}

class ConstraintStats:
	# counters representing known/unknown counts
	var pressure_counts : UnknownCounter = UnknownCounter.new()
	var flow_counts     : UnknownCounter = UnknownCounter.new()
	var equation_count : int = 0

	func get_unknown_vars() -> int:
		return pressure_counts.num_unknown + flow_counts.num_unknown

	func get_equation_count() -> int:
		return equation_count

	func get_type() -> ConstrainType:
		var unknown_vars := get_unknown_vars()
		if unknown_vars == equation_count:
			return ConstrainType.Well
		elif unknown_vars > equation_count:
			return ConstrainType.Under
		else:
			return ConstrainType.Over

static func make_sub_systems(fsys: FSystem) -> Array[SubSystem]:
	var systems : Array[SubSystem] = []
	
	# make a frontier of unexplored entities. then recursively explore the
	# nodes while building SubSystems of intra-connected entities.
	var frontier := SubSystem.new()
	frontier.pipes = fsys.get_pipes()
	frontier.nodes = fsys.get_nodes()
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
	subsys.nodes.push_back(node)
	for p in node.connected_pipes:
		_explore_pipe(p, frontier, subsys)

static func _explore_pipe(pipe: FPipe, frontier: SubSystem, subsys: SubSystem) -> void:
	if _is_explored(pipe, frontier):
		return
	
	frontier.pipes.erase(pipe)
	subsys.pipes.push_back(pipe)
	_explore_node(pipe.src_node, frontier, subsys)
	_explore_node(pipe.sink_node, frontier, subsys)

static func calc_constraint_stats(subsys: SubSystem) -> ConstraintStats:
	var stats := ConstraintStats.new()
	
	for p in subsys.pipes:
		stats.flow_counts.incr( ! p.q_cfs.known)
		stats.equation_count += 1
		if ! is_instance_valid(p.src_node):
			stats.pressure_counts.incr(true)
			stats.flow_counts.incr(true)
		if ! is_instance_valid(p.sink_node):
			stats.pressure_counts.incr(true)
			stats.flow_counts.incr(true)
	
	for n in subsys.nodes:
		stats.pressure_counts.incr( ! n.h_psi.known)
		stats.flow_counts.incr( ! n.q_ext_cfs.known)
		stats.equation_count += 1
	
	return stats
