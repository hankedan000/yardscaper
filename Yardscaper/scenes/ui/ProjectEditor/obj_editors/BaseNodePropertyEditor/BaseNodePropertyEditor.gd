class_name BaseNodePropertyEditor extends WorldObjectPropertyEditor

@onready var pressure_spinbox         : OverrideSpinbox = $VBoxContainer/PropertiesList/PressureSpinbox
@onready var ext_flow_spinbox         : OverrideSpinbox = $VBoxContainer/PropertiesList/ExtFlowSpinbox

# override so we can validate the type
func add_object(wobj: WorldObject) -> void:
	if wobj is BaseNode:
		super.add_object(wobj)

func _sync_ui_from_obj() -> void:
	super._sync_ui_from_obj()
	
	var ref_node := _wobjs[0] as BaseNode
	_sync_var_to_spinbox(ref_node.fnode.h_psi, pressure_spinbox)
	_sync_var_to_spinbox(ref_node.fnode.q_ext_cfs, ext_flow_spinbox, Utils.cftps_to_gpm)

static func _sync_var_to_spinbox(fvar: Var, spinbox: OverrideSpinbox, conv_func:=Callable()) -> void:
	spinbox.set_overriden(fvar.state == Var.State.Known)
	var conv_value := fvar.value
	if conv_func.is_valid():
		conv_value = conv_func.call(fvar.value)
	spinbox.set_control_value(conv_value)

func _on_pressure_spinbox_override_changed(new_overriden: bool) -> void:
	for node: BaseNode in _wobjs:
		node.fnode.h_psi.state = Var.State.Known if new_overriden else Var.State.Unknown

func _on_pressure_spinbox_value_changed(new_value: Variant) -> void:
	for node: BaseNode in _wobjs:
		node.fnode.h_psi.value = new_value

func _on_ext_flow_spinbox_override_changed(new_overriden: bool) -> void:
	for node: BaseNode in _wobjs:
		node.fnode.q_ext_cfs.state = Var.State.Known if new_overriden else Var.State.Unknown

func _on_ext_flow_spinbox_value_changed(new_q_gpm: Variant) -> void:
	for node: BaseNode in _wobjs:
		node.fnode.q_ext_cfs.value = Utils.gpm_to_cftps(new_q_gpm)
