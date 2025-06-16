extends FluidSimTest

var pipe1 : Pipe = null

func before_all():
	pipe1 = instance_pipe("pipe1")
	pipe1.point_a = Utils.ft_to_px_vec(Vector2( 5.0, 0.0)) # 5ft right
	pipe1.point_b = Utils.ft_to_px_vec(Vector2(25.0, 0.0)) # 25ft right
	pipe1.diameter_inches = 0.75 # 3/4in
	pipe1.is_flow_source = true
	pipe1.src_pressure_psi = 60.0
	pipe1.src_flow_rate_gpm = 50.0

func test_pipe_attributes():
	assert_almost_eq(pipe1.dist_ft(), 20.0, 0.0001)
	assert_almost_eq(pipe1.get_diam_h(), 0.0625, 0.0001)
	assert_almost_eq(pipe1.get_area_h(), 0.0030679, 0.0000001)

func test_sim_base_case():
	sim.run_calculations()
	
	# make sure rebake occured
	assert_eq(sim.get_sim_cycles(), 1)
	assert_eq(pipe1.path.curve.get_baked_points().size(), 77)
	assert_eq(pipe1._q_points.size(), pipe1.path.curve.get_baked_points().size())
	assert_eq(pipe1._p_points.size(), pipe1.path.curve.get_baked_points().size())
	
	assert_almost_eq(Utils.cftps_to_gpm(pipe1.get_min_flow()), 50.0, 0.01)
	assert_almost_eq(Utils.cftps_to_gpm(pipe1.get_max_flow()), 50.0, 0.01)
	assert_almost_eq(Utils.psft_to_psi(pipe1.get_min_pressure()), 15.172, 0.001)
	assert_almost_eq(Utils.psft_to_psi(pipe1.get_max_pressure()), 60.0, 0.001)

func test_sim_rebake_to_1_inch():
	assert_eq(pipe1.is_rebake_needed(), false)
	pipe1.diameter_inches = 1.0
	assert_eq(pipe1.is_rebake_needed(), true)
	
	sim.run_calculations()
	
	# make sure rebake occured
	assert_eq(sim.get_sim_cycles(), 2)
	assert_eq(pipe1.path.curve.get_baked_points().size(), 77)
	assert_eq(pipe1._q_points.size(), pipe1.path.curve.get_baked_points().size())
	assert_eq(pipe1._p_points.size(), pipe1.path.curve.get_baked_points().size())
	
	assert_almost_eq(Utils.cftps_to_gpm(pipe1.get_min_flow()), 50.0, 0.01)
	assert_almost_eq(Utils.cftps_to_gpm(pipe1.get_max_flow()), 50.0, 0.01)
	assert_almost_eq(Utils.psft_to_psi(pipe1.get_min_pressure()), 48.926, 0.001)
	assert_almost_eq(Utils.psft_to_psi(pipe1.get_max_pressure()), 60.0, 0.001)

func test_sim_rebake_no_flow_source():
	assert_eq(pipe1.is_rebake_needed(), false)
	pipe1.is_flow_source = false
	assert_eq(pipe1.is_rebake_needed(), true)
	
	sim.run_calculations()
	
	# make sure rebake occured
	assert_eq(sim.get_sim_cycles(), 3)
	assert_eq(pipe1.path.curve.get_baked_points().size(), 77)
	assert_eq(pipe1._q_points.size(), pipe1.path.curve.get_baked_points().size())
	assert_eq(pipe1._p_points.size(), pipe1.path.curve.get_baked_points().size())
	
	assert_almost_eq(Utils.cftps_to_gpm(pipe1.get_min_flow()), 0.0, 0.01)
	assert_almost_eq(Utils.cftps_to_gpm(pipe1.get_max_flow()), 0.0, 0.01)
	assert_almost_eq(Utils.psft_to_psi(pipe1.get_min_pressure()), 0.0, 0.001)
	assert_almost_eq(Utils.psft_to_psi(pipe1.get_max_pressure()), 0.0, 0.001)
