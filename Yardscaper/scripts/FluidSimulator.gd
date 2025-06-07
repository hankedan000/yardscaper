class_name FluidSimulator
extends Node

var _all_pipes : Array[Pipe] = []
var _cached_min_pressure : float = 0.0
var _cached_max_pressure : float = 0.0
var _sim_cycle : int = 0 # count the # of simulation cycles the engine has ran

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	if _all_pipes.size() == 0:
		set_process(false)
		return
	
	_sim_cycle += 1
	print("=========== SIM CYCLE %d ===========" % [_sim_cycle])
	
	_cached_max_pressure = -100000.0
	_cached_min_pressure =  100000.0
	for pipe in _all_pipes:
		if pipe.is_flow_source:
			_bake_pipe(pipe)
	
	set_process(false)

func _bake_pipe(pipe: Pipe) -> void:
	print("baking %s ..." % pipe.user_label)
	pipe.rebake()
	_cached_min_pressure = min(_cached_min_pressure, pipe.get_min_pressure())
	_cached_max_pressure = max(_cached_max_pressure, pipe.get_max_pressure())
	for feed_pipe in pipe.get_feed_pipes_by_progress():
		_bake_pipe(feed_pipe)

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
	pipe.needs_rebake.connect(_on_pipe_needs_rebake)
	pipe._sim = self
	_all_pipes.append(pipe)

func remove_pipe(pipe: Pipe) -> void:
	var idx := _all_pipes.find(pipe)
	if idx >= 0:
		pipe.needs_rebake.disconnect(_on_pipe_needs_rebake)
		pipe._sim = null
		_all_pipes.remove_at(idx)

func get_system_min_pressure() -> float:
	return _cached_min_pressure

func get_system_max_pressure() -> float:
	return _cached_max_pressure

func queue_recalc() -> void:
	set_process(true)

func _on_pipe_needs_rebake() -> void:
	queue_recalc()
