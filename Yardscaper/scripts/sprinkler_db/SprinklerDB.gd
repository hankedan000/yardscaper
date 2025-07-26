class_name SprinklerDB extends Node

var _manus_by_name : Dictionary = {}

func load_data() -> void:
	load_builtin_data()

func load_builtin_data() -> void:
	load_manufacturer_from_dict(GenericSprinklerData.RAW_DATA)
	load_manufacturer_from_dict(RainBirdSprinklerData.RAW_DATA)

func load_manufacturer_from_dict(data: Dictionary) -> void:
	var manu_name := DictUtils.get_w_default(data, &"name", null) as String
	if manu_name == null:
		push_error("manufacturer data must contain a name")
		return
	
	var manu_data := SprinklerManufacturerData.from_dict(manu_name, data)
	_manus_by_name[manu_name] = manu_data

func get_manufacturer_names() -> Array:
	return _manus_by_name.keys()

func get_manufacturer(manu_name: String) -> SprinklerManufacturerData:
	if manu_name in _manus_by_name:
		return _manus_by_name[manu_name]
	return null
