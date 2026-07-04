@tool
extends EditorPlugin

var loader: GCodeFormatLoader

func _enter_tree() -> void:
	loader = GCodeFormatLoader.new()
	ResourceLoader.add_resource_format_loader(loader)

func _exit_tree() -> void:
	ResourceLoader.remove_resource_format_loader(loader)
	loader = null
