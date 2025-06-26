class_name FPipe
extends Object

const NODE_SINK := true
const NODE_SRC  := false

var id        : int = 1 # unique identifier
var fsys      : FSystem = null
var src_node  : FNode = null
var sink_node : FNode = null
var q_cfs     : Var = Var.new()
var d_ft      : float = 0.0 # hydraulic diameter
var l_ft      : float = 0.0 # length of the pipe
var E_ft      : float = 0.0 # absolute roughness of pipe material
var K_entry   : float = 0.0 # minor loss coefficient for fitting at pipe entry
var K_exit    : float = 0.0 # minor loss coefficient for fitting at pipe exit

func disconnect_node(n: FNode) -> void:
	if ! is_instance_valid(n):
		return
	if n == src_node:
		src_node.connected_pipes.erase(self)
		src_node = null
	elif n == sink_node:
		sink_node.connected_pipes.erase(self)
		sink_node = null

func connect_node(n: FNode, node_type: bool) -> void:
	if ! is_instance_valid(n):
		return
	
	if node_type == NODE_SRC:
		if n == sink_node:
			push_error("can't connect P%d source to the same node as sink (N%d)!" % [id, n.id])
			return
		disconnect_node(src_node)
		n.connected_pipes.push_back(self)
		src_node = n
	else:
		if n == src_node:
			push_error("can't connect P%d sink to the same node as source (N%d)!" % [id, n.id])
			return
		disconnect_node(sink_node)
		n.connected_pipes.push_back(self)
		sink_node = n

# cross sectional area of the pipe inf square feet
func area_ft2() -> float:
	var r_ft := d_ft / 2.0
	return PI * r_ft * r_ft

func _predelete() -> void:
	disconnect_node(src_node)
	disconnect_node(sink_node)
