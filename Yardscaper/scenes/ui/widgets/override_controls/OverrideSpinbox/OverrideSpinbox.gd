class_name OverrideSpinbox extends OverrideControl

@export var suffix : String = "":
	set(value):
		if is_instance_valid(control):
			(control as SpinBox).suffix = value
		else:
			suffix = value
	get():
		if is_instance_valid(control):
			return (control as SpinBox).suffix
		else:
			return suffix

func _ready() -> void:
	var init_suffix := suffix # reapply after control is found in super._ready()
	super._ready()
	suffix = init_suffix
