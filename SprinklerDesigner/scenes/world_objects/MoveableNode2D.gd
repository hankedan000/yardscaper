extends WorldObject
class_name MoveableNode2D

signal moved(sprink, from_xy, to_xy)

var show_indicator := false :
	set(value):
		show_indicator = value
		queue_redraw()

var _pos_at_move_start = null

func get_subclass() -> String:
	return "MoveableNode2D"

func has_point(_pos: Vector2):
	push_error("subclass for '%s' should override has_point()" % [name])

func moving() -> bool:
	return _pos_at_move_start != null

func start_move():
	if moving():
		push_warning("move was already started. starting another one.")
	_pos_at_move_start = position

func update_move(delta):
	if ! moving():
		push_warning("can't update_move() when not moving")
		return
	position = _pos_at_move_start + delta

func finish_move(cancel=false):
	if not moving():
		push_warning("move was never started")
		return
	
	if cancel:
		position = _pos_at_move_start
	else:
		emit_signal("moved", self, _pos_at_move_start, position)
	_pos_at_move_start = null
