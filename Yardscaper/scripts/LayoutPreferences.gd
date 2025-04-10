extends Object
class_name LayoutPreferences

const PROP_KEY_SHOW_GRID = &"show_grid"
const PROP_KEY_SHOW_ORIGIN = &"show_origin"
const PROP_KEY_SHOW_IMAGES = &"show_images"
const PROP_KEY_SHOW_MEASUREMENTS = &"show_measurements"
const PROP_KEY_SHOW_POLYGONS = &"show_polygons"
const PROP_KEY_SHOW_SPRINKLERS = &"show_sprinklers"
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
var camera_pos := Vector2()
var zoom = 1.0
var grid_major_spacing_ft := Vector2(5, 5)

func serialize():
	return {
		PROP_KEY_SHOW_GRID : show_grid,
		PROP_KEY_SHOW_ORIGIN : show_origin,
		PROP_KEY_SHOW_IMAGES : show_images,
		PROP_KEY_SHOW_MEASUREMENTS : show_measurements,
		PROP_KEY_SHOW_POLYGONS : show_polygons,
		PROP_KEY_SHOW_SPRINKLERS : show_sprinklers,
		PROP_KEY_CAMERA_POS : Utils.vect2_to_pair(camera_pos),
		PROP_KEY_ZOOM : zoom,
		PROP_KEY_GRID_MAJOR_SPACING : Utils.vect2_to_pair(grid_major_spacing_ft)
	}

func deserialize(obj):
	show_grid = Utils.dict_get(obj, PROP_KEY_SHOW_GRID, true)
	show_origin = Utils.dict_get(obj, PROP_KEY_SHOW_ORIGIN, true)
	show_images = Utils.dict_get(obj, PROP_KEY_SHOW_IMAGES, true)
	show_measurements = Utils.dict_get(obj, PROP_KEY_SHOW_MEASUREMENTS, true)
	show_polygons = Utils.dict_get(obj, PROP_KEY_SHOW_POLYGONS, true)
	show_sprinklers = Utils.dict_get(obj, PROP_KEY_SHOW_SPRINKLERS, true)
	camera_pos = Utils.pair_to_vect2(Utils.dict_get(obj, PROP_KEY_CAMERA_POS, [0,0]))
	zoom = Utils.dict_get(obj, PROP_KEY_ZOOM, 1.0)
	grid_major_spacing_ft = Utils.pair_to_vect2(Utils.dict_get(obj, PROP_KEY_GRID_MAJOR_SPACING, [5,5]))
