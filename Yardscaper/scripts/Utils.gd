class_name Utils
extends Object

const PX_PER_FT : float = 12.0 # 1px per inch
const INCHES_PER_FT : float = 12.0
const CFTPS_PER_GPM : float = 0.0022280092365745
const SQINCH_PER_SQFT : float = 144.0

const DISP_UNIT_NONE : StringName = &""
const DISP_UNIT_IN : StringName = &"in"
const DISP_UNIT_IN2 : StringName = &"in^2"
const DISP_UNIT_FT : StringName = &"ft"
const DISP_UNIT_FT2 : StringName = &"ft^2"
const DISP_UNIT_GPM : StringName = &"gpm"
const DISP_UNIT_PSI : StringName = &"psi"
const DISP_UNIT_FPS : StringName = &"ft/s"

static func ft_to_inches(ft: float) -> float:
	return ft * INCHES_PER_FT

static func inches_to_ft(inches: float) -> float:
	return inches / INCHES_PER_FT

static func ft2_to_in2(ft2: float) -> float:
	return ft2 * SQINCH_PER_SQFT

static func in2_to_ft2(in2: float) -> float:
	return in2 / SQINCH_PER_SQFT

static func ft_to_px(ft: float) -> float:
	return ft * PX_PER_FT

static func px_to_ft(px: float) -> float:
	return px / PX_PER_FT

static func ft_to_px_vec(ft: Vector2) -> Vector2:
	return Vector2(ft_to_px(ft.x), ft_to_px(ft.y))

static func px_to_ft_vec(px: Vector2) -> Vector2:
	return Vector2(px_to_ft(px.x), px_to_ft(px.y))

# US gallons per minute to cubic ft per second
static func gpm_to_cftps(gpm: float) -> float:
	return gpm * CFTPS_PER_GPM

# cubic ft per second to US gallons per minute
static func cftps_to_gpm(cftps: float) -> float:
	return cftps / CFTPS_PER_GPM

# pounds per square inch to pounds per square ft
static func psi_to_psft(psi: float) -> float:
	return psi * SQINCH_PER_SQFT

# pounds per square ft to pounds per square inch
static func psft_to_psi(psft: float) -> float:
	return psft / SQINCH_PER_SQFT

static func pretty_fvar(fvar: Var, disp_unit: StringName, unit_conv: Callable =Callable()) -> String:
	if fvar.state == Var.State.Unknown:
		return "UNKNOWN %s" % disp_unit
	else:
		var value := fvar.value
		if unit_conv.is_valid():
			value = unit_conv.call(value)
		return "%f %s" % [value, disp_unit]

static func pretty_dist(dist_ft: float) -> String:
	# round dist_ft to nearest inch
	dist_ft = round(dist_ft * INCHES_PER_FT) / INCHES_PER_FT
	
	var whole_ft = floor(dist_ft) if dist_ft >= 0 else ceil(dist_ft)
	var whole_in = round(abs(dist_ft - whole_ft) * INCHES_PER_FT)
	return "%0.0f' %0.0f\"" % [whole_ft, whole_in]

static func create_shortcut(letter: Key, ctrl: bool = false, shift: bool = false, alt: bool = false) -> Shortcut:
	var shortcut = Shortcut.new()

	var input_event = InputEventKey.new()

	input_event.keycode = letter
	input_event.ctrl_pressed = ctrl
	input_event.shift_pressed = shift
	input_event.alt_pressed = alt

	shortcut.events = [ input_event ]

	return shortcut

static func world_to_global_px(px: float, zoom_factor: float) -> float:
	return px * zoom_factor

static func global_to_world_px(px: float, zoom_factor: float) -> float:
	return px / zoom_factor

static func world_to_global_size_px(size: Vector2, zoom: Vector2) -> Vector2:
	return Vector2(size.x * zoom.x, size.y * zoom.y)

static func global_to_world_size_px(size: Vector2, zoom: Vector2) -> Vector2:
	return Vector2(size.x / zoom.x, size.y / zoom.y)

static func vect2_to_pair(vec: Vector2) -> Array:
	return [vec.x, vec.y]

static func pair_to_vect2(pair: Array) -> Vector2:
	return Vector2(pair[0], pair[1])

static func get_label_text_size(label: Label, text: String, include_scale: bool = true) -> Vector2:
	var font := label.get_theme_font(&"font")
	var text_size := font.get_multiline_string_size(
		text,
		label.horizontal_alignment,
		(int)(label.size.x) if label.clip_text else -1, # width
		label.get_theme_font_size(&"font_size"),
		-1, # max_lines (unlimited)
		TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND,
		label.justification_flags,
		label.text_direction as TextServer.Direction,
		TextServer.ORIENTATION_HORIZONTAL)
	if include_scale:
		text_size.x *= label.scale.x
		text_size.y *= label.scale.y
	return text_size

static func set_item_checked_by_id(popup: PopupMenu, id: int, checked: bool) -> void:
	var idx := popup.get_item_index(id)
	popup.set_item_checked(idx, checked)

static func draw_sector(canvas: CanvasItem, center: Vector2, radius: float, angle_from: float, angle_to: float, n_points: int, color: Color) -> void:
	if n_points <= 2:
		printerr("n_points must be > 2. n_points = %d" % [n_points])
		return

	var angle_step = (angle_to - angle_from) / (n_points - 1)
	var points = PackedVector2Array()
	points.push_back(center)
	for i in range(n_points):
		var angle_point = angle_from + i * angle_step
		points.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)

	canvas.draw_polygon(points, [color])

class ClosestPointInfo:
	var global_position : Vector2 = Vector2()
	var progress : float = 0.0

static func find_closest_point_on_path(path: Path2D, global_point: Vector2) -> ClosestPointInfo:
	var info := ClosestPointInfo.new()
	var pos_in_path_space := global_point - path.global_position
	info.progress = path.curve.get_closest_offset(pos_in_path_space)
	info.global_position = path.global_position + path.curve.sample_baked(info.progress)
	return info

static func find_nearest_baked_point_index(path: Path2D, point: Vector2) -> int:
	var curve := path.curve
	if not curve:
		return -1

	var closest_index := -1
	var closest_distance := INF
	var baked_points := curve.get_baked_points()

	for i in baked_points.size():
		var dist := point.distance_squared_to(baked_points[i])
		if dist < closest_distance:
			closest_distance = dist
			closest_index = i

	return closest_index

static func reparent_as_submenu(menu: PopupMenu, new_parent_menu: PopupMenu, new_parent_item_id: int) -> void:
	var item_index := new_parent_menu.get_item_index(new_parent_item_id)
	if item_index < 0:
		push_error("couldn't find item_index for item_id %d" % new_parent_item_id)
		return
	menu.get_parent().remove_child(menu)
	new_parent_menu.set_item_submenu_node(item_index, menu)

static func get_bounding_box_around_all(objs: Array[WorldObject]) -> Rect2:
	if objs.is_empty():
		push_error("objs can't be empty")
		return Rect2()
	
	var box := objs[0].get_bounding_box()
	for idx in range(1, objs.size()):
		box = box.merge(objs[idx].get_bounding_box())
	return box

static func fit_camera_to_rect(camera: Camera2D, rect: Rect2, padding: float = 0.0) -> void:
	# Get the size of the viewport (window) in pixels
	var viewport_size = camera.get_viewport_rect().size

	# Add padding to the bounding rect
	var padded_rect = rect.grow_individual(
		rect.size.x * padding,
		rect.size.y * padding,
		rect.size.x * padding,
		rect.size.y * padding
	)
	
	# Calculate the scale needed to fit the rect into the viewport
	var scale_x = viewport_size.x / padded_rect.size.x
	var scale_y = viewport_size.y / padded_rect.size.y

	# Choose the min scale so the whole rect fits in both dimensions
	var zoom_factor = min(scale_x, scale_y)

	# Set the camera zoom (zoom is relative to 1.0, so larger = zoomed out)
	camera.zoom = Vector2(zoom_factor, zoom_factor)

	# Center the camera on the rect
	camera.global_position = padded_rect.get_center()

const PROP_KEY_FVAR_STATE := &'state'
const PROP_KEY_FVAR_VALUE := &'value'

static func add_fvar_knowns_into_dict(fvar: Var, prop_key: StringName, data: Dictionary) -> void:
	if fvar.state == Var.State.Known:
		data[prop_key] = fvar.value

static func get_fvar_knowns_from_dict(fvar: Var, prop_key: StringName, data: Dictionary) -> void:
	fvar.reset()
	if prop_key in data:
		var value = data[prop_key]
		if value is float:
			fvar.set_known(value)

class PropertyResult extends RefCounted:
	var found : bool = false
	var value : Variant = null
	var parent_obj : Object = null
	var last_prop_key : String = ""

## gets an [Object]'s property if the path contains multiple property names
## chained together with dots.
## Example: get_property_w_path(obj, "prop1.prop2.prop3") would return the
## value stored in prop3.
static func get_property_w_path(obj: Object, prop_path: StringName) -> PropertyResult:
	var res := PropertyResult.new()
	var prop_chain := prop_path.split(".", false)
	
	# traverse down the object property path one part at a time
	res.value = obj
	res.parent_obj = null
	var curr_obj : Variant = obj
	for prop_key in prop_chain:
		if ! (curr_obj is Object):
			push_error("can't get to '%s' because previous item wasn't an object. prop_path='%s'" % [prop_key, prop_path])
			return res
		elif ! (prop_key in curr_obj):
			push_error("prop '%s' doesn't exist in object %s. prop_path='%s'" % [prop_key, curr_obj, prop_path])
			return res
		res.parent_obj = curr_obj
		res.value = curr_obj.get(prop_key)
		res.last_prop_key = prop_key
		curr_obj = res.value
	
	res.found = true
	return res

static func get_metadata_from_fentity(fentity: FEntity) -> FluidEntityMetadata:
	if ! is_instance_valid(fentity):
		return null
	elif ! is_instance_valid(fentity.user_metadata):
		return null
	elif ! (fentity.user_metadata is FluidEntityMetadata):
		return null
	return fentity.user_metadata as FluidEntityMetadata

static func get_wobj_from_fentity(fentity: FEntity) -> WorldObject:
	var metadata := get_metadata_from_fentity(fentity)
	if metadata == null:
		return
	return metadata.parent_wobj

static func get_wobj_from_fvar(fvar: Var) -> WorldObject:
	var metadata := get_metadata_from_fentity(fvar.get_parent_entity())
	if metadata == null:
		return
	return metadata.parent_wobj

class MagnetParents extends RefCounted:
	var magnet : MagneticArea = null
	var handle : EditorHandle = null
	var wobj : WorldObject = null

static func get_magnet_parents(magnet: MagneticArea) -> MagnetParents:
	var mag_parents := MagnetParents.new()
	mag_parents.magnet = magnet
	
	var mag_parent : Node = magnet.get_parent()
	while is_instance_valid(mag_parent):
		if mag_parent is EditorHandle:
			mag_parents.handle = mag_parent as EditorHandle
		elif mag_parent is WorldObject:
			mag_parents.wobj = mag_parent as WorldObject
			break
		mag_parent = mag_parent.get_parent()
	return mag_parents
