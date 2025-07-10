extends GutTest

func test_make_sub_systems_empty():
	var fsys := FSystem.new()
	var systems := FSolver.make_sub_systems(fsys)
	
	assert_eq(systems.size(), 0)

func test_constraints_2pipes_1subsys():
	#           p0               p1
	#   (n0)----------->(n1)----------->(n2)
	var fsys := FSystem.new()
	var n0 := fsys.alloc_node()
	var n1 := fsys.alloc_node()
	var n2 := fsys.alloc_node()
	var p0 := fsys.alloc_pipe()
	var p1 := fsys.alloc_pipe()
	
	# connect the system
	p0.connect_node(n0, FPipe.NODE_SRC)
	p0.connect_node(n1, FPipe.NODE_SINK)
	p1.connect_node(n1, FPipe.NODE_SRC)
	p1.connect_node(n2, FPipe.NODE_SINK)
	
	var systems := FSolver.make_sub_systems(fsys)
	assert_eq(systems.size(), 1)
	assert_eq(systems[0].pipes.size(), 2)
	assert_eq(systems[0].nodes.size(), 3)
	
	var sys0 := systems[0]
	assert_eq(sys0.unknown_vars.size(), 8)
	assert_eq(sys0.equations.size(), 5)
	assert_eq(sys0.constrain_type(), FSolver.ConstrainType.Under)
	
	fsys.clear()

func test_constraints_2pipes_2subsys():
	#        [subsys0]                 [subsys1]
	#           p0                         p1
	#   (n0)----------->(null)    (n1)----------->(n2)
	var fsys := FSystem.new()
	var n0 := fsys.alloc_node()
	var n1 := fsys.alloc_node()
	var n2 := fsys.alloc_node()
	var p0 := fsys.alloc_pipe()
	var p1 := fsys.alloc_pipe()
	
	# connect the system
	p0.connect_node(n0, FPipe.NODE_SRC)
	p1.connect_node(n1, FPipe.NODE_SRC)
	p1.connect_node(n2, FPipe.NODE_SINK)
	
	var systems := FSolver.make_sub_systems(fsys)
	
	assert_eq(systems.size(), 2)
	assert_eq(systems[0].pipes.size(), 1)
	assert_eq(systems[0].nodes.size(), 1)
	assert_eq(systems[1].pipes.size(), 1)
	assert_eq(systems[1].nodes.size(), 2)
	
	var sys0 := systems[0]
	assert_eq(sys0.unknown_vars.size(), 5)
	assert_eq(sys0.equations.size(), 2)
	assert_eq(sys0.constrain_type(), FSolver.ConstrainType.Under)
	
	var sys1 := systems[1]
	assert_eq(sys1.unknown_vars.size(), 5)
	assert_eq(sys1.equations.size(), 3)
	assert_eq(sys1.constrain_type(), FSolver.ConstrainType.Under)

func test_make_sub_systems_3pipes_1subsys():
	#           p0              p1
	#   (n0)----------->(n1)<----------(n2)
	#                     |
	#                     |p2
	#                     v
	#                   (n3)
	var fsys := FSystem.new()
	var n0 := fsys.alloc_node()
	var n1 := fsys.alloc_node()
	var n2 := fsys.alloc_node()
	var n3 := fsys.alloc_node()
	var p0 := fsys.alloc_pipe()
	var p1 := fsys.alloc_pipe()
	var p2 := fsys.alloc_pipe()
	
	# connect the system
	p0.connect_node(n0, FPipe.NODE_SRC)
	p0.connect_node(n1, FPipe.NODE_SINK)
	p1.connect_node(n2, FPipe.NODE_SRC)
	p1.connect_node(n1, FPipe.NODE_SINK)
	p2.connect_node(n1, FPipe.NODE_SRC)
	p2.connect_node(n3, FPipe.NODE_SINK)
	
	# default some knowns
	n0.h_psi.set_known(8.0)     # n0 is a source of flow
	n2.h_psi.set_known(6.0)     # n2 is a 2nd source of flow
	n1.q_ext_cfs.set_known(0.0) # n1 is a combining tee
	n3.h_psi.set_known(0.0)     # n3 is venting to atmosphere
	
	var systems := FSolver.make_sub_systems(fsys)
	
	assert_eq(systems.size(), 1)
	assert_eq(systems[0].pipes.size(), 3)
	assert_eq(systems[0].nodes.size(), 4)
	
	var sys0 := systems[0]
	assert_eq(sys0.unknown_vars.size(), 7)
	assert_eq(sys0.equations.size(), 7)
	assert_eq(sys0.constrain_type(), FSolver.ConstrainType.Well)

func test_solve_system_1pipe():
	#           p0
	#   (n0)----------->(n1)
	var fsys := FSystem.new()
	var n0 := fsys.alloc_node()
	var n1 := fsys.alloc_node()
	var p0 := fsys.alloc_pipe()
	
	# connect the system
	p0.connect_node(n0, FPipe.NODE_SRC)
	p0.connect_node(n1, FPipe.NODE_SINK)
	
	# set some knowns
	n0.q_ext_cfs.set_known(Utils.gpm_to_cftps(10.0)) # n0 is a source of flow
	n1.h_psi.set_known(0.0)                          # n1 is venting to atmosphere
	p0.l_ft = 1.0
	p0.d_ft = 1.0 / 12.0
	
	var res := FSolver.solve_system(fsys)
	assert_eq(res.solved, true)
	assert_eq(res.sub_systems.size(), 1)
	var sres0 := res.sub_system_results[0]
	assert_true(sres0.converged)
	assert_true(sres0.iters > 0)
	assert_almost_eq(n0.h_psi.value,     +4.444044, 0.000001)
	assert_almost_eq(p0.q_cfs.value,     +0.022280, 0.000001)
	assert_almost_eq(n1.q_ext_cfs.value, -0.022280, 0.000001)
	assert_eq(n0.h_psi.state,     Var.State.Solved)
	assert_eq(p0.q_cfs.state,     Var.State.Solved)
	assert_eq(n1.q_ext_cfs.state, Var.State.Solved)

func test_solve_system_2subsys():
	#           sub_sys[0] (solvable)               sub_sys[1] (unsolvable)
	#
	#           p0              p1                           p3
	#   (n0)----------->(n1)<----------(n2)         (n4)<----------(null)
	#                     |
	#                     |p2
	#                     v
	#                   (n3)
	var fsys := FSystem.new()
	var n0 := fsys.alloc_node()
	var n1 := fsys.alloc_node()
	var n2 := fsys.alloc_node()
	var n3 := fsys.alloc_node()
	var n4 := fsys.alloc_node()
	var p0 := fsys.alloc_pipe()
	var p1 := fsys.alloc_pipe()
	var p2 := fsys.alloc_pipe()
	var p3 := fsys.alloc_pipe()
	
	# connect the left sub system
	p0.connect_node(n0, FPipe.NODE_SRC)
	p0.connect_node(n1, FPipe.NODE_SINK)
	p1.connect_node(n2, FPipe.NODE_SRC)
	p1.connect_node(n1, FPipe.NODE_SINK)
	p2.connect_node(n1, FPipe.NODE_SRC)
	p2.connect_node(n3, FPipe.NODE_SINK)
	
	# connect the right sub system
	p3.connect_node(n4, FPipe.NODE_SINK)
	
	# set some knowns
	n1.q_ext_cfs.set_known(Utils.gpm_to_cftps(0))    # n1 is a merge point
	n3.h_psi.set_known(0.0)                          # n3 is venting to atmosphere
	p0.q_cfs.set_known(Utils.gpm_to_cftps(10.0))     # p0 is a source of flow
	p1.q_cfs.set_known(Utils.gpm_to_cftps(5.0))      # p1 is a source of flow
	p0.l_ft = 1.0
	p0.d_ft = 1.0 / 12.0
	p1.l_ft = 1.0
	p1.d_ft = 1.0 / 12.0
	p2.l_ft = 1.0
	p2.d_ft = 1.0 / 12.0
	
	var res := FSolver.solve_system(fsys)
	assert_eq(res.solved, false)
	assert_eq(res.sub_systems.size(), 2)
	var sres0 := res.sub_system_results[0]
	assert_true(sres0.converged)
	assert_true(sres0.iters > 0)
	var sres1 := res.sub_system_results[1]
	assert_false(sres1.converged)
	assert_eq(sres1.iters, 0)
	assert_almost_eq(n0.h_psi.value,     +13.559200, 0.000001)
	assert_almost_eq(n0.q_ext_cfs.value, + 0.022280, 0.000001)
	assert_almost_eq(n1.h_psi.value,     + 9.115156, 0.000001)
	assert_almost_eq(n2.h_psi.value,     +10.427673, 0.000001)
	assert_almost_eq(n2.q_ext_cfs.value, + 0.011140, 0.000001)
	assert_almost_eq(p2.q_cfs.value,     + 0.033420, 0.000001)
	assert_almost_eq(n3.q_ext_cfs.value, - 0.033420, 0.000001)
	assert_eq(n0.h_psi.state,     Var.State.Solved)
	assert_eq(n0.h_psi.state,     Var.State.Solved)
	assert_eq(n0.q_ext_cfs.state, Var.State.Solved)
	assert_eq(n1.h_psi.state,     Var.State.Solved)
	assert_eq(n2.h_psi.state,     Var.State.Solved)
	assert_eq(n2.q_ext_cfs.state, Var.State.Solved)
	assert_eq(p2.q_cfs.state,     Var.State.Solved)
	assert_eq(n3.q_ext_cfs.state, Var.State.Solved)
