class_name FluidMath
extends Object

# kinematic viscocity of water at 72 deg F
# https://www.engineeringtoolbox.com/water-dynamic-kinematic-viscosity-d_596.html
const WATER_VISCOCITY_K : float = 0.00001023 # ft^2/s
# density of water at 72 deg F
# https://www.engineeringtoolbox.com/water-density-specific-weight-d_595.html
const WATER_DENSITY : float = 62.285 # lb/ft^3
# accelration due to gravity
const G : float = 32.174 # ft/s^2

# Computes Reynolds Number for a cylindrical pipe
#
# @param[in] velocity - velocity of the fluid through pipe (ft/s)
# @param[in] diam_h - hydraulic diameter of the pipe (ft)
# @param[in] viscosity_k - kinematic viscosity (ft^2/s)
static func reynolds(velocity: float, diam_h: float, viscosity_k: float) -> float:
	return velocity * diam_h / viscosity_k

# Computes the Darcy friction factor for a fluid through a pipe.
#
# @param[in] Re - the Reynolds Number
# @param[in] rel_roughness - equal to E/d; where ...
#    E is the material roughness
#    d is the pipe's diameter
static func f_darcy(Re: float, rel_roughness: float) -> float:
	# Laminar flow
	if Re < 2000.0:
		return 64.0 / Re

	# Transitional flow (not well-defined)
	if Re < 4000.0:
		# Linearly interpolate between laminar and turbulent (not precise, but safe fallback)
		var f_laminar = 64.0 / 2000.0
		var f_turbulent = _colebrook_white(4000.0, rel_roughness)
		var t = (Re - 2000.0) / 2000.0
		return lerp(f_laminar, f_turbulent, t)

	# Turbulent flow
	return _colebrook_white(Re, rel_roughness)

static func _colebrook_white(Re: float, rel_roughness: float) -> float:
	# Initial guess using Swamee-Jain approximation
	var f = 0.02
	for i in range(20):
		var rhs = -2.0 * Math.log10((rel_roughness / 3.7) + (2.51 / (Re * sqrt(f))))
		var f_new = 1.0 / (rhs * rhs)
		if abs(f - f_new) < 0.00001:
			break
		f = f_new
	return f

# Computes the major pressure loss due to friction along a length of pipe.
#
# @param[in] f_darcy - the darcy friction factor
# @param[in] length - length of the pipe (ft)
# @param[in] velocity - velocity of fluid in the pipe (ft/s)
# @param[in] density - density of the fluid (lb/ft^3)
# @param[in] diam_h - hydraulic diameter of the pipe (ft)
# @return pressure loss (lb/ft^2)
@warning_ignore("shadowed_variable")
static func major_loss(f_darcy: float, length: float, velocity: float, density: float, diam_h: float) -> float:
	return (f_darcy * length * velocity * velocity * density) / (2.0 * G * diam_h)
