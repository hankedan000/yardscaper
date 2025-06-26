class_name FNode
extends Object

var id              : int = 1 # unique identifier
var fsys            : FSystem = null
var h_psi           : Var = Var.new() # pressure at the node
var q_ext_cfs       : Var = Var.new() # external flow in(+) or out(-) ft^3/s
var el_ft           : float = 0.0 # elevation of the node
var connected_pipes : Array[FPipe] = []

func is_outward_pipe(p: FPipe) -> bool:
	if is_instance_valid(p):
		return p.src_node == self
	return false

func is_inward_pipe(p: FPipe) -> bool:
	if is_instance_valid(p):
		return p.sink_node == self
	return false

# called by FSystem when it's freeing us
func _predelete() -> void:
	for p in connected_pipes.duplicate() as Array[FPipe]:
		p.disconnect_node(self)
