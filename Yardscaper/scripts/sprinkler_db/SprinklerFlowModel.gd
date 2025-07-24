class_name SprinklerFlowModel extends RefCounted

const DEFAULT_NOZZLE_DIAMETER_FT := 0.0625 / 12.0 # 1/16 in
const DEFAULT_NOZZLE_LENGTH_FT   := 0.0625 / 12.0 # 1/16 in

enum ModelType {
	Unknown, Fan, Rotary
}

var model_type : ModelType = ModelType.Unknown

func get_minor_loss(_sprink: Sprinkler) -> LUT_Utils.LerpResult:
	var res := LUT_Utils.LerpResult.new()
	res.error = LUT_Utils.LerpError.Empty
	res.value = 0.0
	return res

static func instance_model(type: ModelType, flow_table: Array) -> SprinklerFlowModel:
	match type:
		ModelType.Fan:
			return Fan.from_flow_table(flow_table)
	push_warning("unsupported model type %s" % type)
	return SprinklerFlowModel.new()

class Fan extends SprinklerFlowModel:
	# minor loss lookup table
	var _K_lut : Array = [] # [[sweep_deg1, K1], [sweep_deg2, K2], ...]
	var _orig_flow_table : Array = []
	
	const DATA_IDX_PRESSURE   := 0
	const DATA_IDX_DIST       := 1
	const DATA_IDX_FLOW       := 2
	const DATA_IDX_IS_OPTIMAL := 3
	
	const K_LUT_IDX_SWEEP := 0
	const K_LUT_IDX_K     := 1
	
	static func from_flow_table(flow_table: Array) -> Fan:
		var out := Fan.new()
		out._orig_flow_table = flow_table
		
		# populate _K_lut: computing minor loss coeff at each sweep angle
		var radius_ft := DEFAULT_NOZZLE_DIAMETER_FT / 2.0
		var area_ft2 := PI * radius_ft * radius_ft
		for flow_entry in flow_table:
			var sweep_deg := flow_entry[&'sweep_deg'] as float
			var K_avg := 0.0 # average minor loss across all data entries
			var flow_data := flow_entry[&'data'] as Array
			for data_entry: Array in flow_data:
				var h_psi := data_entry[DATA_IDX_PRESSURE] as float
				var q_cfs := Utils.gpm_to_cftps(data_entry[DATA_IDX_FLOW] as float)
				var v_fps := q_cfs / area_ft2
				var K := h_psi * 2.0 / (v_fps * v_fps * FluidMath.WATER_DENSITY)
				K_avg += K
			if flow_data.size() > 0:
				K_avg /= flow_data.size()
			out._K_lut.push_back([sweep_deg, K_avg])
		
		# sort LUT so it's ascending by sweep angle
		out._K_lut.sort_custom(LUT_Utils._sort_tuple_by_idx.bind(K_LUT_IDX_SWEEP))
		
		return out

	func get_minor_loss_at_sweep(sweep_deg: float) -> LUT_Utils.LerpResult:
		return LUT_Utils.lerp_lookup(_K_lut, sweep_deg, K_LUT_IDX_SWEEP, K_LUT_IDX_K)

	func get_minor_loss(sprink: Sprinkler) -> LUT_Utils.LerpResult:
		return get_minor_loss_at_sweep(sprink.sweep_deg)
