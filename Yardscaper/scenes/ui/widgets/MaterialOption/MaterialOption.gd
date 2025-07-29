class_name MaterialOption extends OptionWithCustomSpinbox

func _ready() -> void:
	# TODO we don't support custom material roughness yet. mostly because the
	# minor loss lookup table is by material type. i think we could change the
	# minor loss table to be in terms of "equivalent length of pipe" in which
	# case you can compute the minor loss with the surface roughness of the
	# material.
	
	#          label,              id,                                         icon,       is_custom_option
	add_option("Custom",           int(PipeTables.MaterialType.CUSTOM),        null,       true)
	add_option("PVC",              int(PipeTables.MaterialType.PVC),           null,       false)
	option_button.set_item_disabled(0, true)
	option_button.set_item_tooltip(0, "Custom materials not yet supported.")
	spinbox.suffix = Utils.DISP_UNIT_FT
	spinbox.min_value = 0.0
	spinbox.max_value = 0.5
	spinbox.step = 0.00000001
	select_option_by_id(int(PipeTables.MaterialType.PVC))
