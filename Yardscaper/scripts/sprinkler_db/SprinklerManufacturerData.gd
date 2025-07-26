class_name SprinklerManufacturerData extends RefCounted

var name : String = ""
var _bodies_by_name : Dictionary = {}
var _heads_by_name : Dictionary = {}

static func from_dict(manu_name: String, data: Dictionary) -> SprinklerManufacturerData:
	var out := SprinklerManufacturerData.new()
	out.name = manu_name
	
	var body_datas := DictUtils.get_w_default(data, &'bodies', {}) as Dictionary
	for body_name in body_datas.keys():
		var body_data := body_datas[body_name] as Dictionary
		out._bodies_by_name[body_name] = SprinklerBodyData.from_dict(body_name, body_data)
	
	var head_datas := DictUtils.get_w_default(data, &'heads', {}) as Dictionary
	for head_model in head_datas.keys():
		var head_data := head_datas[head_model] as Dictionary
		out._heads_by_name[head_model] = SprinklerHeadData.from_dict(head_model, head_data)
	return out

func get_head_count() -> int:
	return _heads_by_name.size()

func get_head_models() -> Array:
	return _heads_by_name.keys()

func get_head(head_model: String) -> SprinklerHeadData:
	if head_model in _heads_by_name:
		return _heads_by_name[head_model]
	return null

func get_body_count() -> int:
	return _bodies_by_name.size()

func get_body_names() -> Array:
	return _bodies_by_name.keys()

func get_body(body_name: String) -> SprinklerBodyData:
	if body_name in _bodies_by_name:
		return _bodies_by_name[body_name]
	return null
