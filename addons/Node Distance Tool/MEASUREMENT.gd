@tool
extends EditorPlugin

var selected_node : Node = null  # Armazena o primeiro nó selecionado
var PainelMetragem
const METRAGEM = preload("res://addons/Node Distance Tool/Metragem.tscn")

# Variáveis de controle
var enable_visualization: bool = true  # Controla se as linhas e labels devem ser desenhadas
var continuous_mode: bool = false  # Controla o modo contínuo
var togheter_mode: bool = false  # Controla o modo "togheter"
var node_pair := []  # Armazena os nós para o modo "togheter"
var previous_positions := []  # Armazena as posições anteriores dos nós no modo "togheter"
var update_timer: Timer  # Timer para o modo "togheter"
var auto_update_mode: bool = false  # Controla se o modo "togheter" está ativo
var togheter_lines_and_labels := []  # Armazena as linhas e labels do modo "togheter"

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
	# Detecta quando o atalho "Q" é pressionado
	if Input.is_action_just_pressed("measure_node_shortcut"):
		measure_or_select_node()

func measure_or_select_node():
	var selected_nodes = get_selected_nodes()

	if selected_nodes.size() > 0:
		var current_node = selected_nodes[0]  # Atualmente selecionado

		if togheter_mode:
			node_pair.append(current_node)

			if node_pair.size() >= 2:
				start_auto_update_mode()  # Iniciar o cálculo contínuo entre os nós

			print_rich("Node [color=yellow]" + current_node.name + "[/color] [color=green]added[/color] to togheter mode.")
		elif continuous_mode:
			if selected_node == null:
				selected_node = current_node
			else:
				# Apaga a linha e o label anteriores antes de calcular a nova distância
				reset_previous_visuals()
				measure_distance(selected_node, current_node)
				selected_node = current_node  # O segundo nó se torna o primeiro
		else:
			if selected_node == null:
				selected_node = current_node
				print_rich("First node selected: [color=yellow]" + selected_node.name + "[/color]")
			elif selected_node != current_node:
				measure_distance(selected_node, current_node)
				selected_node = null  # Reset para iniciar novo ciclo
	else:
		print_rich("No node is selected at the moment")

func measure_distance(node1, node2):
	if node1 == node2:
		print_rich("It is not possible to measure the distance between the same node.")
		return
	
	# Cálculo da distância total
	var distance = node1.global_transform.origin.distance_to(node2.global_transform.origin)
	print_rich("Distance between [color=yellow]" + node1.name + "[/color] and [color=yellow]" + node2.name + "[/color] is [color=cyan]" + str(distance) + " meters[/color]")

	# Arredondar a distância para 2 casas decimais
	var rounded_distance = "%.2f" % distance

	# Desenhar linha e labels somente se a visualização estiver habilitada
	draw_line_between_nodes(node1, node2, rounded_distance)

func draw_line_between_nodes(node1, node2, distance):
	if not enable_visualization:
		return  # Se a visualização estiver desabilitada, apenas retorna

	# Criação da linha entre os dois nós
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

	# Criação da label com a distância arredondada
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
	# Remove todas as linhas e labels criadas pelo addon
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
	# Remove os atalhos ao sair do plugin
	InputMap.erase_action("measure_node_shortcut")
	
	reset_measurement_visuals()

func start_auto_update_mode():
	if node_pair.size() >= 2:
		previous_positions = [node_pair[0].global_transform.origin, node_pair[1].global_transform.origin]

		# Criar o timer para verificar a posição a cada 0.1 segundos
		if not update_timer:
			update_timer = Timer.new()
			update_timer.wait_time = 0.1
			update_timer.one_shot = false
			update_timer.connect("timeout", Callable(self, "_check_node_movement"))
			add_child(update_timer)

		auto_update_mode = true
		update_timer.start()
		print_rich("Auto-update started between [color=yellow]" + node_pair[0].name + "[/color] and [color=yellow]" + node_pair[1].name + "[/color].")
	else:
		print_rich("[color=red]You need to select at least two nodes for togheter mode.[/color]")

func _check_node_movement():
	if node_pair.size() >= 2 and auto_update_mode:
		var current_positions = []
		for node in node_pair:
			current_positions.append(node.global_transform.origin)

		# Se qualquer nó se mover, recalculamos as distâncias para os pares conectados
		if current_positions != previous_positions:
			# Remove linhas e labels antigas
			reset_measurement_visuals()

			# Recalcula as distâncias entre todos os pares de nós
			for i in range(node_pair.size()):
				var node1 = node_pair[i]
				for j in range(i + 1, node_pair.size()):
					var node2 = node_pair[j]

					# Calcula a distância exata
					var distance = node1.global_transform.origin.distance_to(node2.global_transform.origin)
					
					# Arredonda a distância apenas para exibição no label
					var rounded_distance = "%.2f" % distance

					# Desenha a linha e o label novamente entre os nós
					draw_line_between_nodes(node1, node2, rounded_distance)

					# Exibe a distância precisa no print_rich (não arredondada)
					print_rich("Distance between [color=yellow]" + node1.name + "[/color] and [color=yellow]" + node2.name + "[/color] is [color=cyan]" + str(distance) + " meters[/color]")

			previous_positions = current_positions

func reset_togheter_mode():
	node_pair.clear()
	if update_timer:
		update_timer.stop()
	reset_measurement_visuals()

func reset_measurement_visuals():
	# Remove todas as linhas e labels criadas pelo addon
	var all_lines = get_tree().get_nodes_in_group("lines")
	for line in all_lines:
		line.queue_free()

	var all_labels = get_tree().get_nodes_in_group("labels")
	for label in all_labels:
		label.queue_free()

func reset_previous_visuals():
	if continuous_mode:
		# Remove a linha e o label do cálculo anterior
		var all_lines = get_tree().get_nodes_in_group("lines")
		for line in all_lines:
			line.queue_free()

		var all_labels = get_tree().get_nodes_in_group("labels")
		for label in all_labels:
			label.queue_free()
