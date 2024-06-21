extends MoveableNode2D
class_name ImageNode

@onready var texture_rect := $TextureRect

var filename : String = ""

var width_ft : float = 0:
	set(value):
		var old_value = width_ft
		width_ft = value
		if old_value != width_ft:
			emit_signal('property_changed', 'width_ft', old_value, width_ft)
		if texture_rect:
			texture_rect.size.x = Utils.ft_to_px(value)
			queue_redraw()

var height_ft : float = 0:
	set(value):
		var old_value = height_ft
		height_ft = value
		if old_value != height_ft:
			emit_signal('property_changed', 'height_ft', old_value, height_ft)
		if texture_rect:
			texture_rect.size.y = Utils.ft_to_px(value)
			queue_redraw()

func _ready():
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

func _draw():
	if show_indicator:
		draw_rect(Rect2(Vector2(), img_size_px()), Color.YELLOW, false, 4)

func img_size_px() -> Vector2:
	return texture_rect.size

func get_subclass() -> String:
	return "ImageNode"

func serialize():
	var obj = super.serialize()
	obj['filename'] = filename
	obj['width_ft'] = width_ft
	obj['height_ft'] = height_ft
	return obj

func deserialize(obj):
	super.deserialize(obj)
	filename = obj['filename']
	width_ft = Utils.dict_get(obj, 'width_ft', 0)
	height_ft = Utils.dict_get(obj, 'height_ft', 0)
