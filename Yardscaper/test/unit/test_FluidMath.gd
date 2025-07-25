extends GutTest

func test_reynolds():
	var d_ft = Utils.inches_to_ft(0.75)
	var v_fps = Utils.gpm_to_cftps(50.0) / Math.area_circle(d_ft)
	var Re := FluidMath.reynolds(v_fps, d_ft, FluidMath.WATER_VISCOCITY_K)
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
		FluidMath.major_loss_psi(0.01555, 19.75, 0.0, 62.285, 0.0625),
		0.00000, # expect
		0.01)    # allowed error
	assert_almost_eq(
		FluidMath.major_loss_psi(0.01555, 19.75, 36.3, 62.285, 0.0625),
		43.52, # expect
		0.01)    # allowed error
