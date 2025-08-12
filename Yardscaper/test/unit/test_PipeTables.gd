extends GutTest

func test_PVC_lookup_minor_loss():
	var MAT = PipeTables.MaterialType.PVC
	
	# below the lowest entry on the table, so we should get the 1/2" diameter
	var res : PipeTables.LossLookupResult = PipeTables.lookup_minor_loss(MAT, PipeTables.FittingType.ELBOW_90, Utils.inches_to_ft(0.25))
	assert_eq(res.error, PipeTables.LossLookupError.DiameterOOR)
	assert_almost_eq(res.loss_factor, 1.6, 0.001)
	
	# right on the 1/2" diameter
	res = PipeTables.lookup_minor_loss(MAT, PipeTables.FittingType.ELBOW_90, Utils.inches_to_ft(0.5))
	assert_eq(res.error, PipeTables.LossLookupError.OK)
	assert_almost_eq(res.loss_factor, 1.6, 0.001)
	
	# half way between 5" and 6" diameters
	res = PipeTables.lookup_minor_loss(MAT, PipeTables.FittingType.ELBOW_90, Utils.inches_to_ft(5.5))
	assert_eq(res.error, PipeTables.LossLookupError.OK)
	assert_almost_eq(res.loss_factor, 13.9, 0.001)
	
	# past the highest entry on the table, so we should get the 12" diamter
	res = PipeTables.lookup_minor_loss(MAT, PipeTables.FittingType.ELBOW_90, Utils.inches_to_ft(15.0))
	assert_eq(res.error, PipeTables.LossLookupError.DiameterOOR)
	assert_almost_eq(res.loss_factor, 30.0, 0.001)
	
	# test a different fitting too
	res = PipeTables.lookup_minor_loss(MAT, PipeTables.FittingType.ELBOW_45, Utils.inches_to_ft(3.5))
	assert_eq(res.error, PipeTables.LossLookupError.OK)
	assert_almost_eq(res.loss_factor, 4.6, 0.001)
