extends Node2D

## Vida: cuántos golpes de slash aguanta antes de morir.
@export var hits_to_die: int = 2

## Escena del proyectil a disparar.
@export var projectile_scene: PackedScene

## Tiempo entre disparos (segundos).
@export var fire_interval: float = 2.0

## Duración de la fase de carga (se pone rojo vivo). Debe ser < fire_interval.
@export var charge_time: float = 0.9

## Tiempo que el cañón deja de apuntar tras disparar.
@export var aim_lockout_time: float = 0.6

## Punto desde donde sale el proyectil (hijo del nodo del cañón).
@export var muzzle: Node2D

## Nodo del cañón que rota para apuntar (ej: Sprite2D del cañón).
@export var cannon_pivot: Node2D

## Sprite del cañón, para el feedback de color.
@export var cannon_sprite: Sprite2D

## Colores del feedback de carga.
@export var idle_color: Color = Color(1, 1, 1, 1)
@export var charging_color: Color = Color(1, 0.15, 0.1, 1)  # rojo vivo
@export var dead_color: Color = Color(0.3, 0.3, 0.3, 1)
@export var turn_speed: float = 4.0 

## Grupo al que pertenece (para el slash controller).
@export var enemy_group: String = "enemies"

@onready var _player: Node2D = null

var _hp: int
var _fire_timer: float = 0.0
var _charge_timer: float = 0.0
var _aim_lockout_timer: float = 0.0
var _is_charging: bool = false
var _is_dead: bool = false


func _ready() -> void:
	_hp = hits_to_die
	add_to_group(enemy_group)
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		# fallback: busca cualquier CharacterBody2D con take_hit
		for n in get_tree().get_nodes_in_group("player"):
			_player = n
			break
	# Comenzar el ciclo de disparo
	_fire_timer = fire_interval


func _process(delta: float) -> void:
	if _is_dead:
		return

	# Reintentar encontrar al jugador si es null o si fue liberado
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
		print("[Turret] re-buscando player -> ", _player)

	_update_aim(delta)
	_update_fire_cycle(delta)
	
func _find_player() -> Node2D:
	# 1) por grupo
	var p = get_tree().get_first_node_in_group("player")
	if p:
		return p
	# 2) fallback: cualquier CharacterBody2D con take_hit
	for n in get_tree().current_scene.find_children("*", "CharacterBody2D", true, false):
		if n.has_method("take_hit"):
			return n
	return null
# ---------- Apuntado ----------

func _update_aim(delta: float) -> void:
	
	if _aim_lockout_timer > 0.0:
		_aim_lockout_timer -= delta
		return

	if _player == null or not is_instance_valid(_player):
		return
	if cannon_pivot == null:
		return

	var to_player := _player.global_position - cannon_pivot.global_position
	var target_angle := to_player.angle()
	cannon_pivot.rotation = lerp_angle(cannon_pivot.rotation, target_angle, turn_speed * delta)
	if to_player.length_squared() < 0.001:
		return
	cannon_pivot.rotation = lerp_angle(cannon_pivot.rotation, target_angle, turn_speed * delta)
	print("[AIM] player_pos=", _player.global_position,
		" pivot_pos=", cannon_pivot.global_position,
		" rot=", rad_to_deg(cannon_pivot.rotation))


# ---------- Ciclo de disparo ----------

func _update_fire_cycle(delta: float) -> void:
	_fire_timer -= delta

	# Fase de carga (solo si aún no estamos cargando y quedan charge_time)
	if not _is_charging and _fire_timer <= charge_time:
		_is_charging = true
		_charge_timer = 0.0

	if _is_charging:
		_charge_timer += delta
		# Progreso 0..1 de la carga
		var t: float = clamp(_charge_timer / charge_time, 0.0, 1.0)
		_update_charge_feedback(t)

	# Momento de disparar
	if _fire_timer <= 0.0:
		_fire()
		_fire_timer = fire_interval
		_is_charging = false
		_charge_timer = 0.0
		_aim_lockout_timer = aim_lockout_time
		_reset_cannon_color()


func _update_charge_feedback(t: float) -> void:
	if cannon_sprite == null:
		return
	# Interpolar de idle_color a charging_color según la carga
	cannon_sprite.modulate = idle_color.lerp(charging_color, t)


func _reset_cannon_color() -> void:
	if cannon_sprite:
		cannon_sprite.modulate = idle_color


# ---------- Disparo ----------

func _fire() -> void:
	if projectile_scene == null:
		return

	# Si no hay jugador, dispara hacia donde apunta el cañón
	var target: Vector2
	if _player != null:
		target = _player.global_position
	else:
		target = cannon_pivot.global_position + Vector2.RIGHT.rotated(cannon_pivot.rotation) * 100.0

	var spawn_pos: Vector2 = muzzle.global_position if muzzle != null else cannon_pivot.global_position

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.launch(spawn_pos, target)


# ---------- Recibir daño (lo llama el SlashController) ----------

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
	# Aquí puedes instanciar partículas / sonido / drops
	queue_free()
