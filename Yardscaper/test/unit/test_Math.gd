extends GutTest

func test_solve_linear():
	var x = Math.solve_linear([[2.0, 1.0], [1.0, 3.0]], [5.0, 6.0])
	assert_eq(x.size(), 2)
	assert_almost_eq(x[0], 1.8, 0.001)
	assert_almost_eq(x[1], 1.4, 0.001)
	
	x = Math.solve_linear([[3.0, -1.0, 7.0], [0.0, 4.0, -3.0], [-1.0, 2.0, 2.0]], [1.0, 2.0, 3.0])
	assert_eq(x.size(), 3)
	assert_almost_eq(x[0], -0.432835, 0.000001)
	assert_almost_eq(x[1], +0.835820, 0.000001)
	assert_almost_eq(x[2], +0.447761, 0.000001)

# eq0 = 4 * sin(x0) - 4 = 0
func _equationsA(x):
	var y = 4 * sin(x[0]) - 4
	return [y]

func test_fsolve_equationsA():
	var res := Math.fsolve(_equationsA, [0.3])
	assert_true(res.converged)
	assert_true(res.inters > 1)
	assert_eq(res.x.size(), 1)
	assert_almost_eq(res.x[0], 1.570781, 0.000001)

# eq0 = x1 * x0 - x1 - 6 = 0
# eq1 = x0 * cos(x1) - 3 = 0
func _equationsB(x):
	var y = [x[1] * x[0] - x[1] - 6.0, x[0] * cos(x[1]) - 3.0]
	return y

func test_fsolve_equationsB():
	var res := Math.fsolve(_equationsB, [4.0, 2.0])
	assert_true(res.converged)
	assert_true(res.inters > 1)
	assert_eq(res.x.size(), 2)
	assert_almost_eq(res.x[0], 6.499430, 0.000001)
	assert_almost_eq(res.x[1], 1.091022, 0.000001)

# eq0 = x0 * x1^2 - 4.0 = 0
# eq1 = x0 - 1.0        = 0
func _equationsC(x):
	var y = [x[0] * x[1] * x[1] - 4.0, x[0] - 1.0]
	return y

func test_fsolve_equationsC():
	var res := Math.fsolve(_equationsC, [1, 1])
	assert_true(res.converged)
	assert_true(res.inters > 1)
	assert_eq(res.x.size(), 2)
	assert_almost_eq(res.x[0], +1.0, 0.000001)
	assert_almost_eq(res.x[1], +2.0, 0.000001)
