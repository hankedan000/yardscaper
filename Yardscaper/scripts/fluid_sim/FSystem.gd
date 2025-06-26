class_name FSystem
extends RefCounted

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
	var pipe := FPipe.new()
	pipe.id = get_next_node_id()
	pipe.fsys = self
	_pipes.append(pipe)
	return pipe

func alloc_node() -> FNode:
	var node := FNode.new()
	node.id = get_next_node_id()
	node.fsys = self
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

func clear() -> void:
	for p in _pipes.duplicate():
		free_pipe(p)
	_pipes.clear()
	_next_pipe_id = 0
	for n in _nodes.duplicate():
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
