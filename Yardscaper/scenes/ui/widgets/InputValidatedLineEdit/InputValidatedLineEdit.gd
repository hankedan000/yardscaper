class_name InputValidatedLineEdit extends LineEdit

signal valid_text_submitted(new_text: String)

const ERROR_BORDER_WIDTH := 2
const ERROR_CORNER_RADIUS := 3
const ERROR_EXPAND_MARGIN := 2
const ERROR_CONTENT_MARGIN := 4

@export var submit_on_focus_exit : bool = true
@export var release_focus_on_submit : bool = true

@onready var _error_label  : Label = $CanvasLayer/Panel/Label
@onready var _error_panel  : Panel = $CanvasLayer/Panel
@onready var _error_canvas : CanvasLayer = $CanvasLayer

# user-definable callback that determines if the input is valid. the function
# should take a single string argument that contains the new text to validate.
# the return value should be a string where and empty string means the text is
# valid; otherwise, the the returned string will be used a rationale that gets
# displayed to the user via a _error_canvas textbox.
var _validator : Callable = _default_validator
var _has_error : bool = false
var _error_style_normal := StyleBoxFlat.new()
var _error_style_focus := StyleBoxFlat.new()

func _ready() -> void:
	text_changed.connect(_on_text_changed)
	text_submitted.connect(_on_text_submitted)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	_error_style_normal.bg_color = Color("#500000")
	_error_style_normal.border_color = Color(0.75, 0, 0)
	_error_style_normal.border_width_bottom = ERROR_BORDER_WIDTH
	_error_style_normal.border_width_top    = ERROR_BORDER_WIDTH
	_error_style_normal.border_width_left   = ERROR_BORDER_WIDTH
	_error_style_normal.border_width_right  = ERROR_BORDER_WIDTH
	_error_style_normal.corner_radius_bottom_left  = ERROR_CORNER_RADIUS
	_error_style_normal.corner_radius_bottom_right = ERROR_CORNER_RADIUS
	_error_style_normal.corner_radius_top_left     = ERROR_CORNER_RADIUS
	_error_style_normal.corner_radius_top_right    = ERROR_CORNER_RADIUS
	_error_style_normal.content_margin_bottom = ERROR_CONTENT_MARGIN
	_error_style_normal.content_margin_top    = ERROR_CONTENT_MARGIN
	_error_style_normal.content_margin_left   = ERROR_CONTENT_MARGIN
	_error_style_normal.content_margin_right  = ERROR_CONTENT_MARGIN
	_error_style_normal.expand_margin_top   = ERROR_EXPAND_MARGIN
	_error_style_normal.expand_margin_left  = ERROR_EXPAND_MARGIN
	_error_style_normal.expand_margin_left  = ERROR_EXPAND_MARGIN
	_error_style_normal.expand_margin_right = ERROR_EXPAND_MARGIN
	_error_style_focus.bg_color = Color("#500000")
	_error_style_focus.border_color = Color(1, 0, 0)
	_error_style_focus.border_width_bottom = ERROR_BORDER_WIDTH
	_error_style_focus.border_width_top    = ERROR_BORDER_WIDTH
	_error_style_focus.border_width_left   = ERROR_BORDER_WIDTH
	_error_style_focus.border_width_right  = ERROR_BORDER_WIDTH
	_error_style_focus.corner_radius_bottom_left  = ERROR_CORNER_RADIUS
	_error_style_focus.corner_radius_bottom_right = ERROR_CORNER_RADIUS
	_error_style_focus.corner_radius_top_left     = ERROR_CORNER_RADIUS
	_error_style_focus.corner_radius_top_right    = ERROR_CORNER_RADIUS
	_error_style_focus.content_margin_bottom = ERROR_CONTENT_MARGIN
	_error_style_focus.content_margin_top    = ERROR_CONTENT_MARGIN
	_error_style_focus.content_margin_left   = ERROR_CONTENT_MARGIN
	_error_style_focus.content_margin_right  = ERROR_CONTENT_MARGIN
	_error_style_focus.expand_margin_top   = ERROR_EXPAND_MARGIN
	_error_style_focus.expand_margin_left  = ERROR_EXPAND_MARGIN
	_error_style_focus.expand_margin_left  = ERROR_EXPAND_MARGIN
	_error_style_focus.expand_margin_right = ERROR_EXPAND_MARGIN

func set_validator(new_validator: Callable) -> void:
	var unbound_arg_count := new_validator.get_argument_count() - new_validator.get_bound_arguments_count()
	if unbound_arg_count != 1:
		push_error("validator must take at least 1 unbound argument that's a String")
		return
	_validator = new_validator

func has_error() -> bool:
	return _has_error

func clear_w_error() -> void:
	clear()
	_clear_error()

static func _default_validator(_new_text: String) -> String:
	return "" # every input is valid by default

func _mark_error(message: String) -> void:
	_has_error = true
	add_theme_stylebox_override("normal", _error_style_normal)
	add_theme_stylebox_override("focus", _error_style_focus)
	_error_label.text = message
	_error_panel.size = Utils.get_label_text_size(_error_label, message)
	_show_error_popup()

func _clear_error() -> void:
	_has_error = false
	remove_theme_stylebox_override("normal")
	remove_theme_stylebox_override("focus")
	_error_canvas.hide()

func _show_error_popup() -> void:
	_error_panel.global_position = global_position + Vector2(0, size.y + 4)
	_error_canvas.show()

func _on_text_changed(new_text: String) -> void:
	var error_msg := _validator.call(new_text) as String
	if error_msg != "":
		_mark_error(error_msg)
	else:
		_clear_error()

func _on_text_submitted(new_text: String) -> void:
	if release_focus_on_submit:
		release_focus()
	if ! _has_error:
		valid_text_submitted.emit(new_text)

func _on_focus_entered() -> void:
	if _has_error:
		_show_error_popup()

func _on_focus_exited() -> void:
	if _has_error:
		_error_canvas.hide()
	if submit_on_focus_exit:
		text_submitted.emit(text)
