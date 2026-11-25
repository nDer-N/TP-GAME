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
@export var death_vfx_scene: PackedScene
@export var sparks_scene: PackedScene

## --- Grupo ---
@export var enemy_group: String = "enemies"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var hitbox: Area2D = $Hitbox
@onready var noise_emitter: PhantomCameraNoiseEmitter2D = $PhantomCameraNoiseEmitter2D
@onready var animation_controller: Node = $DasherAnimationController

@export var knockback_force: float = 500.0        # fuerza horizontal del empujón
@export var knockback_up_force: float = 220.0     # componente vertical del empujón
@export var knockback_duration: float = 0.35      # cuánto dura el empujón antes de frenar
@export var knockback_friction: float = 900.0 

@export_group("Afterimage")
@export var afterimage_enabled: bool = true
@export var afterimage_interval: float = 0.03    # cada cuánto spawnea un fantasma
@export var afterimage_lifetime: float = 0.25    # cuánto tarda en desaparecer
@export var afterimage_start_alpha: float = 0.6  # alpha inicial del fantasma
@export var afterimage_color: Color = Color(1.0, 0.7, 0.3, 1.0)  # tinte naranja
@export var afterimage_scale_end: float = 0.6    # escala final, relativa a la del sprite


var _afterimage_timer: float = 0.0
var _state: State = State.IDLE
var _hp: int
var _player: Node2D = null
var _knockback_timer: float = 0.0
var _is_knocked_back: bool = false
var _player_in_detection: bool = false

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

var _taking_hit: bool = false;
var _last_hit_normal: Vector2 = Vector2.ZERO


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
		
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)


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
		
	if animation_controller:
		animation_controller.force_state(animation_controller.VisualState.CHARGING)
	# (Tu lógica de modular para el parpadeo rojo sigue acá si la tenés)

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
	_afterimage_timer = 0.0
	velocity = _dash_direction * dash_speed

	if sprite:
		sprite.rotation = _dash_direction.angle() + _sprite_base_rotation
		
	if animation_controller:
		animation_controller.force_state(animation_controller.VisualState.DASHING)


func _process_dashing(delta: float) -> void:
	_dash_timer += delta
	_update_afterimage(delta)

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
	noise_emitter.emit()
	_spawn_hit_effect(collision.get_position())

	# Separar de la superficie para evitar re-colisión en el próximo frame
	var normal := collision.get_normal()
	_spawn_sparks(collision.get_position(), normal)
	global_position += normal * 4.0
	_last_hit_normal = normal

	# Rebote inverso
	_dash_direction = -_dash_direction
	velocity = _dash_direction * dash_speed

	if sprite:
		#sprite.rotation = _dash_direction.angle() + _sprite_base_rotation
		sprite.modulate = Color(1, 0.9, 0.3, 1)

	_bounces_left -= 1
	_dash_timer = 0.0

	if _bounces_left <= 0:
		_enter_stunned(stun_time_on_wall)


func _on_hit_player(player: Node2D) -> void:
	noise_emitter.emit()
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
	
	_last_hit_normal = (global_position - player.global_position).normalized()
	_spawn_sparks((global_position + player.global_position) * 0.5, _last_hit_normal)

	_spawn_hit_effect()

	# Transición: aturdido corto tras golpear al jugador
	_enter_stunned(stun_time_on_hit)


# ---------- STUNNED (sin gravedad, se queda flotando) ----------

func _enter_stunned(duration: float) -> void:
	_state = State.STUNNED
	_stun_timer = duration
	velocity = Vector2.ZERO
	
	if animation_controller and not _taking_hit:
		animation_controller.force_state(animation_controller.VisualState.STUNNED)
	




func _process_stunned(delta: float) -> void:
	velocity = Vector2.ZERO
	_stun_timer -= delta
	
	if _stun_timer <= 0.0:
		if sprite:
			sprite.modulate = Color(1, 1, 1, 1)
			
			var tw = create_tween()
			tw.tween_property(sprite, "rotation", _sprite_base_rotation, 0.15)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# --- NUEVO: Separarse de la superficie de forma segura ---
		if _last_hit_normal != Vector2.ZERO:
			for i in range(3): # Intentar hasta 3 veces (por si está en una esquina)
				var col = move_and_collide(_last_hit_normal * 16.0)
				if not col:
					break # Si ya no choca, dejamos de empujar
			_last_hit_normal = Vector2.ZERO
		# --------------------------------------------------------
			
		_idle_origin_y = global_position.y
		_float_phase = 0.0
		_state = State.IDLE
		
		if animation_controller:
			animation_controller.force_state(animation_controller.VisualState.IDLE)
			
		if _player_in_detection:
			_start_attack()


# ---------- DETECCIÓN ----------

func _on_detection_body_entered(body: Node2D) -> void:
	if not body.has_method("take_hit"):
		return
	_player_in_detection = true
	# Si estamos en IDLE, arrancar el ataque inmediatamente
	if _state == State.IDLE:
		_start_attack()

func _on_detection_body_exited(body: Node2D) -> void:
	if not body.has_method("take_hit"):
		return
	_player_in_detection = false

func _start_attack() -> void:
	_state = State.ALERTED
	_charge_timer = 0.0
	if animation_controller:
		animation_controller.force_state(animation_controller.VisualState.ALERTED, 0.15)


# ---------- HITBOX ----------

func _on_hitbox_body_entered(_body: Node2D) -> void:
	# El daño por contacto durante el dash ya lo maneja _on_hit_player.
	pass


# ---------- DAÑO AL ENEMIGO ----------

func take_damage(amount: int, _hit_direction: Vector2 = Vector2.ZERO) -> void:
	_taking_hit = true
	if _hp <= 0:
		return  # Evitar que reciba más daño si ya está muriendo

	_hp -= amount
	
	var spark_dir := -_hit_direction if _hit_direction != Vector2.ZERO else Vector2.UP
	_spawn_sparks(global_position, spark_dir.normalized())

	if _hp <= 0:
		die()
		return

	# 1. Reproducir animación de daño (bloquea la animación por 0.2s)
	if animation_controller:
		animation_controller.force_state(animation_controller.VisualState.HURT, 0.5)

	# 2. Feedback visual (parpadeo rojo)
	if sprite:
		var original := sprite.modulate
		sprite.modulate = Color(1, 0.3, 0.3, 1)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			sprite.modulate = original

	# 3. Interrupción de lógica
	if _state == State.DASHING or _state == State.CHARGING:
		_enter_stunned(0.6)
		_taking_hit = false
	elif _hit_direction != Vector2.ZERO:
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
	# 1. Instanciar las partículas de muerte
	if death_vfx_scene:
		var vfx := death_vfx_scene.instantiate()
		get_tree().current_scene.add_child(vfx)
		vfx.global_position = global_position
		
	# 2. Tu efecto de golpe normal (opcional, si quieres que salgan chispas también)
	# _spawn_hit_effect()

	# 3. Avisar al resto del juego y aplicar HitStop
	Events.enemy_died.emit(true)
	HitStop.request(0.4)
	
	# 4. Destruir al Dasher inmediatamente (esto elimina también sus hitboxes)
	queue_free()


# ---------- UTILIDADES ----------


func _spawn_hit_effect(at_position: Vector2 = global_position) -> void:
	if hit_effect_scene == null:
		return
	var fx := hit_effect_scene.instantiate()
	get_tree().current_scene.add_child(fx)
	fx.global_position = at_position

func _spawn_sparks(at: Vector2, normal: Vector2) -> void:
	if sparks_scene == null:
		return
	var sparks := sparks_scene.instantiate()
	get_tree().current_scene.add_child(sparks)
	sparks.fire(at, normal)
	
func _update_afterimage(delta: float) -> void:
	if not afterimage_enabled or sprite == null:
		return

	_afterimage_timer -= delta
	if _afterimage_timer > 0.0:
		return
	_afterimage_timer = afterimage_interval

	_spawn_afterimage()


func _spawn_afterimage() -> void:
	if sprite.sprite_frames == null:
		return

	# Frame actual de la animación
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if tex == null:
		return

	var ghost := Sprite2D.new()
	ghost.texture = tex
	ghost.centered = sprite.centered
	ghost.offset = sprite.offset
	ghost.flip_h = sprite.flip_h
	ghost.flip_v = sprite.flip_v
	ghost.global_position = sprite.global_position
	ghost.global_rotation = sprite.global_rotation
	ghost.z_index = z_index + sprite.z_index - 1   # por detrás del dasher

	var base_scale: Vector2 = sprite.global_scale
	ghost.global_scale = base_scale

	var c := afterimage_color
	c.a = afterimage_start_alpha
	ghost.modulate = c

	# Al mundo, no al dasher, para que no se mueva con él
	get_tree().current_scene.add_child(ghost)

	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, afterimage_lifetime)
	tween.tween_property(ghost, "scale", base_scale * afterimage_scale_end, afterimage_lifetime)
	tween.chain().tween_callback(ghost.queue_free)
