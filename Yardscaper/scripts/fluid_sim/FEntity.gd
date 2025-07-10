class_name FEntity
extends Object

var id   : int = 1 # unique identifier
var fsys : FSystem = null

func _init(e_fsys: FSystem, e_id: int) -> void:
	self.fsys = e_fsys
	self.id = e_id
