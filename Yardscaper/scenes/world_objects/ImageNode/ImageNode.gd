extends WorldObject
class_name ImageNode

const PROP_KEY_WIDTH_FT = &"width_ft"
const PROP_KEY_HEIGHT_FT = &"height_ft"

@onready var texture_rect := $TextureRect
@onready var draw_layer := $ManualDrawLayer

var filename : String = ""

var width_ft : float = 0:
	set(value):
		var old_value = width_ft
		width_ft = value
		_check_and_emit_prop_change(PROP_KEY_WIDTH_FT, old_value)
		if texture_rect:
			texture_rect.size.x = Utils.ft_to_px(value)
			queue_redraw()
		_sync_pick_area_size()

var height_ft : float = 0:
	set(value):
		var old_value = height_ft
		height_ft = value
		_check_and_emit_prop_change(PROP_KEY_HEIGHT_FT, old_value)
		if texture_rect:
			texture_rect.size.y = Utils.ft_to_px(value)
			queue_redraw()
		_sync_pick_area_size()

func _ready():
	super._ready()
	if TheProject.is_opened():
		var img = TheProject.load_image(filename)
		if img is Image:
			texture_rect.texture = ImageTexture.create_from_image(img)
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			if width_ft == 0 and height_ft == 0:
				width_ft = Utils.px_to_ft(img.get_width())
				height_ft = Utils.px_to_ft(img.get_height())
			else:
				texture_rect.size.x = Utils.ft_to_px(width_ft)
				texture_rect.size.y = Utils.ft_to_px(height_ft)
	
	# change pick shape to a rectangle (default is ellipse)
	pick_coll_shape.shape = RectangleShape2D.new()
	_sync_pick_area_size()

func _draw():
	draw_layer.queue_redraw()

func get_visual_center() -> Vector2:
	return global_position + (img_size_px() / 2.0)

func img_size_px() -> Vector2:
	return texture_rect.size

func get_subclass() -> String:
	return "ImageNode"

func serialize():
	var obj = super.serialize()
	obj['filename'] = filename
	obj[PROP_KEY_WIDTH_FT] = width_ft
	obj[PROP_KEY_HEIGHT_FT] = height_ft
	return obj

func deserialize(obj):
	super.deserialize(obj)
	filename = obj['filename']
	width_ft = DictUtils.get_w_default(obj, PROP_KEY_WIDTH_FT, 0)
	height_ft = DictUtils.get_w_default(obj, PROP_KEY_HEIGHT_FT, 0)

func _sync_pick_area_size():
	if not pick_coll_shape or not texture_rect:
		return
	
	var rect_shape := pick_coll_shape.shape as RectangleShape2D
	if rect_shape:
		rect_shape.size = texture_rect.size
		pick_area.position = texture_rect.size / 2.0
