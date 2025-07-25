class_name FNode extends FEntity

var h_psi           : Var = null # pressure at the node
var q_ext_cfs       : Var = null # external flow in(+) or out(-) ft^3/s
var el_ft           : float = 0.0 # elevation of the node
var connected_pipes : Array[FPipe] = []

func _init(e_fsys: FSystem, e_id: int) -> void:
	super(e_fsys, e_id)
	self.h_psi = Var.new("%s_h_psi" % self)
	self.q_ext_cfs = Var.new("%s_q_ext_cfs" % self)

func is_outward_pipe(p: FPipe) -> bool:
	if is_instance_valid(p):
		return p.src_node == self
	return false

func is_inward_pipe(p: FPipe) -> bool:
	if is_instance_valid(p):
		return p.sink_node == self
	return false

func is_my_var(v: Var) -> bool:
	if v == h_psi:
		return true
	elif v == q_ext_cfs:
		return true
	return false

func reset_solved_vars(clear_values: bool = false) -> void:
	h_psi.reset_if_solved(clear_values)
	q_ext_cfs.reset_if_solved(clear_values)

func _to_string() -> String:
	return "N%d" % id

# called by FSystem when it's freeing us
func _predelete() -> void:
	for p in connected_pipes.duplicate() as Array[FPipe]:
		p.disconnect_node(self)
