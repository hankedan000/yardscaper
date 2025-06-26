class_name Var
extends RefCounted

var value : float = 0.0
var known : bool = false

func _init() -> void:
	reset()

func reset() -> void:
	value = 0.0
	known = false

func set_known(v: float) -> void:
	value = v
	known = true
