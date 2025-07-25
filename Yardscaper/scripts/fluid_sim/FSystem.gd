class_name FSystem extends RefCounted

var fluid_viscocity_k : float = FluidMath.WATER_VISCOCITY_K
var fluid_density_lbft3 : float = FluidMath.WATER_DENSITY

var _pipes : Array[FPipe] = []
var _nodes : Array[FNode] = []

var _next_pipe_id : int = 0
var _next_node_id : int = 0

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

func alloc_pipe() -> FPipe:
	var pipe := FPipe.new(self, get_next_pipe_id())
	_pipes.append(pipe)
	return pipe

func alloc_node() -> FNode:
	var node := FNode.new(self, get_next_node_id())
	_nodes.append(node)
	return node

func free_pipe(p: FPipe) -> void:
	if is_instance_valid(p):
		_pipes.erase(p)
		p._predelete()
		p.free()

func free_node(n: FNode) -> void:
	if is_instance_valid(n):
		_nodes.erase(n)
		n._predelete()
		n.free()

func reset_solved_vars(clear_values: bool = false) -> void:
	for node in _nodes:
		node.reset_solved_vars(clear_values)
	for pipe in _pipes:
		pipe.reset_solved_vars(clear_values)

func clear() -> void:
	for p in _pipes:
		free_pipe(p)
	_pipes.clear()
	_next_pipe_id = 0
	for n in _nodes:
		free_node(n)
	_nodes.clear()
	_next_node_id = 0

func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE:
		return
	elif ! is_instance_valid(self):
		return
	
	# free all of our entities
	clear()
