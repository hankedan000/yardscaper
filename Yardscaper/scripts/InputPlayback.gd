extends Node
class_name InputPlayback

const MIN_EVENT_TO_EVENT_DELAY_MSEC = 0.0

var _evt_queue : Array[InputRecorder.RecordedEvent] = []
var _msec_till_next_event : float = 0.0
var _ticks_msec_at_playback_start : int = 0

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	if _msec_till_next_event > 0.0:
		_msec_till_next_event -= delta * 1000.0
		return
	
	var next_evt := _evt_queue.pop_front() as InputRecorder.RecordedEvent
	var input_evt := next_evt.to_input_event()
	if input_evt:
		if input_evt is InputEventMouse:
			Input.warp_mouse(input_evt.position)
		Input.parse_input_event(input_evt)
	
	if _evt_queue.is_empty():
		set_process(false)
	else:
		_msec_till_next_event = MIN_EVENT_TO_EVENT_DELAY_MSEC

func load_events_from_file(filepath: String) -> int:
	var file := FileAccess.open(filepath, FileAccess.READ)
	if file == null:
		push_error("failed to open '%s'" % filepath)
		return 0
	
	while ! file.eof_reached():
		var line := file.get_line()
		if line.length() == 0:
			break;
		
		var csv_parts = line.split(',')
		var evt_type := InputRecorder.RecordedEvent.evt_type_from_int(int(csv_parts[1]))
		match evt_type:
			InputRecorder.EventType.MouseButton:
				_evt_queue.push_back(InputRecorder.RecordedMouseButtonEvent.from_csv_parts(csv_parts))
			InputRecorder.EventType.MouseMotion:
				_evt_queue.push_back(InputRecorder.RecordedMouseMotionEvent.from_csv_parts(csv_parts))
			_:
				push_warning("unsupported playback of event type %s" % evt_type)
	
	return _evt_queue.size()

func is_playing() -> bool:
	return is_processing()

func start_playback(delay_msec: float) -> bool:
	if is_playing():
		push_warning("ignoring duplicate start")
		return false
	elif _evt_queue.is_empty():
		push_warning("event queue is empty. was anything loaded?")
		return false
	elif delay_msec < 0.0:
		push_error("delay must be >= 0")
		return false
	_msec_till_next_event = delay_msec
	_ticks_msec_at_playback_start = Time.get_ticks_msec()
	set_process(true)
	return true
