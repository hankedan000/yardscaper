extends Object
class_name LayoutPreferences

const PROP_KEY_SHOW_GRID = &"show_grid"
const PROP_KEY_SHOW_ORIGIN = &"show_origin"
const PROP_KEY_CAMERA_POS = &"camera_pos"
const PROP_KEY_ZOOM = &"zoom"

var show_grid = true
var show_origin = true
var camera_pos = Vector2()
var zoom = 1.0

func serialize():
	return {
		PROP_KEY_SHOW_GRID : show_grid,
		PROP_KEY_SHOW_ORIGIN : show_origin,
		PROP_KEY_CAMERA_POS : Utils.vect2_to_pair(camera_pos),
		PROP_KEY_ZOOM : zoom
	}

func deserialize(obj):
	show_grid = Utils.dict_get(obj, PROP_KEY_SHOW_GRID, true)
	show_origin = Utils.dict_get(obj, PROP_KEY_SHOW_ORIGIN, true)
	camera_pos = Utils.pair_to_vect2(Utils.dict_get(obj, PROP_KEY_CAMERA_POS, [0,0]))
	zoom = Utils.dict_get(obj, PROP_KEY_ZOOM, 1.0)
