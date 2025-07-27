class_name PipeFittingOption extends OptionWithCustomSpinbox

func _ready() -> void:
	#          label,              id,                                         icon,                        is_custom_option
	add_option("None",             int(PipeTables.FittingType.NONE),           null,                        false)
	add_option("Custom",           int(PipeTables.FittingType.CUSTOM),         FittingIcons.CUSTOM,         true)
	add_option("Coupling",         int(PipeTables.FittingType.COUPLING),       FittingIcons.COUPLING,       false)
	add_option("45 Elbow",         int(PipeTables.FittingType.ELBOW_45),       FittingIcons.ELBOW_45,       false)
	add_option("90 Elbow",         int(PipeTables.FittingType.ELBOW_90),       FittingIcons.ELBOW_90,       false)
	add_option("Tee (Run)",        int(PipeTables.FittingType.TEE_RUN),        FittingIcons.TEE_RUN,        false)
	add_option("Tee (Branch Out)", int(PipeTables.FittingType.TEE_BRANCH_OUT), FittingIcons.TEE_BRANCH_OUT, false)
	add_option("Tee (Branch In)",  int(PipeTables.FittingType.TEE_BRANCH_IN),  FittingIcons.TEE_BRANCH_IN,  false)
