extends Object
class_name LayoutPreferences

var show_grid = true
var camera_pos = Vector2()
var zoom = 1.0

func serialize():
	return {
		'show_grid' : show_grid,
		'camera_pos' : Utils.vect2_to_pair(camera_pos),
		'zoom' : zoom
	}

func deserialize(obj):
	show_grid = Utils.dict_get(obj, 'show_grid', true)
	camera_pos = Utils.pair_to_vect2(Utils.dict_get(obj, 'camera_pos', [0,0]))
	zoom = Utils.dict_get(obj, 'zoom', 1.0)
