class_name SprinklerFlowModel extends RefCounted

const DEFAULT_NOZZLE_DIAMETER_FT := 0.0625 / 12.0 # 1/16 in
const DEFAULT_NOZZLE_LENGTH_FT   := 0.0625 / 12.0 # 1/16 in

enum ModelType {
	Unknown, Fan, Rotary
}

var model_type : ModelType = ModelType.Unknown

func get_K_s(_sprink: Sprinkler) -> LUT_Utils.LerpResult:
	var res := LUT_Utils.LerpResult.new()
	res.error = LUT_Utils.LerpError.Empty
	res.value = 0.0
	return res

func get_nozzle_options() -> Array[String]:
	return []

static func instance_model(type: ModelType, flow_table: Array) -> SprinklerFlowModel:
	match type:
		ModelType.Fan:
			return Fan.from_flow_table(flow_table)
		ModelType.Rotary:
			return Rotary.from_flow_table(flow_table)
	push_warning("unsupported model type %s" % type)
	return SprinklerFlowModel.new()

class Fan extends SprinklerFlowModel:
	# K-factor lookup table where K = flow_cfs / sqrt(pressure_psi)
	var _K_lut : Array = [] # [[sweep_deg1, K1], [sweep_deg2, K2], ...]
	
	const DATA_IDX_PRESSURE   := 0
	const DATA_IDX_DIST       := 1
	const DATA_IDX_FLOW       := 2
	const DATA_IDX_IS_OPTIMAL := 3
	
	const K_LUT_IDX_SWEEP := 0
	const K_LUT_IDX_K     := 1
	
	static func from_flow_table(flow_table: Array) -> Fan:
		var out := Fan.new()
		
		# populate _K_lut: computing K_s at each sweep angle
		for flow_entry in flow_table:
			var sweep_deg := flow_entry[&'sweep_deg'] as float
			var K_avg := 0.0 # average minor loss across all data entries
			var flow_data := flow_entry[&'data'] as Array
			for data_entry: Array in flow_data:
				var h_psi := data_entry[DATA_IDX_PRESSURE] as float
				var q_cfs := Utils.gpm_to_cftps(data_entry[DATA_IDX_FLOW] as float)
				var K := q_cfs / sqrt(h_psi)
				K_avg += K
			if flow_data.size() > 0:
				K_avg /= flow_data.size()
			out._K_lut.push_back([sweep_deg, K_avg])
		
		# sort LUT so it's ascending by sweep angle
		out._K_lut.sort_custom(LUT_Utils._sort_tuple_by_idx.bind(K_LUT_IDX_SWEEP))
		
		return out

	func get_K_s_at_sweep(sweep_deg: float) -> LUT_Utils.LerpResult:
		return LUT_Utils.lerp_lookup(_K_lut, sweep_deg, K_LUT_IDX_SWEEP, K_LUT_IDX_K)

	func get_K_s(sprink: Sprinkler) -> LUT_Utils.LerpResult:
		return get_K_s_at_sweep(sprink.sweep_deg)

class Rotary extends SprinklerFlowModel:
	# K-factor lookup table where K = flow_cfs / sqrt(pressure_psi)
	var _K_lut : Dictionary = {} # key: nozzle_option, value: K_s
	
	const DATA_IDX_PRESSURE   := 0
	const DATA_IDX_DIST       := 1
	const DATA_IDX_FLOW       := 2
	const DATA_IDX_IS_OPTIMAL := 3
	
	static func from_flow_table(flow_table: Array) -> Rotary:
		var out := Rotary.new()
		
		# populate _K_lut: computing K_s for each nozzle
		for flow_entry in flow_table:
			var nozzle_option := flow_entry[&'nozzle'] as String
			var K_avg := 0.0 # average minor loss across all data entries
			var flow_data := flow_entry[&'data'] as Array
			for data_entry: Array in flow_data:
				var h_psi := data_entry[DATA_IDX_PRESSURE] as float
				var q_cfs := Utils.gpm_to_cftps(data_entry[DATA_IDX_FLOW] as float)
				var K := q_cfs / sqrt(h_psi)
				K_avg += K
			if flow_data.size() > 0:
				K_avg /= flow_data.size()
			out._K_lut[nozzle_option] = K_avg
		
		return out

	func get_K_s_with_nozzle(nozzle_option: String) -> LUT_Utils.LerpResult:
		var res := LUT_Utils.LerpResult.new()
		res.error = LUT_Utils.LerpError.OutOfRange
		res.value = 0.0
		if _K_lut.is_empty():
			res.error = LUT_Utils.LerpError.Empty
		elif nozzle_option in _K_lut:
			res.error = LUT_Utils.LerpError.OK
			res.value = _K_lut[nozzle_option]
		return res

	func get_K_s(sprink: Sprinkler) -> LUT_Utils.LerpResult:
		return get_K_s_with_nozzle(sprink.nozzle_option)

	func get_nozzle_options() -> Array[String]:
		var out_options : Array[String] = []
		for nozzle_option in _K_lut.keys():
			if nozzle_option is String:
				out_options.push_back(nozzle_option)
		return out_options
