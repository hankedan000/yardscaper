class_name SolveSummaryDialog extends Window

signal unknown_var_clicked(uvar: Var)
signal entity_clicked(entity: FEntity)

@onready var rich_text : RichTextLabel = $PanelContainer/VBoxContainer/ScrollContainer/RichTextLabel

func show_summary(solve_time_msec: int, res: FSolver.FSystemSolveResult) -> void:
	rich_text.clear()
	_append_summary_text(rich_text, solve_time_msec, res)
	popup()

static func _append_summary_text(rt: RichTextLabel, solve_time_msec: int, res: FSolver.FSystemSolveResult) -> void:
	# organize results so it easier to display
	var num_subsystems := res.sub_systems.size()
	var unsolved_subsystems : Array[FSolver.SubSystem] = []
	var unsolved_fsolve_results : Array[Math.FSolveResult] = []
	var solved_subsystems : Array[FSolver.SubSystem] = []
	var solved_fsolve_results : Array[Math.FSolveResult] = []
	for i in range(num_subsystems):
		var sub_res := res.sub_system_results[i]
		if sub_res.converged:
			solved_subsystems.push_back(res.sub_systems[i])
			solved_fsolve_results.push_back(res.sub_system_results[i])
		else:
			unsolved_subsystems.push_back(res.sub_systems[i])
			unsolved_fsolve_results.push_back(res.sub_system_results[i])
	
	var num_solved_subsystems := solved_subsystems.size()
	_append_main_summary(rt, num_subsystems, num_solved_subsystems, solve_time_msec)
	_append_unsolved_summaries(rt, unsolved_subsystems, unsolved_fsolve_results)
	_append_solved_summaries(rt, solved_subsystems, solved_fsolve_results)

static func _append_main_summary(rt: RichTextLabel, num_subsystems: int, num_solved_subsystems: int, solve_time_msec: int) -> void:
	rt.append_text("Overall Status: ")
	if num_solved_subsystems == num_subsystems:
		rt.push_color(Color.GREEN)
		rt.append_text("Solved")
	elif num_solved_subsystems == 0:
		rt.push_color(Color.RED)
		rt.append_text("Unsolved")
	elif num_solved_subsystems < num_subsystems:
		rt.push_color(Color.ORANGE)
		rt.append_text("Partially Solved")
	rt.pop() # color
	rt.append_text("\nSolved Subsystems: %d of %d" % [num_solved_subsystems, num_subsystems])
	rt.append_text("\nSolve Time: %d ms" % solve_time_msec)

const CONSTRAINT_STATUS_HINT := "Under: # of unknown vars > # of equations\nWell: # of unknown vars = # of equations\nOver: # of unknown vars < # of equations"

static func _append_unsolved_summaries(
		rt: RichTextLabel,
		subsystems : Array[FSolver.SubSystem],
		fsolve_results: Array[Math.FSolveResult]) -> void:
	if subsystems.is_empty():
		return
	
	rt.push_mono()
	rt.append_text("\n" + _make_block_separator("Unsolved Subsystem Summaries"))
	
	for i in range(subsystems.size()):
		var ssys := subsystems[i]
		var res := fsolve_results[i]
		var sub_title := " Subsystem %d " % (i+1)
		var sep_line := _make_separator_line(sub_title, &"-")
		rt.append_text("\n" + sep_line)
		var c_type := ssys.constrain_type()
		rt.push_hint(CONSTRAINT_STATUS_HINT)
		rt.append_text("\nConstrained Status")
		rt.pop() # hint
		rt.append_text(": %s" % EnumUtils.to_str(FSolver.ConstrainType, c_type))
		rt.append_text("\nSolver iterations: %d of %d max" % [res.iters, res.max_iter])
		rt.append_text("\n# of unknown variables: %d" % ssys.unknown_vars.size())
		rt.append_text("\n# of equations: %d" % ssys.equations.size())
		rt.append_text("\nnodes: ")
		_append_fluid_entity_list(rt, ssys.nodes)
		rt.append_text("\npipes: ")
		_append_fluid_entity_list(rt, ssys.pipes)
		rt.append_text("\nunknown variables:")
		for uvar in ssys.unknown_vars:
			var metadata := Utils.get_metadata_from_fentity(uvar.get_parent_entity())
			if metadata == null:
				continue
			elif metadata.is_hidden_entity:
				continue
			
			rt.append_text("\n  * ")
			rt.push_meta(uvar)
			rt.append_text(uvar.get_name_with_entity())
			rt.pop()
	rt.pop() # mono

static func _append_solved_summaries(
		rt: RichTextLabel,
		subsystems : Array[FSolver.SubSystem],
		fsolve_results: Array[Math.FSolveResult]) -> void:
	if subsystems.is_empty():
		return
	
	rt.push_mono()
	rt.append_text("\n" + _make_block_separator("Solved Subsystem Summaries"))
	
	for i in range(subsystems.size()):
		var ssys := subsystems[i]
		var res := fsolve_results[i]
		var sub_title := " Subsystem %d " % (i+1)
		var sep_line := _make_separator_line(sub_title, &"-")
		rt.append_text("\n" + sep_line)
		rt.append_text("\nSolver iterations: %d of %d max" % [res.iters, res.max_iter])
		rt.append_text("\n# of unknown variables: %d" % ssys.unknown_vars.size())
		rt.append_text("\n# of equations: %d" % ssys.equations.size())
		rt.append_text("\nnodes: ")
		_append_fluid_entity_list(rt, ssys.nodes)
		rt.append_text("\npipes: ")
		_append_fluid_entity_list(rt, ssys.pipes)
	rt.pop() # mono

static func _append_fluid_entity_list(rt: RichTextLabel, entities: Array) -> void:
	rt.append_text("[")
	var comma := &""
	for e: FEntity in entities:
		var metadata := e.user_metadata as FluidEntityMetadata
		if metadata.is_hidden_entity:
			continue
		
		rt.append_text(comma)
		rt.push_meta(e)
		rt.append_text(str(e))
		rt.pop() # meta
		comma = &","
	rt.append_text("]")

const DEFAULT_SEP_LINE_WIDTH := 60
static func _make_separator_line(
		title_txt: String,
		fill_char: StringName,
		width: int = DEFAULT_SEP_LINE_WIDTH,
		begin_txt: StringName = &"",
		end_txt: StringName = &"") -> String:
	if fill_char.length() != 1:
		push_warning("fill char must be a single char. assuming fill_char=' '")
		fill_char = &" "
	elif width < 0:
		push_warning("width must be > 0. assuming width=%d" % DEFAULT_SEP_LINE_WIDTH)
		width = DEFAULT_SEP_LINE_WIDTH
	
	var n_chars_we_have : int = begin_txt.length() + title_txt.length() + end_txt.length()
	var fill_chars_needed : int = width - n_chars_we_have
	var n_left_fill_chars : int = 0
	var n_right_fill_chars : int = 0
	if fill_chars_needed > 0:
		n_left_fill_chars = int(fill_chars_needed / 2.0)
		n_right_fill_chars = fill_chars_needed - n_left_fill_chars
	
	var out_str := begin_txt
	for i in range(n_left_fill_chars):
		out_str += fill_char
	out_str += title_txt
	for i in range(n_right_fill_chars):
		out_str += fill_char
	out_str += end_txt
	return out_str

static func _make_block_separator(title_str: String, block_char: StringName = &"=", width: int = DEFAULT_SEP_LINE_WIDTH) -> String:
	var base_line := _make_separator_line("", block_char, width)
	var out_str := base_line + "\n"
	out_str += _make_separator_line(title_str, &" ", width, block_char, block_char) + "\n"
	out_str += base_line
	return out_str

func _on_close_requested() -> void:
	hide()

func _on_close_button_pressed() -> void:
	_on_close_requested()

func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	if ! is_instance_valid(meta):
		return
	elif meta is Var:
		unknown_var_clicked.emit(meta as Var)
	elif meta is FEntity:
		entity_clicked.emit(meta as FEntity)
