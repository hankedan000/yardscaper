extends GutTest

func test_sprink_type():
	var fsys := FSystem.new()
	var fnode := fsys.alloc_node()
	fnode.set_type(FNode.Type.Sprink)
	assert_eq(fnode.get_type(), FNode.Type.Sprink)
	assert_eq(fnode.h_psi.state, Var.State.Unknown)
	assert_eq(fnode.q_ext_cfs.state, Var.State.Known)
	
	# make sure a change in h_psi causes a recalc of q_ext_cfs
	fnode.K_s = 0.5
	fnode.h_psi.value = 16.0
	assert_almost_eq(fnode.q_ext_cfs.value, -2.0, 0.1)
	
	# make sure a change in K_s causes a recalc of q_ext_cfs
	fnode.K_s = 1.0
	assert_almost_eq(fnode.q_ext_cfs.value, -4.0, 0.1)
	
	# might as well change h_psi one more time
	fnode.h_psi.value = 9.0
	assert_almost_eq(fnode.q_ext_cfs.value, -3.0, 0.1)
