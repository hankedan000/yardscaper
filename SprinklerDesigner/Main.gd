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
	if root_scene is BootMenu:
		root_scene.popup_centered()

func open_project_editor(project_path: String):
	_release_root_scene()
	root_scene = ProjectEditorScene.instantiate()
	add_child(root_scene)
	TheProject.open(project_path)

func _release_root_scene():
	if root_scene:
		remove_child(root_scene)
		root_scene.queue_free()
