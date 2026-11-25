extends Control

@export_group("Escenas")
@export var head_scene: PackedScene
@export var fire_scene: PackedScene

@export_group("Animaciones")
@export var full_animation: String = "full"
@export var empty_animation: String = "empty"

@export_group("Layout")
## Escala de la cabeza.
@export var head_scale: float = 1.0
## Escala del primer fuego (independiente de la cabeza).
@export var first_fire_scale: float = 1.0
## Cada fuego siguiente se multiplica por este valor (0.9 = 10% más chico).
@export_range(0.1, 1.0, 0.01) var fire_scale_falloff: float = 0.9
## Posición del CENTRO de cada ícono, relativa al nodo Icons. Índice 0 = cabeza.
@export var icon_positions: Array[Vector2] = [
	Vector2(0, 0),
	Vector2(170, -20),
	Vector2(258, -5),
	Vector2(342, 5),
]
## Si hay más íconos que posiciones, el resto se coloca sumando este paso a la anterior.
@export var default_step: Vector2 = Vector2(85, 0)
## Desplazamiento de todo el grupo de íconos.
@export var icons_offset: Vector2 = Vector2.ZERO

@export_group("Efectos")
@export var pop_on_change: bool = true
@export_range(0.0, 0.5, 0.01) var fire_speed_variation: float = 0.15

var icons_root: Node2D
var icons: Array[AnimatedSprite2D] = []


func setup(max_hits: int) -> void:
	icons_root = get_node_or_null("Icons") as Node2D
	if icons_root == null:
		push_error("HitsDisplay: falta un nodo hijo Node2D llamado 'Icons'.")
		return

	for child in icons_root.get_children():
		child.queue_free()
	icons.clear()

	if head_scene == null or fire_scene == null:
		push_warning("HitsDisplay: head_scene o fire_scene no asignada.")
		return

	var last_pos := Vector2.ZERO

	for i in max_hits:
		var is_head := i == 0
		var icon: AnimatedSprite2D = (head_scene if is_head else fire_scene).instantiate()

		# Escala: cabeza fija, fuegos decreciendo.
		var s: float
		if is_head:
			s = head_scale
		else:
			s = first_fire_scale * pow(fire_scale_falloff, i - 1)
		icon.scale = Vector2(s, s)
		icon.set_meta("base_scale", icon.scale)

		# Posición manual; si no hay una definida, se extrapola.
		var pos: Vector2
		if i < icon_positions.size():
			pos = icon_positions[i]
		else:
			pos = last_pos + default_step
		last_pos = pos
		icon.position = pos + icons_offset

		icons_root.add_child(icon)
		_play(icon, full_animation, not is_head)
		icons.append(icon)


func update_hits(current_hits: int) -> void:
	var total := icons.size()
	for i in total:
		# Derecha a izquierda: los últimos índices se vacían primero.
		var should_be_empty: bool = i >= total - current_hits
		var target_anim: String = empty_animation if should_be_empty else full_animation

		if icons[i].animation != target_anim:
			_play(icons[i], target_anim, i > 0)
			if pop_on_change:
				_pop(icons[i])


## Reproduce una animación; si desync = true, arranca en un frame aleatorio.
func _play(icon: AnimatedSprite2D, anim: String, desync: bool) -> void:
	icon.play(anim)
	if not desync:
		return
	var frame_count := icon.sprite_frames.get_frame_count(anim)
	icon.frame = randi() % frame_count
	icon.frame_progress = randf()
	icon.speed_scale = 1.0 + randf_range(-fire_speed_variation, fire_speed_variation)


func _pop(icon: AnimatedSprite2D) -> void:
	var base: Vector2 = icon.get_meta("base_scale")
	icon.scale = base * 1.3
	var tween := create_tween()
	tween.tween_property(icon, "scale", base, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
