extends GutTest

func test_reynolds():
	var diam_h = Utils.inches_to_ft(0.75)
	var velocity = Utils.gpm_to_cftps(50.0) / Math.area_circle(diam_h)
	var Re := FluidMath.reynolds(velocity, diam_h, FluidMath.WATER_VISCOCITY_K)
	assert_almost_eq(Re, 221840.0, 1.0)

func test_f_darcy():
	# Laminar flow (Re < 2000)
	assert_almost_eq(
		FluidMath.f_darcy(  1000.0, 0.00008),
		0.064000, # expect
		0.000001) # allowed error
	# Turbulent flow (Re >= 4000)
	assert_almost_eq(
		FluidMath.f_darcy(221774.0, 0.00008),
		0.015987, # expect
		0.000001) # allowed error

func test_major_loss():
	assert_almost_eq(
		FluidMath.major_loss(0.01555, 19.75, 0.0, 62.285, 0.0625),
		0.00000, # expect
		0.01)    # allowed error
	assert_almost_eq(
		FluidMath.major_loss(0.01555, 19.75, 36.3, 62.285, 0.0625),
		6267.28, # expect
		0.01)    # allowed error
