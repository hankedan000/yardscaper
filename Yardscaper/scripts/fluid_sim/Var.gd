class_name Var extends RefCounted

enum State {
	Unknown, # value is a guess and/or intermediate value while being solved
	Known,   # value is a known/fixed truth from user
	Solved   # value is know, but after a converged solution was found
}

var name   : String = ""
var value  : float = 0.0
var state  : State = State.Unknown

var _parent_entity : WeakRef = null

func _init(new_entity: FEntity, new_name: String) -> void:
	_parent_entity = weakref(new_entity)
	name = new_name

func reset() -> void:
	value = 0.0
	state = State.Unknown

func reset_if_solved(clear_value: bool = false) -> void:
	if state == State.Solved:
		state = State.Unknown
		if clear_value:
			value = 0.0

func set_known(v: float) -> void:
	value = v
	state = State.Known

func get_parent_entity() -> FEntity:
	return _parent_entity.get_ref()

func get_name_with_entity() -> String:
	return "%s_%s" % [str(get_parent_entity()), name]

func _to_string() -> String:
	return "%s=%f (%s)" % [get_name_with_entity(), value, EnumUtils.to_str(State, state)]

static func test_states_all(arr: Array[State], test_state: State) -> bool:
	for i in arr:
		if i != test_state:
			return false
	return true

static func test_states_any(arr: Array[State], test_state: State) -> bool:
	for i in arr:
		if i == test_state:
			return true
	return false

static func merge_var_states(vars: Array[Var]) -> State:
	var states : Array[State] = []
	for i in vars:
		states.push_back(i.state)
	
	if test_states_all(states, State.Known):
		return State.Known
	elif ! test_states_any(states, State.Unknown) and test_states_any(states, State.Solved):
		return State.Solved
	return State.Unknown
