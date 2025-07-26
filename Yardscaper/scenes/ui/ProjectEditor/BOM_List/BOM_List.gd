extends PanelContainer

signal CellUpdatedSignal(columnName: String, rowIndex: Variant, celValue: Variant)
signal CellSelectedSignal(columnName: String, rowIndex: Variant)

@onready var tablePager := $TablePager

var _ui_needs_sync = false

# [{manufacturer, model, count}, ...]
var dataArray: Array[Dictionary] = []
var lastSortKey
var lastSortOrder: DataPager.EnumSortOrder

var pageSize = 15

var tableConfig:TableConfig

func _ready():
	# Tell the table how to get data and what size each page should be.
	tableConfig = TableConfig.new(
			SelectPageOfRowData, 
			GetDataCount, 
			pageSize)
	
	#######################################
	### Add some columns to the table

	var manuColumnConfig:ColumnConfig = ColumnConfig.new(
			# Set the Header widget
			TablePager.CellHeaderResource, 
			TablePager.CellLabelResource, 
			"manufacturer", 
			"row_index")
	manuColumnConfig.AddCellConfig(ColumnConfig.CELL_SELECTED_SIGNAL, CellSelectedSignal)
	tableConfig.AddColumnConfig(manuColumnConfig)

	var modelColumnConfig:ColumnConfig = ColumnConfig.new(
			# Set the Header widget
			TablePager.CellHeaderResource, 
			TablePager.CellLabelResource, 
			"model", 
			"row_index")
	modelColumnConfig.AddCellConfig(ColumnConfig.CELL_SELECTED_SIGNAL, CellSelectedSignal)
	tableConfig.AddColumnConfig(modelColumnConfig)
	
	var countColumnConfig:ColumnConfig = ColumnConfig.new(
			# Set the Header widget
			TablePager.CellHeaderResource, 
			TablePager.CellLabelResource, 
			"count", 
			"row_index")
	countColumnConfig.AddCellConfig(ColumnConfig.CELL_SELECTED_SIGNAL, CellSelectedSignal)
	tableConfig.AddColumnConfig(countColumnConfig)
	
	var dataPager: DataPager = DataPager.new(tableConfig)
	
	# Initialise the @onready variables 
	tablePager.Initialise(dataPager)
	tablePager.Render()
	
	TheProject.opened.connect(_on_TheProject_opened)
	TheProject.closed.connect(_on_TheProject_closed)
	TheProject.node_changed.connect(_on_TheProject_node_changed)

func _enter_tree():
	CellUpdatedSignal.connect(_handle_CellUpdatedSignal)
	CellSelectedSignal.connect(_handle_CellSelectedSignal)

func _exit_tree():
	CellUpdatedSignal.disconnect(_handle_CellUpdatedSignal)
	CellSelectedSignal.disconnect(_handle_CellSelectedSignal)

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
			var key = [obj.manufacturer, obj.head_model]
			if key in parts_map:
				parts_map[key]['count'] += 1
			else:
				parts_map[key] = {
					'count' : 1
				}
	
	dataArray.clear()
	var row_index = 0
	for key in parts_map.keys():
		var value = parts_map[key]
		dataArray.append({
			'manufacturer' : key[0],
			'model' : key[1],
			'count' : value['count'],
			'row_index' : row_index})
		row_index += 1
	
	tablePager.Render()

func _handle_CellSelectedSignal(_columnName: String, _rowIndex: Variant):
	pass

func _handle_CellUpdatedSignal(_columnName: String, _rowIndex: Variant, _cellValue: Variant):
	pass

func SelectPageOfRowData(_pageSize: int, pageIndex: int, sortKey: String = "", sortOrder: DataPager.EnumSortOrder = DataPager.EnumSortOrder.NONE ) -> Array[Dictionary]:
	# Fake a database lookup
	var columnKeyArray: Array = tableConfig.GetKeys()
	
	var sortParamsChanged = ( lastSortKey != sortKey || lastSortOrder != sortOrder )
	if sortKey in columnKeyArray && sortParamsChanged:
		dataArray.sort_custom( 
			# Use a Lambda so 'ascending' and 'sortKey' variables can be passed in
			func(a,b) -> bool: 
				var aValue = a[sortKey]
				var bValue = b[sortKey]
				var lessThan: bool
				if typeof(aValue) == TYPE_BOOL && typeof(bValue):
					# boolean requires special compare
					lessThan = aValue && not bValue if sortOrder else not aValue && bValue
				else:
					lessThan = aValue <= bValue if sortOrder else aValue >= bValue
				return  lessThan
		)
		lastSortOrder = sortOrder
		lastSortKey = sortKey
		
	var startIndex = pageIndex * _pageSize
	var endIndex = startIndex + _pageSize
	return dataArray.slice(startIndex, endIndex, 1, true)

func GetDataCount() -> int:
	return dataArray.size()

func _on_TheProject_opened():
	queue_ui_sync()

func _on_TheProject_closed():
	queue_ui_sync()

func _on_TheProject_node_changed(_node, _change_type, _args):
	queue_ui_sync()
