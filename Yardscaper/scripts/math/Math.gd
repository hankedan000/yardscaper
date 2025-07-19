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
	var x : Array[float] = []

# Solves a system of nonlinear equations f(x) = 0 using Newton-Raphson with finite differences
# `f` is a function: Array[float] -> Array[float]
# `x0` is the initial guess: Array[float]
# `tol` is the how close the function will try to get before stopping
# `max_iter` the maximum # of iterations to try before stopping
# `max_delta` pervents large jumps in x[i] per iteration
static func fsolve(f: Callable, x0: Array[float], tol := 1e-9, max_iter := 50, max_delta := 1.0, dbg_printer:=Callable()) -> FSolveResult:
	var res := FSolveResult.new()
	res.max_iter = max_iter
	res.x = x0.duplicate()
	var n = res.x.size()
	var h = 1e-8  # finite difference step size
	
	if n == 0:
		res.converged = true
		return res

	while res.iters <= max_iter:
		if dbg_printer.is_valid():
			dbg_printer.call(res.iters, res.x)
		var fx = f.call(res.x)
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
		var J = []
		for i in range(n):
			var x_step = res.x.duplicate()
			x_step[i] += h
			var f_step = f.call(x_step)

			var column = []
			for j in range(n):
				var dfdx = (f_step[j] - fx[j]) / h
				column.append(dfdx)
			J.append(column)

		# Transpose J to match solver format
		var J_T = []
		for i in range(n):
			var row = []
			for j in range(n):
				row.append(J[j][i])
			J_T.append(row)

		# Solve linear system: J * dx = -f(x)
		var dx := solve_linear(J_T, fx)
		if dx.is_empty():
			return res
		for i in range(n):
			var step = clamp(-dx[i], -max_delta, max_delta)
			res.x[i] += step
		
		res.iters += 1

	return res

# Solves A * x = b using Gaussian elimination with partial pivoting
# A: Array[Array[float]] (n x n)
# b: Array[float] (length n)
# Returns: Array[float] x such that A * x ≈ b
static func solve_linear(A: Array, b: Array) -> Array:
	var n = A.size()
	var M = []

	# Build augmented matrix [A | b]
	for i in range(n):
		var row = A[i].duplicate()
		row.append(b[i])
		M.append(row)

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
			return []

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
	var x = []
	for i in range(n):
		x.append(0.0)

	for i in range(n - 1, -1, -1):
		var sum_ax = 0.0
		for j in range(i + 1, n):
			sum_ax += M[i][j] * x[j]
		x[i] = (M[i][n] - sum_ax) / M[i][i]

	return x
