class_name Math
extends Object

const _LOG_2 := log(2.0)
const _LOG_10 := log(10.0)

static func ln(x: float) -> float:
	return log(x)

static func log2(x: float) -> float:
	return log(x) / _LOG_2

static func log10(x: float) -> float:
	return log(x) / _LOG_10

static func area_circle(diameter: float) -> float:
	var radius = diameter / 2.0
	return PI * radius * radius

class FSolveResult extends RefCounted:
	var converged : bool = false # true if the solution converged, false other wise
	var iters : int = 0 # iterations it took to solve
	var max_iter : int = 0 # maximum iterations fsolve() was allowed to make
	var x := PackedFloat64Array()

class FSolveProfilers extends RefCounted:
	var fx := TickTockProfiler.new("fx")
	var solve_linear := TickTockProfiler.new("solve_linear")
	var solve_linear_profiles := SolveLinearProfilers.new()

# Solves a system of nonlinear equations f(x) = 0 using Newton-Raphson with finite differences
# `f` is a function: Array[float] -> Array[float]
# `x0` is the initial guess: Array[float]
# `tol` is the how close the function will try to get before stopping
# `max_iter` the maximum # of iterations to try before stopping
# `max_delta` pervents large jumps in x[i] per iteration
static func fsolve(f: Callable, x0: PackedFloat64Array, tol := 1e-9, max_iter := 50, max_delta := 1.0, dbg_printer:=Callable()) -> FSolveResult:
	var res := FSolveResult.new()
	res.max_iter = max_iter
	res.x = x0.duplicate()
	var n = res.x.size()
	var h = 1e-8  # finite difference step size
	if n == 0:
		res.converged = true
		return res
	
	# allocate some arrays and matrices we'll reuse each iteration
	var fx := PackedFloat64Array()
	var f_step := PackedFloat64Array()
	fx.resize(n)
	f_step.resize(n)
	var J : Array[PackedFloat64Array] = [] # for Jacobian approximation
	for i in range(n):
		var row := PackedFloat64Array()
		row.resize(n)
		J.push_back(row)
		
	while res.iters <= max_iter:
		res.iters += 1
		if dbg_printer.is_valid():
			dbg_printer.call(res.iters, res.x)
		f.call(res.x, fx)
		if fx.size() != n:
			push_error("Function output size must match input size")
			return res

		# Check convergence
		var residual = 0.0
		for i in fx:
			residual += abs(i)
		if residual < tol:
			res.converged = true
			return res

		# Approximate Jacobian with finite differences
		for i in range(n):
			var x_step = res.x.duplicate()
			x_step[i] += h
			f.call(x_step, f_step)

			for j in range(n):
				J[j][i] = (f_step[j] - fx[j]) / h # dfdx

		# Solve linear system: J * dx = -f(x)
		var dx := solve_linear(J, fx)
		if dx.is_empty():
			return res
		for i in range(n):
			var step = clamp(-dx[i], -max_delta, max_delta)
			res.x[i] += step

	return res

class SolveLinearProfilers extends RefCounted:
	var build_aug_mat := TickTockProfiler.new("build_aug_mat")
	var forw_elim := TickTockProfiler.new("forw_elim")
	var back_sub := TickTockProfiler.new("back_sub")

# Solves A * x = b using Gaussian elimination with partial pivoting
# A: Array[Array[float]] (n x n)
# b: Array[float] (length n)
# Returns: Array[float] x such that A * x ≈ b
static func solve_linear(A: Array[PackedFloat64Array], b: PackedFloat64Array) -> PackedFloat64Array:
	var n = A.size()
	var M = []

	# Build augmented matrix [A | b]
	for i in range(n):
		var m_row := PackedFloat64Array()
		var a_row := A[i]
		m_row.resize(a_row.size() + 1)
		for j in range(a_row.size()):
			m_row[j] = a_row[j]
		m_row[a_row.size()] = b[i]
		M.append(m_row)

	# Forward elimination with partial pivoting
	for k in range(n):
		# Find row with largest absolute pivot in column k
		var max_row = k
		var max_val = abs(M[k][k])
		for r in range(k + 1, n):
			var val = abs(M[r][k])
			if val > max_val:
				max_val = val
				max_row = r

		# Check for singular matrix
		if max_val < 1e-12:
			push_error("Singular or nearly singular matrix at row %d" % k)
			return PackedFloat64Array()

		# Swap rows if necessary
		if max_row != k:
			var temp = M[k]
			M[k] = M[max_row]
			M[max_row] = temp

		# Eliminate entries below pivot
		for i in range(k + 1, n):
			var factor = M[i][k] / M[k][k]
			for j in range(k, n + 1):
				M[i][j] -= factor * M[k][j]

	# Back substitution
	var x := PackedFloat64Array()
	x.resize(n)
	x.fill(0.0)

	for i in range(n - 1, -1, -1):
		var sum_ax = 0.0
		for j in range(i + 1, n):
			sum_ax += M[i][j] * x[j]
		x[i] = (M[i][n] - sum_ax) / M[i][i]

	return x

static func matrix_to_wolfram_str(M: Array) -> String:
	var wolfram_str := str(M)
	wolfram_str = wolfram_str.replacen("[", "{")
	wolfram_str = wolfram_str.replacen("]", "}")
	wolfram_str = wolfram_str.replacen(" ", "")
	return wolfram_str

static func matrix_to_numpy_str(M: Array) -> String:
	var numpy_str := str(M)
	numpy_str = numpy_str.replacen(" ", "")
	return numpy_str
