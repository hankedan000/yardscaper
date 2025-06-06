class_name PipeUndoOps
extends Object

class FlowSourceEdit:
	extends UndoController.UndoOperation
	
	var _flow_src : PipeFlowSource = null
	var _from :PipeFlowSource.PositionInfo = null
	var _to :PipeFlowSource.PositionInfo = null
	
	func _init(flow_src: PipeFlowSource, from: PipeFlowSource.PositionInfo, to: PipeFlowSource.PositionInfo):
		_flow_src = flow_src
		_from = from
		_to = to
	
	func undo() -> bool:
		var all_pipes := _flow_src.parent_pipe.get_sim().get_all_pipes()
		_flow_src.apply_position_info(all_pipes, _from)
		return true
		
	func redo() -> bool:
		var all_pipes := _flow_src.parent_pipe.get_sim().get_all_pipes()
		_flow_src.apply_position_info(all_pipes, _to)
		return true
		
	func pretty_str() -> String:
		return str({
			'_flow_src.parent_pipe.user_label' : _flow_src.parent_pipe.user_label,
			'_from' : _from.to_dict(),
			'_to' : _to.to_dict()
		})
