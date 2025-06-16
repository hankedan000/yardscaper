class_name FluidSimTest
extends GutTest

var PipeScene : PackedScene = preload("res://scenes/world_objects/Pipe/Pipe.tscn")

var sim_world : Node2D = Node2D.new()
var sim : FluidSimulator = FluidSimulator.new()

func _ready() -> void:
	super._ready()
	add_child(sim_world)
	sim_world.add_child(sim)

func instance_pipe(user_label: String) -> Pipe:
	var new_pipe := PipeScene.instantiate() as Pipe
	new_pipe.user_label = user_label
	sim_world.add_child(new_pipe)
	sim.add_pipe(new_pipe)
	return new_pipe

func after_all():
	sim_world.free()
