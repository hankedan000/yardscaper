class_name PipeTables
extends Object

enum FittingType {
	NONE,
	CUSTOM,
	COUPLING,
	ELBOW_90,
	ELBOW_45,
	TEE_RUN,
	TEE_BRANCH_OUT,
	TEE_BRANCH_IN
}

enum MaterialType {
	CUSTOM,
	PVC
}

const MINOR_LOSSES_LUT = [
	# PVC minor losses
	{
		&'material' : MaterialType.PVC,
		&'loss_by_fitting' : {
			FittingType.COUPLING: 0.06,
			FittingType.ELBOW_90: 0.5,
			FittingType.ELBOW_45: 0.2,
			FittingType.TEE_RUN: 0.5,
			FittingType.TEE_BRANCH_OUT: 0.8,
			FittingType.TEE_BRANCH_IN: 1.4
		}
	}
]

# surface roughness in feet
const SURFACE_ROUGHNESS_LUT = [
	{
		&'material' : MaterialType.PVC,
		&'roughness' : 0.000005
	}
]

enum LossLookupError {
	# OOR - Out Of Range
	OK, MaterialOOR, FittingOOR
}

class LossLookupResult extends RefCounted:
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

static func lookup_minor_loss(material: MaterialType, fitting: FittingType) -> LossLookupResult:
	if fitting == FittingType.NONE:
		return LossLookupResult.from_ok_value(0.0)
	
	for mat_entry in MINOR_LOSSES_LUT:
		if mat_entry[&'material'] == material:
			return _lookup_minor_loss_in_mat_table(mat_entry, fitting)
	return LossLookupResult.from_error(LossLookupError.MaterialOOR)

static func _lookup_minor_loss_in_mat_table(mat_entry: Dictionary, fitting: FittingType) -> LossLookupResult:
	var fitting_lut := mat_entry[&'loss_by_fitting'] as Dictionary
	if fitting in fitting_lut:
		return LossLookupResult.from_ok_value(fitting_lut[fitting])
	return LossLookupResult.from_error(LossLookupError.FittingOOR)

# @return -1.0 on error, else the roughness value in feet
static func lookup_surface_roughness(material: MaterialType) -> float:
	for entry in SURFACE_ROUGHNESS_LUT:
		if entry[&'material'] == material:
			return entry[&'roughness']
	push_error("failed to find roughness for material %s. returning 0.0" % material)
	return 0.0
