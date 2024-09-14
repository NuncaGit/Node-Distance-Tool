@tool
extends HBoxContainer

var plugin : EditorPlugin
@onready var h_config = $HBoxConfig

func _on_button_reset_pressed():
	if plugin:
		plugin.reset()
		if plugin.togheter_mode:
			plugin.reset_togheter_mode()

func _on_button_config_pressed():
	if h_config.is_visible():
		h_config.hide()
	else:
		h_config.show()

func _on_button_lines_labels_toggled(toggled_on):
	if toggled_on:
		plugin.enable_visualization = true
		print_rich("Line and label creation is [color=aqua]ON" + "[/color]")
	else:
		plugin.enable_visualization = false
		plugin.reset()
		print_rich("Line and label creation is [color=red]OFF" + "[/color]")

func _on_button_continuos_mode_toggled(toggled_on):
	if toggled_on:
		plugin.continuous_mode = true
		print_rich("Continuous mode is [color=aqua]ON" + "[/color]")
	else:
		plugin.continuous_mode = false
		print_rich("Continuous mode is [color=red]OFF" + "[/color]")

func _on_button_togheter_mode_toggled(toggled_on):
	if toggled_on:
		plugin.togheter_mode = true
		print_rich("Togheter mode is [color=aqua]ON" + "[/color]")
	else:
		plugin.auto_update_mode = false
		plugin.togheter_mode= false
		plugin.reset_togheter_mode()
		print_rich("Togheter mode is [color=red]OFF" + "[/color]")
