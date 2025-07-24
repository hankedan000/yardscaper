class_name SprinklerBodyData extends RefCounted

var name : String = ""

static func from_dict(body_name: String, _data: Dictionary) -> SprinklerBodyData:
	var out := SprinklerBodyData.new()
	out.name = body_name
	return out
