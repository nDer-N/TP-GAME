extends Control

## Escena del ícono. Debe contener un AnimatedSprite2D con animaciones "full" y "empty".
@export var icon_scene: PackedScene

## Nombre de la animación cuando el ícono está lleno.
@export var full_animation: String = "full"

## Nombre de la animación cuando el ícono está vacío.
@export var empty_animation: String = "empty"

## Tamaño del espacio reservado para cada ícono (no del sprite en sí).
@export var icon_size: Vector2 = Vector2(32, 32)

## Separación horizontal entre íconos.
@export var icon_spacing: float = 4.0

var icons: Array[AnimatedSprite2D] = []


func setup(max_hits: int) -> void:
	for child in get_children():
		child.queue_free()
	icons.clear()

	if icon_scene == null:
		push_warning("HitsDisplay: icon_scene no asignada.")
		return

	for i in max_hits:
		var icon: AnimatedSprite2D = icon_scene.instantiate()
		# Centrar el sprite en el espacio asignado:
		# el primer ícono arranca en (0,0) y el centro está en (icon_size/2).
		icon.position = Vector2(
			(icon_size.x + icon_spacing) * i + icon_size.x * 0.5,
			icon_size.y * 0.5
		)
		add_child(icon)
		icon.play(full_animation)
		icons.append(icon)


func update_hits(current_hits: int) -> void:
	var total := icons.size()
	for i in total:
		# Derecha a izquierda: los últimos índices se vacían primero
		var should_be_empty: bool = i >= total - current_hits
		var target_anim: String = empty_animation if should_be_empty else full_animation
		# Solo cambiar si es distinto (evita reiniciar la animación cada frame)
		if icons[i].animation != target_anim:
			icons[i].play(target_anim)
