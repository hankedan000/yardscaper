extends PanelContainer

@onready var item_list := $ItemList

var _ui_needs_sync = false

func _ready():
	TheProject.opened.connect(_on_TheProject_opened)
	TheProject.closed.connect(_on_TheProject_closed)
	TheProject.node_changed.connect(_on_TheProject_node_changed)

func _process(_delta):
	if _ui_needs_sync:
		_sync_ui()

func queue_ui_sync():
	_ui_needs_sync = true

func _sync_ui():
	_ui_needs_sync = false
	
	var parts_map = Dictionary()
	for obj in TheProject.objects:
		if obj is Sprinkler:
			var key = [obj.manufacturer, obj.model]
			if key in parts_map:
				parts_map[key]['count'] += 1
			else:
				parts_map[key] = {
					'count' : 1
				}
	
	clear_rows()
	for key in parts_map.keys():
		var entry = parts_map[key]
		item_list.add_item(key[0]) # manufacturer
		item_list.add_item(key[1]) # model
		item_list.add_item(str(entry['count']))

func row_count(include_header=false) -> int:
	var rows = int(item_list.item_count / item_list.max_columns)
	if not include_header:
		rows -= 1
	return rows

func clear_rows():
	while row_count() > 0:
		remove_row(0)

# remove non-header rows from table (idx 0 is first non-header row)
func remove_row(row_idx: int):
	if row_idx >= row_count():
		push_error("row_idx (%d) >= row_count (%d)" % [row_idx, row_count()])
		return
	
	var num_cols = item_list.max_columns
	var start_idx = num_cols + (row_idx * num_cols)
	for col_idx in range(num_cols):
		item_list.remove_item(start_idx)

func _on_TheProject_opened():
	queue_ui_sync()

func _on_TheProject_closed():
	queue_ui_sync()

func _on_TheProject_node_changed(_node, _change_type, _args):
	queue_ui_sync()
