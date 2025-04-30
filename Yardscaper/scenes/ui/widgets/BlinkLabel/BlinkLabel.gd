@tool
extends Label
class_name BlinkLabel

@export var background_color_normal : Color = Color(0,0,0,0)
@export var background_color_blink : Color = Color.ORANGE
@export var text_color_normal : Color = Color.WHITE
@export var text_color_blink : Color = Color.BLACK
@export var blink_on_show : bool = false
@export var blink_count : int = 2
@export var total_blink_duration : float = 1.0

@onready var timer : Timer = $Timer

var _state_changes_remaining : int = 0
var _normal_style_box : StyleBoxFlat = null
var _prev_visible : bool = false

func _ready() -> void:
	_normal_style_box = get(&"theme_override_styles/normal") as StyleBoxFlat
	set_to_normal_state()

func set_to_blink_state() -> void:
	set(&"theme_override_colors/font_color", text_color_blink)
	_normal_style_box.bg_color = background_color_blink

func set_to_normal_state() -> void:
	set(&"theme_override_colors/font_color", text_color_normal)
	_normal_style_box.bg_color = background_color_normal

func start_blink() -> void:
	if blink_count > 0 && is_inside_tree():
		set_to_normal_state() # in case we're not there already
		_state_changes_remaining = blink_count * 2
		timer.start(total_blink_duration / _state_changes_remaining)

func _on_visibility_changed() -> void:
	if blink_on_show && visible && _prev_visible != visible:
		start_blink()
	_prev_visible = visible

func _on_timer_timeout() -> void:
	_state_changes_remaining -= 1
	if _state_changes_remaining % 2 == 0:
		set_to_normal_state()
	else:
		set_to_blink_state()
	if _state_changes_remaining <= 0:
		timer.stop()
