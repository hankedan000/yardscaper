extends GutTest

func test_PVC_lookup_minor_loss():
	var MAT = PipeTables.MaterialType.PVC
	
	# test 90 elbow
	var res := PipeTables.lookup_minor_loss(MAT, PipeTables.FittingType.ELBOW_90)
	assert_eq(res.error, PipeTables.LossLookupError.OK)
	assert_almost_eq(res.loss_factor, 0.5, 0.001)
	
	# test 45 elbow
	res = PipeTables.lookup_minor_loss(MAT, PipeTables.FittingType.ELBOW_45)
	assert_eq(res.error, PipeTables.LossLookupError.OK)
	assert_almost_eq(res.loss_factor, 0.2, 0.001)
	
	# custom shouldn't exist
	res = PipeTables.lookup_minor_loss(MAT, PipeTables.FittingType.CUSTOM)
	assert_eq(res.error, PipeTables.LossLookupError.FittingOOR)
