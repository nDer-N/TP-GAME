extends Node2D

## Nodo al que sigue este orbe (normalmente el jugador).
@export var follow_target: Node2D = null

## Offset desde el target (en píxeles, se flipea con el sprite).
@export var offset: Vector2 = Vector2(-30, 0)

## Sprite del jugador para detectar flip_h y espejar el offset.
@export var sprite_to_check_flip: AnimatedSprite2D = null

## Velocidad de seguimiento (mayor = más pegado, menor = más arrastra).
@export var follow_speed: float = 10.0

## Efecto de flotado (bob) para que se vean orgánicos.
@export var bob_amplitude: float = 3.0
@export var bob_speed: float = 3.0

## Variación inicial para que no floten todos en fase.
@export var bob_phase_offset: float = 0.0

var _bob_phase: float = 0.0


func _process(delta: float) -> void:
	if follow_target == null or not is_instance_valid(follow_target):
		return

	_bob_phase += delta * bob_speed

	# Calcular posición objetivo
	var target_offset := offset
	if sprite_to_check_flip and sprite_to_check_flip.flip_h:
		target_offset.x *= -1.0

	var target_pos := follow_target.global_position + target_offset
	target_pos.y += sin(_bob_phase + bob_phase_offset) * bob_amplitude

	# Lerp independiente del framerate
	var t := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(target_pos, t)


## Snap inmediato — se llama después del TP para que no queden atrás.
func snap_to_target() -> void:
	if follow_target == null or not is_instance_valid(follow_target):
		return

	var target_offset := offset
	if sprite_to_check_flip and sprite_to_check_flip.flip_h:
		target_offset.x *= -1.0

	global_position = follow_target.global_position + target_offset
