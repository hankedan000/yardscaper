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
	var inters : int = 1 # iterations it took to solve
	var x : Array[float] = []

# Solves a system of nonlinear equations f(x) = 0 using Newton-Raphson with finite differences
# `f` is a function: Array[float] -> Array[float]
# `x0` is the initial guess: Array[float]
# `tol` is the how close the function will try to get before stopping
# `max_iter` the maximum # of iterations to try before stopping
# `max_delta` pervents large jumps in x[i] per iteration
static func fsolve(f: Callable, x0: Array[float], tol := 1e-9, max_iter := 50, max_delta := 1.0) -> FSolveResult:
	var res := FSolveResult.new()
	res.x = x0.duplicate()
	var n = res.x.size()
	var h = 1e-8  # finite difference step size

	while res.inters <= max_iter:
		var fx = f.callv([res.x])
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
			var f_step = f.callv([x_step])

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
		var dx = solve_linear(J_T, fx)
		for i in range(n):
			var step = clamp(-dx[i], -max_delta, max_delta)
			res.x[i] += step
		
		res.inters += 1

	return res

# Basic linear solver using Gaussian elimination
# Solves A * x = b, returns x
static func solve_linear(A: Array, b: Array) -> Array:
	var n = A.size()
	var M = []

	# Create augmented matrix
	for i in range(n):
		var row = A[i].duplicate()
		row.append(b[i])
		M.append(row)

	# Forward elimination
	for k in range(n):
		for i in range(k+1, n):
			var factor = M[i][k] / M[k][k]
			for j in range(k, n+1):
				M[i][j] -= factor * M[k][j]

	# Backward substitution
	var x = []
	for i in range(n):
		x.append(0.0)
	for i in range(n - 1, -1, -1):
		var sum_ax = 0.0
		for j in range(i + 1, n):
			sum_ax += M[i][j] * x[j]
		x[i] = (M[i][n] - sum_ax) / M[i][i]
	return x
