extends PanelContainer
class_name Main

@export var ProjectEditorScene : PackedScene = null
@export var BootMenuScene      : PackedScene = null

var root_scene : Control = null

func _ready():
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	open_boot_menu()

func open_boot_menu():
	swap_root_scene(
		BootMenuScene.instantiate() as Control,
		DisplayServer.WINDOW_MODE_WINDOWED,
		Vector2(1000, 400))

func open_project_editor(project_path: String):
	swap_root_scene(
		ProjectEditorScene.instantiate() as Control,
		DisplayServer.WINDOW_MODE_MAXIMIZED,
		Vector2(1280, 720))
	TheProject.open(project_path)

func swap_root_scene(new_scene: Control, window_mode: int, preferred_size: Vector2) -> void:
	_release_root_scene()
	root_scene = new_scene
	add_child(root_scene)
	get_window().size = preferred_size
	DisplayServer.window_set_mode(window_mode)
	if window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		get_window().move_to_center()

func _release_root_scene() -> void:
	# restore default auto-close behavior when switching scenes
	get_tree().set_auto_accept_quit(true)
	if root_scene:
		remove_child(root_scene)
		root_scene.queue_free()
