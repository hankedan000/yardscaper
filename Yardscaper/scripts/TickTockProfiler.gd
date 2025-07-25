class_name TickTockProfiler extends RefCounted

var name := ""
var num_msmts := 0
var min_usec := 9223372036854775807
var max_usec := 0
var total_usec := 0

var _prev_start_usec = null

func _init(new_name: String):
	name = new_name

func reset() -> void:
	num_msmts = 0
	min_usec = 9223372036854775807
	max_usec = 0
	total_usec = 0

func tick() -> void:
	_prev_start_usec = Time.get_ticks_usec()

func tock() -> void:
	if _prev_start_usec == null:
		return
	
	var delta_usec := (Time.get_ticks_usec() - _prev_start_usec) as int
	num_msmts += 1
	min_usec = min(delta_usec, min_usec)
	max_usec = max(delta_usec, max_usec)
	total_usec += delta_usec

func avg_usec() -> float:
	if num_msmts == 0:
		return 0.0
	return float(total_usec) / num_msmts

func _to_string() -> String:
	var sout := ""
	sout += "------ %s ------\n" % name
	sout += "num_msmts:  %9d\n" % num_msmts
	sout += "min_usec:   %9d\n" % min_usec
	sout += "max_usec:   %9d\n" % max_usec
	sout += "total_usec: %9d\n" % total_usec
	sout += "avg_usec:   %13.3f" % avg_usec()
	return sout
