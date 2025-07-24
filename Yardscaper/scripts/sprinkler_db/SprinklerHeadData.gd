class_name SprinklerHeadData extends RefCounted

var name : String = ""
var min_dist_ft : float = 0.0
var max_dist_ft : float = 0.0
var min_sweep_deg : float = 0.0
var max_sweep_deg : float = 0.0
var compatible_bodies : Array = [] # of names
var flow_model : SprinklerFlowModel = null

static func from_dict(head_name: String, data: Dictionary) -> SprinklerHeadData:
	var out := SprinklerHeadData.new()
	out.name = head_name
	out.min_dist_ft = DictUtils.get_w_default(data, &'min_dist_ft', 0.0)
	out.max_dist_ft = DictUtils.get_w_default(data, &'max_dist_ft', 0.0)
	out.min_sweep_deg = DictUtils.get_w_default(data, &'min_sweep_deg', 0.0)
	out.max_sweep_deg = DictUtils.get_w_default(data, &'max_sweep_deg', 0.0)
	out.compatible_bodies = DictUtils.get_w_default(data, &'compatible_bodies', [])
	var flow_model_str := DictUtils.get_w_default(data, &'flow_model', "Unknown") as String
	var flow_model_type := EnumUtils.from_str(SprinklerFlowModel.ModelType, SprinklerFlowModel.ModelType.Unknown, flow_model_str) as SprinklerFlowModel.ModelType
	var flow_table := DictUtils.get_w_default(data, &'flow_characteristics', []) as Array
	out.flow_model = SprinklerFlowModel.instance_model(flow_model_type, flow_table)
	return out
