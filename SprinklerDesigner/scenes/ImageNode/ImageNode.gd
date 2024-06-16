extends MoveableNode2D
class_name ImageNode

@onready var texture_rect := $TextureRect

var filename : String = ""

func _ready():
	if TheProject.is_opened():
		var img = TheProject.load_image(filename)
		if img is Image:
			texture_rect.texture = ImageTexture.create_from_image(img)

func _draw():
	if show_indicator:
		draw_rect(Rect2(Vector2(), get_img_size()), Color.YELLOW, false, 4)

func get_img_size() -> Vector2:
	return texture_rect.size

func serialize():
	var position_ft = Utils.px_to_ft_vec(position)
	return {
		'filename' : filename,
		'position_ft' : [position_ft.x, position_ft.y]
	}

func deserialize(obj):
	filename = obj['filename']
	var pos_ft = obj['position_ft']
	position = Vector2(Utils.ft_to_px(pos_ft[0]), Utils.ft_to_px(pos_ft[1]))
