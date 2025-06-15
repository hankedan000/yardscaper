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
