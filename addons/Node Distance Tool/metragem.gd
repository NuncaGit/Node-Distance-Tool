@tool
extends VBoxContainer

var plugin : EditorPlugin


func _on_button_reset_pressed():
	if plugin:
		plugin.reset()
