class_name FluidSimulator
extends Node

var _all_pipes : Array[Pipe] = []

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	set_process(false)

func get_all_pipes() -> Array[Pipe]:
	return _all_pipes.duplicate()

func reset() -> void:
	for pipe in _all_pipes.duplicate():
		remove_pipe(pipe)

func initialize_pipe_flow_sources() -> void:
	for pipe in _all_pipes:
		pipe.init_flow_source(get_all_pipes())

func add_pipe(pipe: Pipe) -> void:
	if pipe in _all_pipes:
		return # avoid duplicate adds
	pipe.flow_source_changed.connect(_on_pipe_flow_source_changed)
	pipe._sim = self
	_all_pipes.append(pipe)

func remove_pipe(pipe: Pipe) -> void:
	var idx := _all_pipes.find(pipe)
	if idx >= 0:
		pipe.flow_source_changed.disconnect(_on_pipe_flow_source_changed)
		pipe._sim = null
		_all_pipes.remove_at(idx)

func queue_recalc() -> void:
	set_process(true)

func _on_pipe_flow_source_changed() -> void:
	queue_recalc()
