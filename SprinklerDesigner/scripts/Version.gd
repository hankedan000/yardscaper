extends Object
class_name Version

var _major : int = 0
var _minor : int = 0
var _patch : int = 0

func _init(major_v: int, minor_v: int, patch_v: int):
	_major = major_v
	_minor = minor_v
	_patch = patch_v
	if major_v < 0:
		push_error('major version must be >= 0. was %d' % major_v)
	elif minor_v < 0:
		push_error('minor version must be >= 0. was %d' % minor_v)
	elif patch_v < 0:
		push_error('patch version must be >= 0. was %d' % patch_v)
	elif minor_v >= 1000:
		push_error('minor version must be < 1000. was %d' % minor_v)
	elif patch_v >= 1000:
		push_error('patch version must be < 1000. was %d' % patch_v)

static func from_str(sver: String) -> Version:
	var parts := sver.split('.')
	if parts.size() != 3:
		push_error("version split of '%s' didn't result in 3 parts! parts = %s" % [sver, parts])
	var major_v := int(parts[0])
	var minor_v := int(parts[1])
	var patch_v := int(parts[2])
	return Version.new(major_v, minor_v, patch_v)

static func from_int(iver: int) -> Version:
	var patch_v := iver % 1000
	iver /= 1000
	var minor_v := iver % 1000
	iver /= 1000
	var major_v := iver
	return Version.new(major_v, minor_v, patch_v)

func major() -> int:
	return _major

func minor() -> int:
	return _minor

func patch() -> int:
	return _patch

func to_int() -> int:
	var iver = _major * 1000
	iver += _minor
	iver *= 1000
	iver += _patch
	return iver

# @return true if this version is considered compatible with the
# current application version (ie. major <= app.major && minor <= app.minor)
func is_compatible() -> bool:
	var lhs_no_patch := Version.new(_major, _minor, 0)
	var rhs_no_patch := Globals.get_app_version()
	rhs_no_patch._patch = 0
	return lhs_no_patch.compare(rhs_no_patch) <= 0

# @return true if version is equal to 'v'
func is_equal(v: Version) -> bool:
	if _major == v._major and _minor == v._minor and _patch == v._patch:
		return true
	return false

# @return true if version is less than 'v', else false
func is_less(v: Version) -> bool:
	if _major < v._major:
		return true
	elif _major == v._major:
		if _minor < v._minor:
			return true
		elif _minor == v._minor:
			return _patch < v._patch
	return false

# @param[in] v - the version compare again
# @return
# 0 if version is equal to 'v'
# -1 if version is less than 'v
# +1 if version is greater than 'v'
func compare(v: Version) -> int:
	if is_equal(v):
		return 0
	elif is_less(v):
		return -1
	return 1

func _to_string() -> String:
	return "%d.%d.%d" % [_major, _minor, _patch]
