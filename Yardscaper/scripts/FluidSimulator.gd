class_name FluidSimulator
extends Node

var debug = false
var enable_major_losses : bool = true:
	set(value):
		if value == enable_major_losses:
			return
		enable_major_losses = value
		queue_recalc()

var enable_minor_losses : bool = true:
	set(value):
		if value == enable_minor_losses:
			return
		enable_minor_losses = value
		queue_recalc()

var _all_pipes : Array[Pipe] = []
var _cached_min_pressure : float = 0.0
var _cached_max_pressure : float = 0.0
var _cached_min_flow : float = 0.0
var _cached_max_flow : float = 0.0
var _sim_cycles : int = 0 # count the # of simulation cycles the engine has ran

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	if _all_pipes.size() == 0:
		set_process(false)
		return
	run_calculations()
	set_process(false)

func run_calculations() -> void:
	_sim_cycles += 1
	if debug:
		print("=========== SIM CYCLE %d ===========" % [_sim_cycles])
	
	_cached_max_pressure = -INF
	_cached_min_pressure =  INF
	_cached_max_flow = -INF
	_cached_min_flow =  INF
	for pipe in _all_pipes:
		if pipe.is_flow_source:
			_bake_pipe(pipe)
	
	# bake any orphaned pipes that still need to rebaked
	for pipe in _all_pipes:
		if pipe.is_rebake_needed():
			_bake_pipe(pipe)
	
	if debug:
		print("system pressure min/max: %f/%f (psi)" %
			[Utils.psft_to_psi(_cached_min_pressure), Utils.psft_to_psi(_cached_max_pressure)])
		print("system flow min/max: %f/%f (gpm)" %
			[Utils.cftps_to_gpm(_cached_min_flow), Utils.cftps_to_gpm(_cached_max_flow)])

func get_sim_cycles() -> int:
	return _sim_cycles

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
	queue_recalc()

func remove_pipe(pipe: Pipe) -> void:
	var idx := _all_pipes.find(pipe)
	if idx >= 0:
		pipe.needs_rebake.disconnect(_on_pipe_needs_rebake)
		pipe._sim = null
		_all_pipes.remove_at(idx)
		queue_recalc()

func get_system_min_pressure() -> float:
	return _cached_min_pressure

func get_system_max_pressure() -> float:
	return _cached_max_pressure

func get_system_min_flow() -> float:
	return _cached_min_flow

func get_system_max_flow() -> float:
	return _cached_max_flow

func queue_recalc() -> void:
	set_process(true)

func _bake_pipe(pipe: Pipe) -> void:
	if debug:
		print("baking %s ..." % pipe.user_label)
	pipe.rebake()
	if debug:
		print("pressure min/max: %f/%f (psi)" %
			[Utils.psft_to_psi(pipe.get_min_pressure()), Utils.psft_to_psi(pipe.get_max_pressure())])
		print("flow min/max: %f/%f (gpm)" %
			[Utils.cftps_to_gpm(pipe.get_min_flow()), Utils.cftps_to_gpm(pipe.get_max_flow())])
	_cached_min_pressure = min(_cached_min_pressure, pipe.get_min_pressure())
	_cached_max_pressure = max(_cached_max_pressure, pipe.get_max_pressure())
	_cached_min_flow = min(_cached_min_flow, pipe.get_min_flow())
	_cached_max_flow = max(_cached_max_flow, pipe.get_max_flow())
	for feed_pipe in pipe.get_feed_pipes_by_progress():
		_bake_pipe(feed_pipe)

func _on_pipe_needs_rebake() -> void:
	queue_recalc()
