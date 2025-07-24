class_name LUT_Utils extends RefCounted

enum LerpError {
	OK, Empty, OutOfRange
}

class LerpResult extends RefCounted:
	var error : LerpError = LerpError.OK
	var value : float = 0.0

static func lerp_lookup(lut: Array, search_value: float, search_col: int, return_col: int) -> LerpResult:
	var res := LerpResult.new()
	res.value = search_value
	var list_size := lut.size()
	if list_size == 0:
		res.error = LerpError.Empty
		return res
	elif list_size < 2:
		res.value = lut[0][return_col]
		res.error = LerpError.OutOfRange
		return res
	
	# Iterate through pairs
	for i in range(list_size - 1):
		var curr = lut[i]
		var next = lut[i + 1]
		
		if search_value < curr[search_col]:
			# Target is before the first element
			res.value = curr[return_col]
			res.error = LerpError.OutOfRange
			return res
		
		if curr[search_col] <= search_value && search_value < next[search_col]:
			# search_value is between two entries. interpolate to get result
			res.value = _lerp_tuples(curr, next, search_value, search_col, return_col)
			res.error = LerpError.OK
			return res
	
	# search_value is either at or beyond the last element return last value
	var last = lut[list_size - 1]
	res.value = last[return_col]
	res.error = LerpError.OutOfRange if (search_value > last[search_col]) else LerpError.OK
	return res

static func _lerp_tuples(a: Array, b: Array, lerp_value: float, lerp_idx: int, return_col: int) -> float:
	var spread = b[lerp_idx] - a[lerp_idx] as float
	var weight := (lerp_value - a[lerp_idx]) / spread  as float
	return lerpf(a[return_col], b[return_col], weight)

static func _sort_tuple_by_idx(a: Array, b: Array, idx: int) -> bool:
	return a[idx] < b[idx]
