extends GutTest

func test_builtin_loss_lookup():
	var sprink_db := SprinklerDB.new()
	sprink_db.load_builtin_data()
	
	var manu := sprink_db.get_manufacturer("Rain Bird")
	var head := manu.get_head("RVAN14")
	var flow_model := head.flow_model as SprinklerFlowModel.Fan
	
	# right on 2nd to last entry
	var res := flow_model.get_minor_loss_at_sweep(210.0)
	assert_eq(res.error, LUT_Utils.LerpError.OK)
	assert_almost_eq(res.value, 0.0002164, 0.0000001)
	
	# right on upper range
	res = flow_model.get_minor_loss_at_sweep(270.0)
	assert_eq(res.error, LUT_Utils.LerpError.OK)
	assert_almost_eq(res.value, 0.0001310, 0.0000001)
	
	# between the last two rows
	res = flow_model.get_minor_loss_at_sweep(240.0)
	assert_eq(res.error, LUT_Utils.LerpError.OK)
	assert_almost_eq(res.value, 0.0001737, 0.0000001)
	
	# below the lower range
	res = flow_model.get_minor_loss_at_sweep(0.0)
	assert_eq(res.error, LUT_Utils.LerpError.OutOfRange)
	assert_almost_eq(res.value, 0.0011653, 0.0000001) # returns the 90deg loss factor
	
	# above upper range
	res = flow_model.get_minor_loss_at_sweep(360.0)
	assert_eq(res.error, LUT_Utils.LerpError.OutOfRange)
	assert_almost_eq(res.value, 0.0001310, 0.0000001) # returns the 270deg loss factor
