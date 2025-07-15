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
	self.q_cfs = Var.new("%s_q_cfs" % self)

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

func v_fps() -> Var:
	var out := Var.new("%s_v_fps" % self)
	var area := area_ft2()
	if area == 0.0:
		push_warning("%s area is 0" % self)
	out.state = q_cfs.state
	out.value = q_cfs.value / area
	return out

func src_h_psi() -> Var:
	var h_psi := Var.new("%s_src_h_psi" % self)
	if ! is_instance_valid(src_node):
		return h_psi
	
	h_psi.value = src_node.h_psi.value
	h_psi.state = src_node.h_psi.state
	return h_psi

func sink_h_psi() -> Var:
	var h_psi := Var.new("%s_sink_h_psi" % self)
	if ! is_instance_valid(sink_node):
		return h_psi
	
	h_psi.value = sink_node.h_psi.value
	h_psi.state = sink_node.h_psi.state
	return h_psi

func delta_h_psi() -> Var:
	var delta_h := Var.new("%s_delta_h_psi" % self)
	if ! is_instance_valid(src_node):
		return delta_h
	elif ! is_instance_valid(sink_node):
		return delta_h
	
	delta_h.value = sink_node.h_psi.value - src_node.h_psi.value
	delta_h.state = Var.merge_var_states([src_node.h_psi, sink_node.h_psi])
	return delta_h

# reynolds number
func Re() -> Var:
	return _calc_Re(v_fps())

func relative_roughness() -> float:
	if d_ft == 0.0:
		push_warning("%s d_ft is 0" % self)
	return E_ft / d_ft

func f_darcy() -> Var:
	return _calc_f_darcy(Re())

func major_loss_psi() -> Var:
	var out := Var.new("%s_major_loss_psi" % self)
	var _v_fps := v_fps()
	out.state = _v_fps.state
	
	# if v is 0 then f_darcy would blow up to infinity. regardles if there is
	# no velocity then there's no frictional losses.
	if _v_fps.value == 0.0:
		out.value = 0.0
		return out
	
	var _Re := _calc_Re(_v_fps)
	var _f_darcy := _calc_f_darcy(_Re)
	out.value = FluidMath.major_loss(_f_darcy.value, l_ft, _v_fps.value, fsys.fluid_density_lbft3, d_ft)
	return out

func entry_minor_loss_psi() -> Var:
	var out := Var.new("%s_entry_minor_loss_psi" % self)
	var _v_fps := v_fps()
	out.value = K_entry * fsys.fluid_density_lbft3 * (_v_fps.value * _v_fps.value) / 2.0
	out.state = _v_fps.state
	return out

func exit_minor_loss_psi() -> Var:
	var out := Var.new("%s_exit_minor_loss_psi" % self)
	var _v_fps := v_fps()
	out.value = K_exit * fsys.fluid_density_lbft3 * (_v_fps.value * _v_fps.value) / 2.0
	out.state = _v_fps.state
	return out

func _calc_Re(v_fps_in: Var) -> Var:
	var out := Var.new("%s_Re" % self)
	out.value = FluidMath.reynolds(v_fps_in.value, d_ft, fsys.fluid_viscocity_k)
	out.state = v_fps_in.state
	return out

func _calc_f_darcy(Re_in: Var) -> Var:
	var out := Var.new("%s_f_darcy" % self)
	out.value = FluidMath.f_darcy(Re_in.value, relative_roughness())
	out.state = Re_in.state
	return out

func _predelete() -> void:
	disconnect_node(src_node)
	disconnect_node(sink_node)

func _to_string() -> String:
	return "P%d" % id
