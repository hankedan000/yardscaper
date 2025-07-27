class_name FPipe extends FEntity

const NODE_SINK := true
const NODE_SRC  := false

var src_node  : FNode = null
var sink_node : FNode = null
var q_cfs     : Var = null
var d_ft      : float = 0.0 # hydraulic diameter
var l_ft      : float = 0.0 # length of the pipe
var E_ft      : float = 0.0 # absolute roughness of pipe material
var K_entry   : float = 0.0 # minor loss coefficient for fitting at pipe entry
var K_exit    : float = 0.0 # minor loss coefficient for fitting at pipe exit

func _init(e_fsys: FSystem, e_id: int) -> void:
	super(e_fsys, e_id)
	self.q_cfs = Var.new(self, "q_cfs")

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

func is_my_var(v: Var) -> bool:
	if v == q_cfs:
		return true
	return false

func reset_solved_vars(clear_values: bool = false) -> void:
	q_cfs.reset_if_solved(clear_values)

# cross sectional area of the pipe inf square feet
func area_ft2() -> float:
	var r_ft := d_ft / 2.0
	return PI * r_ft * r_ft

func v_fps() -> Var:
	var out := Var.new(self, "v_fps")
	out.state = q_cfs.state
	out.value = _flt_v_fps()
	return out

func src_h_psi() -> Var:
	var h_psi := Var.new(self, "src_h_psi")
	if ! is_instance_valid(src_node):
		return h_psi
	
	h_psi.value = src_node.h_psi.value
	h_psi.state = src_node.h_psi.state
	return h_psi

func sink_h_psi() -> Var:
	var h_psi := Var.new(self, "sink_h_psi")
	if ! is_instance_valid(sink_node):
		return h_psi
	
	h_psi.value = sink_node.h_psi.value
	h_psi.state = sink_node.h_psi.state
	return h_psi

func delta_h_psi() -> Var:
	var delta_h := Var.new(self, "delta_h_psi")
	if ! is_instance_valid(src_node):
		return delta_h
	elif ! is_instance_valid(sink_node):
		return delta_h
	
	delta_h.value = _flt_delta_h_psi()
	delta_h.state = Var.merge_var_states([src_node.h_psi, sink_node.h_psi])
	return delta_h

# reynolds number
func Re() -> Var:
	var out = Var.new(self, "Re")
	out.state = q_cfs.state
	out.value = _flt_Re(_flt_v_fps())
	return out

func relative_roughness() -> float:
	if d_ft == 0.0:
		push_warning("%s d_ft is 0" % self)
	return E_ft / d_ft

func f_darcy() -> Var:
	var out = Var.new(self, "f_darcy")
	out.state = q_cfs.state
	out.value = _flt_f_darcy(_flt_Re(_flt_v_fps()))
	return out

func major_loss_psi() -> Var:
	var out := Var.new(self, "major_loss_psi")
	out.state = q_cfs.state
	var _v_fps := _flt_v_fps()
	var _f_darcy := _flt_f_darcy(_flt_Re(_v_fps))
	out.value = _flt_major_loss_psi(_v_fps, _f_darcy)
	return out

func entry_minor_loss_psi() -> Var:
	var out := Var.new(self, "entry_minor_loss_psi")
	out.value = _flt_entry_minor_loss_psi(_flt_v_fps())
	out.state = q_cfs.state
	return out

func exit_minor_loss_psi() -> Var:
	var out := Var.new(self, "exit_minor_loss_psi")
	out.value = _flt_exit_minor_loss_psi(_flt_v_fps())
	out.state = q_cfs.state
	return out

func _flt_v_fps() -> float:
	var area := area_ft2()
	if area == 0.0:
		push_warning("%s area is 0" % self)
	return q_cfs.value / area

func _flt_delta_h_psi() -> float:
	if ! is_instance_valid(src_node):
		return 0.0
	elif ! is_instance_valid(sink_node):
		return 0.0
	
	return sink_node.h_psi.value - src_node.h_psi.value

func _flt_Re(arg_v_fps: float) -> float:
	return FluidMath.reynolds(arg_v_fps, d_ft, fsys.fluid_viscocity_k)

func _flt_f_darcy(arg_Re: float) -> float:
	return FluidMath.f_darcy(arg_Re, relative_roughness())

func _flt_major_loss_psi(arg_v_fps: float, arg_f_darcy: float) -> float:
	# if v is 0 then f_darcy would blow up to infinity. regardlesa, if there is
	# no velocity then there's no frictional losses.
	if arg_v_fps == 0.0:
		return 0.0
	return FluidMath.major_loss_psi(arg_f_darcy, l_ft, arg_v_fps, fsys.fluid_density_lbft3, d_ft)

func _flt_entry_minor_loss_psi(arg_v_fps: float) -> float:
	return _flt_minor_loss_psi(arg_v_fps, K_entry)

func _flt_exit_minor_loss_psi(arg_v_fps: float) -> float:
	return _flt_minor_loss_psi(arg_v_fps, K_exit)

func _flt_minor_loss_psi(arg_v_fps: float, arg_k: float) -> float:
	return Utils.psft_to_psi(arg_k * fsys.fluid_density_lbft3 * (arg_v_fps * arg_v_fps) / 2.0)

func _predelete() -> void:
	disconnect_node(src_node)
	disconnect_node(sink_node)

func _to_string() -> String:
	return "P%d" % id
