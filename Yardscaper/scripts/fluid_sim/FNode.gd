class_name FNode extends FEntity

enum Type {
	Normal, Sprink
}

var h_psi           : Var = null   # pressure at the node
var q_ext_cfs       : Var = null   # external flow in(+) or out(-) ft^3/s
var el_ft           : float = 0.0  # elevation of the node
var connected_pipes : Array[FPipe] = []
var K_s             : float = 0.0: # used only if type = Sprink. used to solve
								   # for q_ext_cfs = K_s * sqrt(h_psi)
	set(value):
		K_s = value
		if _type == Type.Sprink:
			_recalc_q_ext_cfs()

var _type : Type = Type.Normal

func _init(e_fsys: FSystem, e_id: int) -> void:
	super(e_fsys, e_id)
	self.h_psi = Var.new(self, "h_psi")
	self.q_ext_cfs = Var.new(self, "q_ext_cfs")

func set_type(new_type: Type) -> void:
	_type = new_type
	if _type == Type.Sprink:
		h_psi.add_value_change_listener(_recalc_q_ext_cfs)
		h_psi.state = Var.State.Unknown
		q_ext_cfs.state = Var.State.Known
		_recalc_q_ext_cfs()
	else:
		h_psi.remove_value_change_listener(_recalc_q_ext_cfs)
		h_psi.state = Var.State.Unknown
		q_ext_cfs.state = Var.State.Unknown

func get_type() -> Type:
	return _type

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

func _recalc_q_ext_cfs() -> void:
	var h_psi_mag := absf(h_psi.value)
	var flow_dir := signf(h_psi.value) * -1.0 # (+) pressure -> outward flow (-)
	q_ext_cfs.value = K_s * sqrt(h_psi_mag) * flow_dir

func _to_string() -> String:
	return "N%d" % id

# called by FSystem when it's freeing us
func _predelete() -> void:
	for p in connected_pipes.duplicate() as Array[FPipe]:
		p.disconnect_node(self)
