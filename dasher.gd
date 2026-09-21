extends CharacterBody2D

enum State { IDLE, ALERTED, CHARGING, DASHING, STUNNED }

## Vida: cuántos golpes de slash aguanta antes de morir.
@export var hits_to_die: int = 3

## --- Movimiento / flotado en idle ---
@export var float_amplitude: float = 6.0
@export var float_speed: float = 2.5

## --- Detección ---
@export var detection_radius: float = 220.0

## --- Dash ---
@export var charge_time: float = 0.5
@export var dash_speed: float = 780.0
@export var dash_max_time: float = 3.0

## --- Rebote ---
@export var bounce_decay: float = 0.85        # 1.0 = rebote perfecto, 0.0 = se detiene
@export var max_bounces: int = 4              # cuántos rebotes antes de aturdirse
@export var min_bounce_speed: float = 120.0   # si la velocidad tras rebotar es menor, se aturde
@export var bounce_on_player: float = 600.0   # rebote al golpear al jugador

## --- Aturdimiento ---
@export var stun_time_on_hit: float = 1.2
@export var stun_time_on_wall: float = 1.8

## --- Daño ---
@export var contact_damage: int = 1

## --- Efectos ---
@export var hit_effect_scene: PackedScene

## --- Grupo ---
@export var enemy_group: String = "enemies"

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var hitbox: Area2D = $Hitbox

@export var knockback_force: float = 500.0        # fuerza horizontal del empujón
@export var knockback_up_force: float = 220.0     # componente vertical del empujón
@export var knockback_duration: float = 0.35      # cuánto dura el empujón antes de frenar
@export var knockback_friction: float = 900.0 

var _state: State = State.IDLE
var _hp: int
var _player: Node2D = null
var _knockback_timer: float = 0.0
var _is_knocked_back: bool = false

# idle
var _idle_origin_y: float = 0.0
var _float_phase: float = 0.0

# carga
var _charge_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.DOWN

# dash
var _dash_timer: float = 0.0
var _bounces_left: int = 0

# aturdido
var _stun_timer: float = 0.0

# rotación base del sprite (para orientar durante el dash)
var _sprite_base_rotation: float = 0.0


func _ready() -> void:
	_hp = hits_to_die
	add_to_group(enemy_group)

	_idle_origin_y = global_position.y
	_sprite_base_rotation = sprite.rotation if sprite else 0.0

	# Buscar jugador
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		await get_tree().process_frame
		_player = get_tree().get_first_node_in_group("player")

	# Conexiones
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	match _state:
		State.IDLE:
			_process_idle(delta)
		State.ALERTED:
			_process_alerted(delta)
		State.CHARGING:
			_process_charging(delta)
		State.DASHING:
			_process_dashing(delta)
		State.STUNNED:
			_process_stunned(delta)


# ---------- IDLE ----------

func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	_float_phase += delta * float_speed
	global_position.y = _idle_origin_y + sin(_float_phase) * float_amplitude


# ---------- ALERTED ----------

func _process_alerted(delta: float) -> void:
	velocity = Vector2.ZERO
	_charge_timer += delta
	if _charge_timer >= 0.15:
		_charge_timer = 0.0
		_enter_charging()


# ---------- CHARGING ----------

func _enter_charging() -> void:
	_state = State.CHARGING
	_charge_timer = 0.0
	if _player and is_instance_valid(_player):
		_dash_direction = (_player.global_position - global_position).normalized()
	else:
		_dash_direction = Vector2.DOWN
	if sprite:
		sprite.modulate = Color(1, 0.3, 0.3, 1)


func _process_charging(delta: float) -> void:
	velocity = Vector2.ZERO
	_charge_timer += delta

	# Seguir levemente al jugador durante la carga (telegraph)
	if _player and is_instance_valid(_player):
		var to_player := (_player.global_position - global_position).normalized()
		_dash_direction = _dash_direction.lerp(to_player, 4.0 * delta).normalized()

	# Parpadeo creciente
	if sprite:
		var t: float = _charge_timer / charge_time
		var blink: float = 0.5 + 0.5 * sin(t * TAU * 4.0)
		sprite.modulate = Color(1, 0.3 + 0.4 * blink, 0.3 + 0.4 * blink, 1)

	if _charge_timer >= charge_time:
		_enter_dashing()


# ---------- DASHING (sin gravedad, con rebote especular) ----------

func _enter_dashing() -> void:
	_state = State.DASHING
	_dash_timer = 0.0
	_bounces_left = max_bounces
	velocity = _dash_direction * dash_speed

	if sprite:
		sprite.modulate = Color(1, 1, 1, 1)
		sprite.rotation = _dash_direction.angle() + _sprite_base_rotation


func _process_dashing(delta: float) -> void:
	_dash_timer += delta

	# Sin gravedad: la velocidad se mantiene constante salvo por rebotes.

	move_and_slide()

	# Detección de colisiones
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()

		# ¿Jugador?
		if collider and collider.has_method("take_hit"):
			_on_hit_player(collider)
			return

		# ¿Pared/suelo/techo? (ignoramos otros enemigos)
		if collider and not collider.is_in_group("enemies"):
			_on_hit_wall(collision)
			return

	# Tiempo máximo de dash sin chocar nada
	if _dash_timer >= dash_max_time:
		_enter_stunned(stun_time_on_wall)


func _on_hit_wall(collision: KinematicCollision2D) -> void:
	_spawn_hit_effect(collision.get_position())

	var normal := collision.get_normal()

	# Rebote especular: refleja la velocidad según la normal de la superficie
	var reflected := velocity.bounce(normal)
	reflected *= bounce_decay
	velocity = reflected

	# Actualizar dirección
	if velocity.length_squared() > 0.01:
		_dash_direction = velocity.normalized()
		if sprite:
			sprite.rotation = _dash_direction.angle() + _sprite_base_rotation

	# Feedback visual breve: flash amarillo
	if sprite:
		sprite.modulate = Color(1, 0.9, 0.3, 1)

	_bounces_left -= 1

	# ¿Se agotó la energía o los rebotes?
	if velocity.length() < min_bounce_speed or _bounces_left <= 0:
		_enter_stunned(stun_time_on_wall)
		return

	# Reanudar el contador de dash (opcional, para que no se aturda por tiempo si sigue rebotando)
	_dash_timer = 0.0


func _on_hit_player(player: Node2D) -> void:
	if player.has_method("take_hit"):
		player.take_hit()

	# Knockback al jugador
	if player is CharacterBody2D:
		var dir := (_dash_direction + Vector2.UP * 0.5).normalized()
		player.velocity = dir * bounce_on_player
		if "knockback_timer" in player:
			player.knockback_timer = 0.25

	# El dasher rebota hacia atrás y arriba
	var bounce_dir := (-_dash_direction + Vector2.UP * 0.5).normalized()
	velocity = bounce_dir * (dash_speed * 0.6)
	_dash_direction = velocity.normalized()

	_spawn_hit_effect()

	# Transición: aturdido corto tras golpear al jugador
	_enter_stunned(stun_time_on_hit)


# ---------- STUNNED (sin gravedad, se queda flotando) ----------

func _enter_stunned(duration: float) -> void:
	_state = State.STUNNED
	_stun_timer = duration
	velocity = Vector2.ZERO

	if sprite:
		sprite.modulate = Color(0.6, 0.6, 0.6, 1)


func _process_stunned(delta: float) -> void:
	# Sin gravedad: se queda quieto donde está.
	velocity = Vector2.ZERO

	_stun_timer -= delta
	if _stun_timer <= 0.0:
		if sprite:
			sprite.modulate = Color(1, 1, 1, 1)
		# Actualizar origen de flotado a la posición actual
		_idle_origin_y = global_position.y
		_float_phase = 0.0
		_state = State.IDLE


# ---------- DETECCIÓN ----------

func _on_detection_body_entered(body: Node2D) -> void:
	if _state != State.IDLE:
		return
	if not body.has_method("take_hit"):
		return

	_state = State.ALERTED
	_charge_timer = 0.0

	if sprite:
		sprite.modulate = Color(1, 0.8, 0.2, 1)


# ---------- HITBOX ----------

func _on_hitbox_body_entered(_body: Node2D) -> void:
	# El daño por contacto durante el dash ya lo maneja _on_hit_player.
	pass


# ---------- DAÑO AL ENEMIGO ----------

func take_damage(amount: int, _hit_direction: Vector2 = Vector2.ZERO) -> void:
	_hp -= amount

	if sprite:
		var original := sprite.modulate
		sprite.modulate = Color(1, 0.3, 0.3, 1)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			sprite.modulate = original

	if _hp <= 0:
		die()
		return

	if _state == State.DASHING or _state == State.CHARGING:
		_enter_stunned(0.6)

	# Aplicar knockback si nos dieron una dirección
	if _hit_direction != Vector2.ZERO:
		_apply_knockback(_hit_direction)

func _apply_knockback(hit_direction: Vector2) -> void:
	_is_knocked_back = true
	_knockback_timer = knockback_duration

	# Empujón horizontal en la dirección del golpe + un poco hacia arriba
	velocity.x = hit_direction.x * knockback_force
	velocity.y = -knockback_up_force

	# Orientar sprite hacia donde sale despedido (opcional)
	if sprite and abs(hit_direction.x) > 0.01:
		sprite.flip_h = hit_direction.x < 0.0
func die() -> void:
	_spawn_hit_effect()
	queue_free()


# ---------- UTILIDADES ----------


func _spawn_hit_effect(at_position: Vector2 = global_position) -> void:
	if hit_effect_scene == null:
		return
	var fx := hit_effect_scene.instantiate()
	get_tree().current_scene.add_child(fx)
	fx.global_position = at_position
