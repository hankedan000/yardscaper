class_name FEntity extends Object

var id   : int = 1 # unique identifier
var fsys : FSystem = null
var user_metadata : Variant = null # can be anything the user wants

func _init(e_fsys: FSystem, e_id: int) -> void:
	self.fsys = e_fsys
	self.id = e_id

func is_my_var(_v: Var) -> bool:
	push_warning("method should be overriden")
	return false

func reset_solved_vars() -> void:
	push_warning("method should be overriden")
	pass
