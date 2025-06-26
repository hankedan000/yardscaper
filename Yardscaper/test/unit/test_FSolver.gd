extends GutTest

func test_make_sub_systems_empty():
	var fsys := FSystem.new()
	var systems := FSolver.make_sub_systems(fsys)
	
	assert_eq(systems.size(), 0)

func test_constraints_2pipes_1subsys():
	#           p1               p2
	#   (n1)----------->(n2)----------->(n3)
	var fsys := FSystem.new()
	var n1 := fsys.alloc_node()
	var n2 := fsys.alloc_node()
	var n3 := fsys.alloc_node()
	var p1 := fsys.alloc_pipe()
	var p2 := fsys.alloc_pipe()
	
	# connect the system
	p1.connect_node(n1, FPipe.NODE_SRC)
	p1.connect_node(n2, FPipe.NODE_SINK)
	p2.connect_node(n2, FPipe.NODE_SRC)
	p2.connect_node(n3, FPipe.NODE_SINK)
	
	var systems := FSolver.make_sub_systems(fsys)
	assert_eq(systems.size(), 1)
	assert_eq(systems[0].pipes.size(), 2)
	assert_eq(systems[0].nodes.size(), 3)
	
	var cstats0 := FSolver.calc_constraint_stats(systems[0])
	assert_eq(cstats0.get_unknown_vars(), 8)
	assert_eq(cstats0.get_equation_count(), 5)
	assert_eq(cstats0.get_type(), FSolver.ConstrainType.Under)
	
	fsys.clear()

func test_constraints_2pipes_2subsys():
	#        [subsys0]                 [subsys1]
	#           p1                         p2
	#   (n1)----------->(null)    (n2)----------->(n3)
	var fsys := FSystem.new()
	var n1 := fsys.alloc_node()
	var n2 := fsys.alloc_node()
	var n3 := fsys.alloc_node()
	var p1 := fsys.alloc_pipe()
	var p2 := fsys.alloc_pipe()
	
	# connect the system
	p1.connect_node(n1, FPipe.NODE_SRC)
	p2.connect_node(n2, FPipe.NODE_SRC)
	p2.connect_node(n3, FPipe.NODE_SINK)
	
	var systems := FSolver.make_sub_systems(fsys)
	
	assert_eq(systems.size(), 2)
	assert_eq(systems[0].pipes.size(), 1)
	assert_eq(systems[0].nodes.size(), 1)
	assert_eq(systems[1].pipes.size(), 1)
	assert_eq(systems[1].nodes.size(), 2)
	
	var cstats0 := FSolver.calc_constraint_stats(systems[0])
	assert_eq(cstats0.get_unknown_vars(), 5)
	assert_eq(cstats0.get_equation_count(), 2)
	assert_eq(cstats0.get_type(), FSolver.ConstrainType.Under)
	
	var cstats1 := FSolver.calc_constraint_stats(systems[1])
	
	assert_eq(cstats1.get_unknown_vars(), 5)
	assert_eq(cstats1.get_equation_count(), 3)
	assert_eq(cstats1.get_type(), FSolver.ConstrainType.Under)

func test_make_sub_systems_3pipes_1subsys():
	#           p1              p2
	#   (n1)----------->(n2)<----------(n3)
	#                     |
	#                     |p3
	#                     v
	#                   (n4)
	var fsys := FSystem.new()
	var n1 := fsys.alloc_node()
	var n2 := fsys.alloc_node()
	var n3 := fsys.alloc_node()
	var n4 := fsys.alloc_node()
	var p1 := fsys.alloc_pipe()
	var p2 := fsys.alloc_pipe()
	var p3 := fsys.alloc_pipe()
	
	# connect the system
	p1.connect_node(n1, FPipe.NODE_SRC)
	p1.connect_node(n2, FPipe.NODE_SINK)
	p2.connect_node(n3, FPipe.NODE_SRC)
	p2.connect_node(n2, FPipe.NODE_SINK)
	p3.connect_node(n2, FPipe.NODE_SRC)
	p3.connect_node(n4, FPipe.NODE_SINK)
	
	# default some knowns
	n1.h_psi.set_known(8.0)     # n1 is a source of flow
	n3.h_psi.set_known(6.0)     # n3 is a 2nd source of flow
	n2.q_ext_cfs.set_known(0.0) # n2 is a combining tee
	n4.h_psi.set_known(0.0)     # n4 is venting to atmosphere
	
	var systems := FSolver.make_sub_systems(fsys)
	
	assert_eq(systems.size(), 1)
	assert_eq(systems[0].pipes.size(), 3)
	assert_eq(systems[0].nodes.size(), 4)
	
	var cstats0 := FSolver.calc_constraint_stats(systems[0])
	assert_eq(cstats0.get_unknown_vars(), 7)
	assert_eq(cstats0.get_equation_count(), 7)
	assert_eq(cstats0.get_type(), FSolver.ConstrainType.Well)
	
