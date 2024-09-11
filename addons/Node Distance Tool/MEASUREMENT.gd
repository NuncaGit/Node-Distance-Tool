@tool
extends EditorPlugin

var selected_node : Node = null  # Stores the first selected node
var PainelMetragem
const METRAGEM = preload("res://addons/Node Distance Tool/Metragem.tscn")

func _enter_tree():
		# Verifica se a ação já foi registrada antes de adicionar novamente
	if not InputMap.has_action("measure_node_shortcut"):
		# Criar o atalho de medição (Q) e associá-lo diretamente ao InputMap
		var measure_shortcut = InputEventKey.new()
		measure_shortcut.keycode = Key.KEY_Q
		InputMap.add_action("measure_node_shortcut", true)
		InputMap.action_add_event("measure_node_shortcut", measure_shortcut)


	PainelMetragem = METRAGEM.instantiate()
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, PainelMetragem)
	PainelMetragem.plugin = self

func _process(delta):
	# Detect when the "M" shortcut is pressed
	if Input.is_action_just_pressed("measure_node_shortcut"):
		measure_or_select_node()

func measure_or_select_node():
	var selected_nodes = get_selected_nodes()
	
	if selected_nodes.size() > 0:
		var current_node = selected_nodes[0]  # Currently selected node

		if selected_node == null:
			# First time pressing 'M', saving the first node
			selected_node = current_node
			print_rich("First node selected: [color=yellow]" + selected_node.name + "[/color]")
		elif selected_node != current_node:
			# Second time pressing 'M', measure the distance between the nodes
			measure_distance(selected_node, current_node)
			selected_node = null  # Reset to allow starting a new cycle
		else:
			# If the selected node is the same as the previous, replace the saved node
			selected_node = current_node
			print_rich("Selected node was the same as the previous one. Replacing the saved node: [color=yellow]" + selected_node.name + "[/color]")
	else:
		print_rich("No node is selected at the moment")

func measure_distance(node1, node2):
	# Check if the nodes are different
	if node1 == node2:
		print_rich("It is not possible to measure the distance between the same node.")
		return
	
	# Calculate the full distance (maximum precision)
	var distance = node1.global_transform.origin.distance_to(node2.global_transform.origin)
	
	# Display the full distance in the script log
	print_rich("Distance between [color=yellow]" + node1.name + "[/color] and [color=yellow]" + node2.name + "[/color] is [color=cyan]" + str(distance) + " meters[/color]")

	# Display the rounded distance in the label (2 decimal places)
	var rounded_distance = "%.2f" % distance
	draw_line_between_nodes(node1, node2, rounded_distance)

func draw_line_between_nodes(node1, node2, distance):
	# Create a line between the two nodes
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_add_vertex(node1.to_local(node2.global_transform.origin))
	mesh.surface_end()

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.transform.origin = Vector3.ZERO
	node1.add_child(mesh_instance)
	mesh_instance.add_to_group("lines")

	# Create the rounded distance label (with 2 decimal places)
	var label = Label3D.new()
	label.text = str(distance) + "m"
	label.transform.origin = (node1.global_transform.origin + node2.global_transform.origin) / 2
	label.add_to_group("labels")
	get_tree().root.add_child(label)

func get_selected_nodes():
	var selection = get_editor_interface().get_selection()
	if selection:
		return selection.get_selected_nodes()
	return []

func reset():
	# Remove all lines and labels created by the addon
	var all_lines = get_tree().get_nodes_in_group("lines")
	for line in all_lines:
		if line is MeshInstance3D and line.mesh is ImmediateMesh:
			line.queue_free()
	
	var all_labels = get_tree().get_nodes_in_group("labels")
	for label in all_labels:
		label.queue_free()

	print_rich("All lines and labels have been removed.")

func _exit_tree():
	remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, PainelMetragem)
	# Remove the shortcuts when exiting the plugin
	InputMap.erase_action("measure_node_shortcut")
