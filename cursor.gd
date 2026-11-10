extends Node2D


func _ready() -> void:
	# Sigue funcionando mientras el juego está en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if get_tree().paused:
		# En pausa: se oculta el cursor del juego y se muestra el ratón normal
		visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		visible = true
		global_position = get_global_mouse_position()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
