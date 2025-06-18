class_name PipeFlowSource
extends PathFollow2D

const PROP_KEY_POSITION_INFO := &'position_info'
const PROP_KEY_FITTING_TYPE := &'fitting_type'

const SNAP_DIST_PX := 5.0
const UNSNAP_DIST_PX := 7.0 # slightly more so it doesn't toggle rapidly near edge

class PositionInfo:
	var is_free_floating : bool = true
	var src_pipe_user_label : String = ""
	var src_pipe_progress : float = 0.0
	var free_position : Vector2 = Vector2()
	
	func to_dict() -> Dictionary:
		var obj = {}
		obj[&'is_free_floating'] = is_free_floating
		obj[&'src_pipe_user_label'] = src_pipe_user_label
		obj[&'src_pipe_progress'] = src_pipe_progress
		obj[&'free_position'] = Utils.vect2_to_pair(free_position)
		return obj
	
	static func from_dict(obj: Dictionary) -> PositionInfo:
		var info := PositionInfo.new()
		info.is_free_floating = DictUtils.get_w_default(obj, &'is_free_floating', true)
		info.src_pipe_user_label = DictUtils.get_w_default(obj, &'src_pipe_user_label', "")
		info.src_pipe_progress = DictUtils.get_w_default(obj, &'src_pipe_progress', 0.0)
		info.free_position = Utils.pair_to_vect2(DictUtils.get_w_default(obj, &'free_position', [0.0, 0.0]))
		return info

signal flow_property_changed()
signal moved(old_pos: Vector2, new_pos: Vector2)
signal attached(new_src: Pipe)
signal dettached(old_src: Pipe)

@onready var handle : EditorHandle = $EditorHandle

var fitting_type : PipeTables.FittingType = PipeTables.FittingType.ELBOW_90:
	set(value):
		if fitting_type == value:
			return
		fitting_type = value
		flow_property_changed.emit()

# the pipe to provide fluid flow to
var parent_pipe : Pipe = null

# the pipe to get fluid flow from
var source_pipe : Pipe = null

var _pos_info_from_disk : PositionInfo = null
var _init_pos_info : PositionInfo = null
var _init_pos : Vector2 = Vector2() # init position when starting move
var _mouse_init_pos : Vector2 = Vector2() # init position when starting move

func get_position_info() -> PositionInfo:
	var info := PositionInfo.new()
	info.is_free_floating = source_pipe == null
	info.free_position = position
	info.src_pipe_progress = progress
	if source_pipe:
		info.src_pipe_user_label = source_pipe.user_label
	return info

func get_flow_stats() -> Pipe.FlowStats:
	if ! source_pipe:
		return Pipe.FlowStats.new()
	return source_pipe.get_flow_stats_at_progress(progress)

func is_attached() -> bool:
	return source_pipe != null

func detach_from_source() -> void:
	if ! is_inside_tree():
		push_error("can't detach if not inside tree")
		return
	
	if source_pipe:
		source_pipe.path.remove_child(self)
		parent_pipe.add_child(self)
		var old_source := source_pipe
		source_pipe = null
		dettached.emit(old_source)

func attach_to_source_at_progress(pipe: Pipe, at_progress: float) -> void:
	if pipe == null:
		push_error("can't attach to a null pipe")
		return
	elif pipe == parent_pipe:
		push_error("can't attach to parent pipe")
		return
	
	detach_from_source()
	get_parent().remove_child(self)
	pipe.path.add_child(self)
	source_pipe = pipe
	progress = at_progress
	attached.emit(source_pipe)

# called by the FluidSimulator once it restores all objects from disk
func init_flow_source(all_pipes: Array[Pipe]) -> void:
	if _pos_info_from_disk != null:
		apply_position_info(all_pipes, _pos_info_from_disk)
		_pos_info_from_disk = null
	
func apply_position_info(all_pipes: Array[Pipe], info: PositionInfo) -> void:
	if info.is_free_floating:
		if is_attached():
			detach_from_source()
		position = info.free_position
	else:
		# search over through pipes and attach to one that matches our source's label
		for pipe in all_pipes:
			if pipe.user_label == info.src_pipe_user_label:
				attach_to_source_at_progress(pipe, info.src_pipe_progress)
				return
		
		push_warning("source pipe '%s' not found" % info.src_pipe_user_label)

func serialize():
	var obj = {}
	obj[PROP_KEY_POSITION_INFO] = get_position_info().to_dict()
	obj[PROP_KEY_FITTING_TYPE] = EnumUtils.to_str(PipeTables.FittingType, fitting_type)
	return obj

func deserialize(obj):
	var pos_info_dict = DictUtils.get_w_default(obj, PROP_KEY_POSITION_INFO, null)
	if pos_info_dict is Dictionary:
		_pos_info_from_disk = PipeFlowSource.PositionInfo.from_dict(pos_info_dict)
	var fitting_type_str := DictUtils.get_w_default(obj, PROP_KEY_FITTING_TYPE, '') as String
	fitting_type = EnumUtils.from_str(PipeTables.FittingType, PipeTables.FittingType.ELBOW_90, fitting_type_str) as PipeTables.FittingType

func _ready() -> void:
	handle.user_text = "Flow Source"
	handle.get_button().button_down.connect(_on_handle_button_down)
	set_process_input(false)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var world_mouse_pos := get_global_mouse_position()
		var mouse_delta_pos := world_mouse_pos - _mouse_init_pos
		
		if is_attached():
			var info := Utils.find_closest_point_on_path(source_pipe.path, world_mouse_pos)
			var dist_to_point := (info.global_position - world_mouse_pos).length()
			if dist_to_point > UNSNAP_DIST_PX:
				detach_from_source()
				global_position = _init_pos + mouse_delta_pos
			else:
				progress = info.progress
		else:
			global_position = _init_pos + mouse_delta_pos
			_snap_to_nearest_pipe(TheFluidSimulator.get_all_pipes())
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && ! event.pressed:
			if _init_pos != global_position:
				parent_pipe.undoable_edit.emit(PipeUndoOps.FlowSourceEdit.new(
					self,
					_init_pos_info,
					get_position_info()))
				moved.emit(_init_pos, global_position)
			set_process_input(false)

func _snap_to_nearest_pipe(all_pipes: Array[Pipe]) -> void:
	var clostest_dist_yet : float = SNAP_DIST_PX
	var nearest_pipe : Pipe = null
	var nearest_point_info : Utils.ClosestPointInfo = null
	
	for pipe in all_pipes:
		if pipe == parent_pipe:
			continue
		
		var info := Utils.find_closest_point_on_path(pipe.path, self.global_position)
		var dist_to_point := (info.global_position - global_position).length()
		if dist_to_point <= clostest_dist_yet:
			clostest_dist_yet = dist_to_point
			nearest_pipe = pipe
			nearest_point_info = info
	
	if nearest_pipe:
		attach_to_source_at_progress(nearest_pipe, nearest_point_info.progress)

func _on_handle_button_down() -> void:
	_init_pos_info = get_position_info()
	_init_pos = global_position
	_mouse_init_pos = get_global_mouse_position()
	set_process_input(true)
