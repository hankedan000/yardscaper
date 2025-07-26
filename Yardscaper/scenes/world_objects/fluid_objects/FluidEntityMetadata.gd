class_name FluidEntityMetadata extends RefCounted

# the owning WorldObject for this entity
var parent_wobj : WorldObject = null

# true if the FluidEntity is one of those that are internally managed by
# Yardscaper and should be hidden from the user. Examples of this are the
# FPipe and FNode eneities we create for simulating Sprinkler nozzles.
var is_hidden_entity : bool = false

func _init(wobj: WorldObject, hidden: bool) -> void:
	parent_wobj = wobj
	is_hidden_entity = hidden
