extends Node
class_name InputRecorder

enum EventType {Invalid = 0, None = 1, MouseButton = 2, MouseMotion = 3}

class RecordedEvent:
	var ticks_msec : int = 0
	var evt_type : EventType = EventType.None
	
	func _init(type: EventType) -> void:
		ticks_msec = Time.get_ticks_msec()
		evt_type = type
	
	func to_csv() -> String:
		return "%d,%d" % [ticks_msec,int(evt_type)]
	
	func to_input_event() -> InputEvent:
		return null
	
	func _to_string() -> String:
		return to_csv()

	static func evt_type_from_int(i: int) -> EventType:
		match i:
			0:
				return EventType.Invalid
			1:
				return EventType.None
			2:
				return EventType.MouseButton
			3:
				return EventType.MouseMotion
		push_error("event type %d invalid!" % i)
		return EventType.Invalid

class RecordedMouseButtonEvent extends RecordedEvent:
	var button_index : int = 0
	var button_mask : int = 0
	var pressed : bool = false
	var position : Vector2 = Vector2()
	
	func _init() -> void:
		super._init(EventType.MouseButton)
	
	static func from_input_event(evt: InputEventMouseButton) -> RecordedMouseButtonEvent:
		var rec_evt := RecordedMouseButtonEvent.new()
		rec_evt.button_index = evt.button_index
		rec_evt.button_mask = evt.button_mask
		rec_evt.pressed = evt.pressed
		rec_evt.position = evt.position
		return rec_evt
	
	static func from_csv_parts(parts: Array[String]) -> RecordedMouseButtonEvent:
		var rec_evt := RecordedMouseButtonEvent.new()
		rec_evt.ticks_msec = int(parts[0])
		rec_evt.evt_type = evt_type_from_int(int(parts[1]))
		rec_evt.button_index = int(parts[2])
		rec_evt.button_mask = int(parts[3])
		rec_evt.pressed = int(parts[4]) != 0
		rec_evt.position.x = int(parts[5])
		rec_evt.position.y = int(parts[6])
		return rec_evt
	
	func to_csv() -> String:
		var csv := super.to_csv()
		csv += ",%d,%d,%d,%d,%d" % [button_index, button_mask, int(pressed), int(position.x), int(position.y)]
		return csv
	
	static func button_index_to_mouse_button(i: int) -> MouseButton:
		match i:
			MOUSE_BUTTON_LEFT:
				return MOUSE_BUTTON_LEFT
			MOUSE_BUTTON_MIDDLE:
				return MOUSE_BUTTON_MIDDLE
			MOUSE_BUTTON_RIGHT:
				return MOUSE_BUTTON_RIGHT
		assert("invalid mouse button_index %d" % i)
		return MOUSE_BUTTON_NONE
	
	func to_input_event() -> InputEvent:
		var in_evt := InputEventMouseButton.new()
		in_evt.button_index = button_index_to_mouse_button(button_index)
		in_evt.button_mask = button_mask
		in_evt.pressed = pressed
		in_evt.position = position
		return in_evt

class RecordedMouseMotionEvent extends RecordedEvent:
	var position : Vector2 = Vector2()
	
	func _init() -> void:
		super._init(EventType.MouseMotion)
	
	static func from_input_event(evt: InputEventMouseMotion) -> RecordedMouseMotionEvent:
		var rec_evt := RecordedMouseMotionEvent.new()
		rec_evt.position = evt.position
		return rec_evt
	
	static func from_csv_parts(parts: Array[String]) -> RecordedMouseMotionEvent:
		var rec_evt := RecordedMouseMotionEvent.new()
		rec_evt.ticks_msec = int(parts[0])
		rec_evt.evt_type = evt_type_from_int(int(parts[1]))
		rec_evt.position.x = int(parts[2])
		rec_evt.position.y = int(parts[3])
		return rec_evt
	
	func to_csv() -> String:
		var csv := super.to_csv()
		csv += ",%d,%d" % [int(position.x), int(position.y)]
		return csv
	
	func to_input_event() -> InputEvent:
		var in_evt := InputEventMouseMotion.new()
		in_evt.position = position
		return in_evt

var _log_file : FileAccess = null
var _thread : Thread = Thread.new()
var _mutex : Mutex = Mutex.new() # guards _evt_queue
var _stay_alive : bool = true
var _evt_queue : Array[RecordedEvent] = []

func _ready() -> void:
	set_process_input(false)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_queue_evt(RecordedMouseButtonEvent.from_input_event(event))
	elif event is InputEventMouseMotion:
		_queue_evt(RecordedMouseMotionEvent.from_input_event(event))

func is_recording() -> bool:
	return _thread.is_alive()

# @returns true if recording was started, false on failure or if recording
# was already started previously.
func start_recording(filepath: String) -> bool:
	if is_recording():
		push_warning("ignoring duplicate start")
		return false
	
	_log_file = FileAccess.open(filepath, FileAccess.WRITE)
	if _log_file == null:
		push_error("failed to open '%s'" % filepath)
		return false
	
	_stay_alive = true
	_thread.start(__THREADED__write_events)
	set_process_input(true)
	return true

func stop_recording() -> bool:
	if ! is_recording():
		return false
	_stay_alive = false
	_thread.wait_to_finish()
	return true

func __THREADED__write_events() -> void:
	while _stay_alive:
		_mutex.lock()
		var evt : RecordedEvent = _evt_queue.pop_front()
		_mutex.unlock()
		if evt:
			_log_file.store_line(evt.to_csv())
	_log_file.close()
	_log_file = null

func _queue_evt(evt: RecordedEvent) -> void:
	_mutex.lock()
	_evt_queue.push_back(evt)
	_mutex.unlock()
