class_name PipeTables
extends Object

enum FittingType {
	Custom,
	ELBOW_90,
	ELBOW_45,
	TEE_RUN,
	TEE_BRANCH
}

enum MaterialType {
	Custom,
	PVC
}

const MINOR_LOSSES_LUT = [
	# PVC minor losses
	{
		'material' : MaterialType.PVC,
		'loss_by_fitting' : [
			{
				'fitting' : FittingType.ELBOW_90,
				'loss_by_diam' : [
					[0.5,1.6], [0.75,2.1], [1.0,2.6], [1.25,3.5], [1.5,4.0], [2.0,5.2], [2.5,6.2], [3.0,7.7], [4.0,10.1], [5.0,12.6], [6.0,15.2], [8.0,20.0], [10.0,25.1], [12.0,30.0]
				]
			},
			{
				'fitting' : FittingType.ELBOW_45,
				'loss_by_diam' : [
					[0.5,0.8], [0.75,1.1], [1.0,1.4], [1.25,1.8], [1.5,2.2], [2.0,2.8], [2.5,3.3], [3.0,4.1], [4.0,5.1], [5.0,6.7], [6.0,8.1], [8.0,10.6], [10.0,13.4], [12.0,15.9]
				]
			},
			{
				'fitting' : FittingType.TEE_RUN,
				'loss_by_diam' : [
					[0.5,1.0], [0.75,1.4], [1.0,1.7], [1.25,2.3], [1.5,2.7], [2.0,3.5], [2.5,4.1], [3.0,5.1], [4.0,6.7], [5.0,8.4], [6.0,10.1], [8.0,13.3], [10.0,16.7], [12.0,20.0]
				]
			},
			{
				'fitting' : FittingType.TEE_BRANCH,
				'loss_by_diam' : [
					[0.5,3.1], [0.75,4.1], [1.0,5.3], [1.25,6.9], [1.5,8.1], [2.0,10.3], [2.5,12.3], [3.0,16.3], [4.0,20.1], [5.0,25.2], [6.0,30.3], [8.0,40.0], [10.0,50.1], [12.0,58.0]
				]
			}
		]
	}
]

# surface roughness in feet
const SURFACE_ROUGHNESS_LUT = [
	{
		'material' : MaterialType.PVC,
		'roughness' : 0.000005
	}
]

enum LossLookupError {
	# OOR - Out Of Range
	OK, MaterialOOR, FittingOOR, EmptyLossTable, DiameterOOR
}

class LossLookupResult:
	var error : LossLookupError = LossLookupError.OK
	var loss_factor : float = -1.0
	
	static func from_error(err: LossLookupError) -> LossLookupResult:
		var res := LossLookupResult.new()
		res.error = err
		return res
	
	static func from_ok_value(value: float) -> LossLookupResult:
		var res := LossLookupResult.new()
		res.loss_factor = value
		return res
	
	static func from_warn_value(warn: LossLookupError, value: float) -> LossLookupResult:
		var res := LossLookupResult.new()
		res.error = warn
		res.loss_factor = value
		return res

static func lookup_minor_loss(material: MaterialType, fitting: FittingType, diam_h: float) -> LossLookupResult:
	for mat_entry in MINOR_LOSSES_LUT:
		if mat_entry['material'] == material:
			return _lookup_minor_loss_in_mat_table(mat_entry, fitting, diam_h)
	return LossLookupResult.from_error(LossLookupError.MaterialOOR)

static func _lookup_minor_loss_in_mat_table(mat_entry: Dictionary, fitting: FittingType, diam_h: float) -> LossLookupResult:
	for fitting_entry in mat_entry['loss_by_fitting']:
		if fitting_entry['fitting'] == fitting:
			return _lookup_minor_loss_in_fitting_table(fitting_entry, diam_h)
	return LossLookupResult.from_error(LossLookupError.FittingOOR)

static func _lookup_minor_loss_in_fitting_table(fitting_entry: Dictionary, diam_h: float) -> LossLookupResult:
	var loss_lut := fitting_entry['loss_by_diam'] as Array
	var search_col := 0 # diam_h
	var return_col := 1 # loss
	var res := LUT_Utils.lerp_lookup(loss_lut, diam_h, search_col, return_col)
	
	match res.error:
		LUT_Utils.LerpError.Empty:
			return LossLookupResult.from_error(LossLookupError.EmptyLossTable)
		LUT_Utils.LerpError.OutOfRange:
			return LossLookupResult.from_warn_value(LossLookupError.DiameterOOR, res.value)
	return LossLookupResult.from_ok_value(res.value)

# @return -1.0 on error, else the roughness value in feet
static func lookup_surface_roughness(material: MaterialType) -> float:
	for entry in SURFACE_ROUGHNESS_LUT:
		if entry['material'] == material:
			return entry['roughness']
	push_error("failed to find roughness for material %s. returning 0.0" % material)
	return 0.0
