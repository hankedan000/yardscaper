extends PanelContainer
class_name Main

@export var ProjectEditorScene : PackedScene = null
@export var BootMenuScene      : PackedScene = null

var root_scene : Node = null

func _ready():
	open_boot_menu()

func open_boot_menu():
	_release_root_scene()
	root_scene = BootMenuScene.instantiate()
	add_child(root_scene)
	get_window().size = Vector2(800,400)
	get_window().move_to_center()

func open_project_editor(project_path: String):
	_release_root_scene()
	root_scene = ProjectEditorScene.instantiate()
	add_child(root_scene)
	TheProject.open(project_path)
	get_window().size = Vector2(1280,720)
	get_window().move_to_center()

func _release_root_scene():
	# restore default auto-close behavior when switching scenes
	get_tree().set_auto_accept_quit(true)
	if root_scene:
		remove_child(root_scene)
		root_scene.queue_free()
