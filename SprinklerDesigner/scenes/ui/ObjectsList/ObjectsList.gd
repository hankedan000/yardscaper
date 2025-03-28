extends VBoxContainer

@onready var grid := $ScrollContainer/ObjectsGrid

var _ui_needs_sync = false

var world : WorldViewportContainer = null:
	set(value):
		if value is WorldViewportContainer:
			world = value
			world.objects.child_entered_tree.connect(_on_world_child_entered_tree)
			world.objects.child_exiting_tree.connect(_on_world_child_exiting_tree)
			world.objects.child_order_changed.connect(_on_world_child_order_changed)
			queue_ui_sync()

func _ready():
	queue_ui_sync()

func _process(_delta):
	if _ui_needs_sync:
		_sync_ui()

func queue_ui_sync():
	_ui_needs_sync = true

func _sync_ui():
	_ui_needs_sync = false
	if world == null:
		return
	
	# grow/shrink the UI's list of object to match objects in world
	var objects = world.objects.get_children()
	var do_adds = grid.get_child_count() < len(objects)
	while len(objects) != grid.get_child_count():
		if do_adds:
			var new_item := Button.new()
			grid.add_child(new_item)
		else:
			grid.remove_child(grid.get_child(grid.get_child_count() - 1))
	
	# update UI's labels to match names of objects in world
	for idx in range(len(objects)):
		var obj = objects[idx]
		var button : Button = grid.get_child(idx)
		button.text = obj.user_label
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT

func _shift_object(dir):
	var focus_owner = get_viewport().gui_get_focus_owner()
	var from_idx = -1
	for idx in range(grid.get_child_count()):
		var control : Control = grid.get_child(idx)
		if control == focus_owner:
			from_idx = idx
			break
	
	if from_idx < 0:
		return # nothing to shift
	
	var to_idx = from_idx + dir
	if world and world.reorder_world_object(from_idx, to_idx):
		grid.get_child(to_idx).grab_focus()

func _on_world_child_entered_tree(_node: Node):
	queue_ui_sync()

func _on_world_child_exiting_tree(_node: Node):
	queue_ui_sync()

func _on_world_child_order_changed():
	queue_ui_sync()

func _on_down_button_pressed():
	_shift_object(+1)
	queue_ui_sync()

func _on_up_button_pressed():
	_shift_object(-1)
	queue_ui_sync()
