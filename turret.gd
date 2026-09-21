extends Node2D

## Vida: cuántos golpes de slash aguanta antes de morir.
@export var hits_to_die: int = 2

## Escena del proyectil a disparar.
@export var projectile_scene: PackedScene

## Tiempo entre disparos (segundos).
@export var fire_interval: float = 2.0

## Duración de la fase de carga (se pone rojo vivo). Debe ser < fire_interval.
@export var charge_time: float = 0.9

## Punto desde donde sale el proyectil (hijo del nodo del cañón).
@export var muzzle: Node2D

## Nodo del cañón que rota para apuntar.
@export var cannon_pivot: Node2D

## Sprite del cañón, para el feedback de color.
@export var cannon_sprite: Sprite2D

## Velocidad de apuntado suavizado (mayor = más rápido).
@export var turn_speed: float = 4.0

## Colores del feedback de carga.
@export var idle_color: Color = Color(1, 1, 1, 1)
@export var charging_color: Color = Color(1, 0.15, 0.1, 1)
@export var dead_color: Color = Color(0.3, 0.3, 0.3, 1)

## Grupo al que pertenece (para el slash controller).
@export var enemy_group: String = "enemies"

## Si es true, la torreta solo apunta/dispara cuando el jugador está dentro del DetectionArea.
@export var aim_only_when_detected: bool = true

## Delay antes de activarse al detectar al jugador (segundos).
@export var activation_delay: float = 0.2

@onready var detection_area: Area2D = $DetectionArea

var _player: Node2D = null
var _hp: int
var _fire_timer: float = 0.0
var _charge_timer: float = 0.0
var _is_charging: bool = false
var _is_dead: bool = false

var _player_in_range: bool = false
var _activation_timer: float = 0.0
var _is_active: bool = false


func _ready() -> void:
	_hp = hits_to_die
	add_to_group(enemy_group)

	# Buscar jugador
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		await get_tree().process_frame
		_player = get_tree().get_first_node_in_group("player")

	# Conectar área de detección
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)

	# Empezar el ciclo
	_fire_timer = fire_interval


func _process(delta: float) -> void:
	if _is_dead:
		return

	# Reintentar encontrar al jugador si es null o fue liberado
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()

	# --- Activar / desactivar según detección ---
	if _player_in_range:
		_activation_timer += delta
		if _activation_timer >= activation_delay:
			_is_active = true
	else:
		_activation_timer = 0.0
		if _is_active:
			_is_active = false
			# Cancelar cualquier carga en curso
			_fire_timer = fire_interval
			_is_charging = false
			_charge_timer = 0.0
			_reset_cannon_color()

	# Si no está activa y la opción está activada, no procesar nada
	if aim_only_when_detected and not _is_active:
		return

	_update_aim(delta)
	_update_fire_cycle(delta)


func _find_player() -> Node2D:
	var p = get_tree().get_first_node_in_group("player")
	if p:
		return p
	# Fallback: cualquier CharacterBody2D con take_hit
	for n in get_tree().current_scene.find_children("*", "CharacterBody2D", true, false):
		if n.has_method("take_hit"):
			return n
	return null


# ---------- Apuntado ----------

func _update_aim(delta: float) -> void:
	# No apuntar mientras carga (da ventana de reacción al jugador)
	if _is_charging:
		return

	if _player == null or not is_instance_valid(_player):
		return
	if cannon_pivot == null:
		return

	var to_player := _player.global_position - cannon_pivot.global_position
	if to_player.length_squared() < 0.001:
		return

	var target_angle := to_player.angle()
	cannon_pivot.rotation = lerp_angle(cannon_pivot.rotation, target_angle, turn_speed * delta)


# ---------- Ciclo de disparo ----------

func _update_fire_cycle(delta: float) -> void:
	_fire_timer -= delta

	# Fase de carga
	if not _is_charging and _fire_timer <= charge_time:
		_is_charging = true
		_charge_timer = 0.0

	if _is_charging:
		_charge_timer += delta
		var t: float = clamp(_charge_timer / charge_time, 0.0, 1.0)
		_update_charge_feedback(t)

	# Momento de disparar
	if _fire_timer <= 0.0:
		_fire()
		_fire_timer = fire_interval
		_is_charging = false
		_charge_timer = 0.0
		_reset_cannon_color()


func _update_charge_feedback(t: float) -> void:
	if cannon_sprite == null:
		return
	cannon_sprite.modulate = idle_color.lerp(charging_color, t)


func _reset_cannon_color() -> void:
	if cannon_sprite:
		cannon_sprite.modulate = idle_color


# ---------- Disparo ----------

func _fire() -> void:
	if projectile_scene == null:
		return
	if cannon_pivot == null:
		return

	var target: Vector2
	if _player != null and is_instance_valid(_player):
		target = _player.global_position
	else:
		target = cannon_pivot.global_position + Vector2.RIGHT.rotated(cannon_pivot.rotation) * 100.0

	var spawn_pos: Vector2 = muzzle.global_position if muzzle != null else cannon_pivot.global_position

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.launch(spawn_pos, target)


# ---------- Detección ----------

func _on_detection_body_entered(body: Node2D) -> void:
	if not body.has_method("take_hit"):
		return
	_player_in_range = true


func _on_detection_body_exited(body: Node2D) -> void:
	if not body.has_method("take_hit"):
		return
	_player_in_range = false


# ---------- Recibir daño ----------

func take_damage(amount: int, _hit_direction: Vector2 = Vector2.ZERO) -> void:
	if _is_dead:
		return
	_hp -= amount
	if _hp <= 0:
		die()


func die() -> void:
	_is_dead = true
	if cannon_sprite:
		cannon_sprite.modulate = dead_color
	queue_free()
