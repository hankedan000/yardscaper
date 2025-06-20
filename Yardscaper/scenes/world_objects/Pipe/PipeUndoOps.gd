class_name PipeUndoOps
extends Object

class FlowSourceEdit:
	extends UndoController.UndoOperation
	
	var _world : WorldViewportContainer = null
	var _parent_pipe_idx_in_world : int = 0
	var _from :PipeFlowSource.PositionInfo = null
	var _to :PipeFlowSource.PositionInfo = null
	
	func _init(flow_src: PipeFlowSource, from: PipeFlowSource.PositionInfo, to: PipeFlowSource.PositionInfo):
		_world = flow_src.parent_pipe.world
		_parent_pipe_idx_in_world = flow_src.parent_pipe.get_order_in_world()
		_from = from
		_to = to
	
	func undo() -> bool:
		var parent_pipe := _get_parent_pipe()
		var all_pipes := parent_pipe.get_sim().get_all_pipes()
		parent_pipe.flow_src.apply_position_info(all_pipes, _from)
		return true
		
	func redo() -> bool:
		var parent_pipe := _get_parent_pipe()
		var all_pipes := parent_pipe.get_sim().get_all_pipes()
		parent_pipe.flow_src.apply_position_info(all_pipes, _to)
		return true
		
	func pretty_str() -> String:
		return str({
			'_parent_pipe_idx_in_world' : _parent_pipe_idx_in_world,
			'_from' : _from.to_dict(),
			'_to' : _to.to_dict()
		})
	
	func _get_parent_pipe() -> Pipe:
		return _world.objects.get_child(_parent_pipe_idx_in_world) as Pipe
