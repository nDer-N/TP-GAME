extends Sprite2D

func _ready():
	# Oculta el cursor por defecto del sistema
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(delta):
	# Sigue la posición global del mouse en cada fotograma
	global_position = get_global_mouse_position()
