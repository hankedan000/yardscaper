class_name BaseNodePropertyEditor extends WorldObjectPropertyEditor

@onready var pressure_label           : Label = $VBoxContainer/PropertiesList/PressureLabel
@onready var pressure_spinbox         : OverrideSpinbox = $VBoxContainer/PropertiesList/PressureSpinbox
@onready var ext_flow_label           : Label = $VBoxContainer/PropertiesList/ExtFlowLabel
@onready var ext_flow_spinbox         : OverrideSpinbox = $VBoxContainer/PropertiesList/ExtFlowSpinbox

func _ready() -> void:
	super._ready()
	_setup_pressure_spinbox(pressure_spinbox.control as SpinBox)
	_setup_flow_rate_spinbox(ext_flow_spinbox.control as SpinBox)

# override so we can validate the type
func add_object(wobj: WorldObject) -> void:
	if wobj is BaseNode:
		super.add_object(wobj)

func _sync_ui_from_obj() -> void:
	super._sync_ui_from_obj()
	
	var ref_node := _wobjs[0] as BaseNode
	_sync_fvar_to_spinbox(ref_node.fnode.h_psi, pressure_spinbox)
	_sync_fvar_to_spinbox(ref_node.fnode.q_ext_cfs, ext_flow_spinbox, Utils.cftps_to_gpm)

func _on_pressure_spinbox_override_changed(new_overriden: bool) -> void:
	_apply_fluid_prop_edit(BaseNode.PROP_KEY_FNODE_H_PSI, _override_to_var_state(new_overriden))

func _on_pressure_spinbox_value_changed(new_value: Variant) -> void:
	_apply_fluid_prop_edit(BaseNode.PROP_KEY_FNODE_H_PSI, new_value as float)

func _on_ext_flow_spinbox_override_changed(new_overriden: bool) -> void:
	_apply_fluid_prop_edit(BaseNode.PROP_KEY_FNODE_Q_EXT_CFS, _override_to_var_state(new_overriden))

func _on_ext_flow_spinbox_value_changed(new_q_gpm: Variant) -> void:
	_apply_fluid_prop_edit(BaseNode.PROP_KEY_FNODE_Q_EXT_CFS, Utils.gpm_to_cftps(new_q_gpm))
