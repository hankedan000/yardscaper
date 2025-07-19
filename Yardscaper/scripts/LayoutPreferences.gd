extends Object
class_name LayoutPreferences

const PROP_KEY_SHOW_GRID = &"show_grid"
const PROP_KEY_SHOW_ORIGIN = &"show_origin"
const PROP_KEY_SHOW_IMAGES = &"show_images"
const PROP_KEY_SHOW_MEASUREMENTS = &"show_measurements"
const PROP_KEY_SHOW_POLYGONS = &"show_polygons"
const PROP_KEY_SHOW_SPRINKLERS = &"show_sprinklers"
const PROP_KEY_SHOW_PIPES = &"show_pipes"
const PROP_KEY_SHOW_PIPE_FLOW_DIRECTION = &"show_pipe_flow_direction"
const PROP_KEY_CAMERA_POS = &"camera_pos"
const PROP_KEY_ZOOM = &"zoom"
const PROP_KEY_GRID_MAJOR_SPACING = &"grid_major_spacing_ft"

signal view_show_state_changed(prop_key: StringName, new_value: bool)

var show_grid = true:
	set(value):
		if show_grid == value:
			return
		show_grid = value
		view_show_state_changed.emit(PROP_KEY_SHOW_GRID, value)
var show_origin = true:
	set(value):
		if show_origin == value:
			return
		show_origin = value
		view_show_state_changed.emit(PROP_KEY_SHOW_ORIGIN, value)
var show_images = true:
	set(value):
		if show_images == value:
			return
		show_images = value
		view_show_state_changed.emit(PROP_KEY_SHOW_IMAGES, value)
var show_measurements = true:
	set(value):
		if show_measurements == value:
			return
		show_measurements = value
		view_show_state_changed.emit(PROP_KEY_SHOW_MEASUREMENTS, value)
var show_polygons = true:
	set(value):
		if show_polygons == value:
			return
		show_polygons = value
		view_show_state_changed.emit(PROP_KEY_SHOW_POLYGONS, value)
var show_sprinklers = true:
	set(value):
		if show_sprinklers == value:
			return
		show_sprinklers = value
		view_show_state_changed.emit(PROP_KEY_SHOW_SPRINKLERS, value)
var show_pipes = true:
	set(value):
		if show_pipes == value:
			return
		show_pipes = value
		view_show_state_changed.emit(PROP_KEY_SHOW_PIPES, value)
var show_pipe_flow_direction = false:
	set(value):
		if show_pipe_flow_direction == value:
			return
		show_pipe_flow_direction = value
		view_show_state_changed.emit(PROP_KEY_SHOW_PIPE_FLOW_DIRECTION, value)
var camera_pos := Vector2()
var zoom = 1.0
var grid_major_spacing_ft := Vector2(5, 5)

func serialize() -> Dictionary:
	return {
		PROP_KEY_SHOW_GRID : show_grid,
		PROP_KEY_SHOW_ORIGIN : show_origin,
		PROP_KEY_SHOW_IMAGES : show_images,
		PROP_KEY_SHOW_MEASUREMENTS : show_measurements,
		PROP_KEY_SHOW_POLYGONS : show_polygons,
		PROP_KEY_SHOW_SPRINKLERS : show_sprinklers,
		PROP_KEY_SHOW_PIPES : show_pipes,
		PROP_KEY_SHOW_PIPE_FLOW_DIRECTION : show_pipe_flow_direction,
		PROP_KEY_CAMERA_POS : Utils.vect2_to_pair(camera_pos),
		PROP_KEY_ZOOM : zoom,
		PROP_KEY_GRID_MAJOR_SPACING : Utils.vect2_to_pair(grid_major_spacing_ft)
	}

func deserialize(obj: Dictionary) -> void:
	show_grid = DictUtils.get_w_default(obj, PROP_KEY_SHOW_GRID, true)
	show_origin = DictUtils.get_w_default(obj, PROP_KEY_SHOW_ORIGIN, true)
	show_images = DictUtils.get_w_default(obj, PROP_KEY_SHOW_IMAGES, true)
	show_measurements = DictUtils.get_w_default(obj, PROP_KEY_SHOW_MEASUREMENTS, true)
	show_polygons = DictUtils.get_w_default(obj, PROP_KEY_SHOW_POLYGONS, true)
	show_sprinklers = DictUtils.get_w_default(obj, PROP_KEY_SHOW_SPRINKLERS, true)
	show_pipes = DictUtils.get_w_default(obj, PROP_KEY_SHOW_PIPES, true)
	show_pipe_flow_direction = DictUtils.get_w_default(obj, PROP_KEY_SHOW_PIPE_FLOW_DIRECTION, false)
	camera_pos = Utils.pair_to_vect2(DictUtils.get_w_default(obj, PROP_KEY_CAMERA_POS, [0,0]))
	zoom = DictUtils.get_w_default(obj, PROP_KEY_ZOOM, 1.0)
	grid_major_spacing_ft = Utils.pair_to_vect2(DictUtils.get_w_default(obj, PROP_KEY_GRID_MAJOR_SPACING, [5,5]))
