extends CharacterBody2D

@export var lifetime: float = 5.0
@export var physics_config: ProjectilePhysicsConfig
@export_group("Afterimage")
@export var afterimage_enabled: bool = true
@export var afterimage_interval: float = 0.03   # cada cuánto spawnea un fantasma
@export var afterimage_lifetime: float = 0.25   # cuánto tarda en desaparecer
@export var afterimage_start_alpha: float = 0.6 # alpha inicial del fantasma
@export var afterimage_color: Color = Color(0.6, 0.9, 1.0, 1.0)  # tinte cian
@export var afterimage_scale: float = 1.0            # scale del fantasma (relativo al proyectil)
@export var afterimage_scale_end: float = 0.6
@export_group("Death animation")
## Nombre de la animación (dentro del AnimatedSprite2D hijo llamado "DeathAnimation") que se reproduce
## SIEMPRE que el proyectil termina: al golpear un enemigo, al aterrizar o al acabarse su lifetime.
@export var death_animation_name: StringName = &"death"

var time_elapsed: float = 0.0
var target_half_height: float = 0.0
var _afterimage_timer: float = 0.0
var _is_dying: bool = false   # true mientras suena la animación de muerte (el proyectil ya no hace nada más)
signal landed(position: Vector2)
signal died(did_die : bool)
signal hit_enemy(enemy: Node2D, hit_position: Vector2)


@onready var sprite: Sprite2D = $Sprite2D   # asegúrate de que exista
@onready var death_sprite: AnimatedSprite2D = get_node_or_null("DeathAnimation")

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if death_sprite:
		death_sprite.hide()   # solo se muestra al morir

func launch(from: Vector2, to: Vector2, charge_power: float, half_height: float = 0.0) -> void:
	global_position = from
	target_half_height = half_height
	var direction = (to - from).normalized()
	var launch_speed = physics_config.base_speed * charge_power
	velocity = direction * launch_speed

func _physics_process(delta: float) -> void:
	time_elapsed += delta
	if time_elapsed >= lifetime:
		die()
		return

	velocity.y += physics_config.gravity * delta
	

	var velocity_before_collision = velocity  # ✅ ahora sí es la real
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		
		if collider and collider.is_in_group("enemies"):
			hit_enemy.emit(collider, collision.get_position())
			_play_death(collision.get_position())
			return
		_bounce(collision, velocity_before_collision)
		if _is_dying:   # _bounce pudo haber llamado a _land()
			return
	_update_afterimage(delta)
		
func _update_afterimage(delta: float) -> void:
	if not afterimage_enabled or sprite == null:
		return

	_afterimage_timer -= delta
	if _afterimage_timer > 0.0:
		return
	_afterimage_timer = afterimage_interval

	_spawn_afterimage()

func _spawn_afterimage() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.global_position = sprite.global_position
	ghost.global_rotation = sprite.global_rotation
	ghost.scale = sprite.scale
	ghost.flip_h = sprite.flip_h
	ghost.flip_v = sprite.flip_v
	ghost.z_index = sprite.z_index - 1     # por detrás del proyectil real
	
	var base_scale: Vector2 = sprite.scale * afterimage_scale
	var end_scale: Vector2 = sprite.scale * afterimage_scale_end
	ghost.scale = base_scale
	# Alpha inicial + tinte
	var c := afterimage_color
	c.a = afterimage_start_alpha
	ghost.modulate = c

	# Añadirlo al mundo (no al proyectil, para que no se mueva con él)
	get_tree().current_scene.add_child(ghost)

	# Tween de fade out + un pequeño encogimiento opcional
	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, afterimage_lifetime)
	tween.tween_property(ghost, "scale", sprite.scale * 0.6, afterimage_lifetime)  # opcional
	tween.tween_property(ghost, "scale", end_scale, afterimage_lifetime)
	tween.chain().tween_callback(ghost.queue_free)
	
func _bounce(collision: KinematicCollision2D, incoming_velocity: Vector2) -> void:
	var normal = collision.get_normal()
	
	# CHECK DE GRUPO: Si el objeto es un techo, forzamos el rebote sin importar la normal
	if collision.get_collider().is_in_group("TECHO"):
		# Rebote con velocidad mínima (ver ProjectilePhysicsConfig.ceiling_bounce)
		velocity = physics_config.ceiling_bounce(incoming_velocity, normal)
		# Empujón hacia AFUERA de la superficie, no siempre hacia abajo
		global_position += normal * physics_config.ceiling_push_out
		return
	
	# Lógica original de normales (solo se ejecuta si NO es techo)
	if normal.y < -0.7:
		_land(global_position)
		return
	if normal.y > 0.7:
		var top_pos = _get_platform_top(collision.get_position())
		_land(top_pos)
		return
	velocity = incoming_velocity.bounce(normal) * physics_config.bounce_decay


func _land(pos: Vector2) -> void:
	if _is_dying:
		return
	velocity = Vector2.ZERO
	landed.emit(pos)
	_play_death()


func _get_platform_top(collision_point: Vector2) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var from = Vector2(collision_point.x, collision_point.y - 240)
	var to = Vector2(collision_point.x, collision_point.y + 4.0)
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [self] 
	var result = space_state.intersect_ray(query)
	if result:
		return Vector2(collision_point.x, result.position.y - target_half_height - 2.0)
	return Vector2(collision_point.x, collision_point.y - target_half_height - 2.0)

func die() -> void:
	if _is_dying:
		return
	died.emit(true)
	_play_death()


## Detiene el proyectil, oculta su sprite normal y reproduce la animación de muerte.
## Es el ÚNICO punto de salida del proyectil: golpe a enemigo, aterrizaje y expiración pasan por aquí.
## Las señales (hit_enemy / landed / died) se emiten ANTES de llamar a esto, así que el gameplay
## (teleport, slash, etc.) no espera a que termine la animación.
## at_position: dónde mostrar la animación (por defecto, donde esté el proyectil).
func _play_death(at_position: Vector2 = Vector2.INF) -> void:
	if _is_dying:
		return
	_is_dying = true

	# Congelar el proyectil: sin movimiento, sin colisiones y sin estela nueva.
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	if at_position != Vector2.INF:
		global_position = at_position

	# Si no hay animación de muerte configurada, se comporta como antes: desaparece al instante.
	if death_sprite == null \
			or death_sprite.sprite_frames == null \
			or not death_sprite.sprite_frames.has_animation(death_animation_name):
		queue_free()
		return

	if sprite:
		sprite.hide()
	# Si la animación estuviera en loop, animation_finished nunca se emitiría y el proyectil quedaría para siempre.
	death_sprite.sprite_frames.set_animation_loop(death_animation_name, false)
	death_sprite.show()
	death_sprite.animation_finished.connect(queue_free)
	death_sprite.play(death_animation_name)
