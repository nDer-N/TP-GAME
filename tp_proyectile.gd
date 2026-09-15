extends CharacterBody2D

@export var lifetime: float = 5.0
@export var physics_config: ProjectilePhysicsConfig

var time_elapsed: float = 0.0
var target_half_height: float = 0.0
signal landed(position: Vector2)

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func launch(from: Vector2, to: Vector2, charge_power: float, half_height: float = 0.0) -> void:
	global_position = from
	target_half_height = half_height
	var direction = (to - from).normalized()
	var launch_speed = physics_config.base_speed * charge_power
	velocity = direction * launch_speed

func _physics_process(delta: float) -> void:
	time_elapsed += delta
	if time_elapsed >= lifetime:
		queue_free()
		return

	velocity.y += physics_config.gravity * delta
	

	var velocity_before_collision = velocity  # ✅ ahora sí es la real
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		_bounce(collision, velocity_before_collision)

func _bounce(collision: KinematicCollision2D, incoming_velocity: Vector2) -> void:
	var normal = collision.get_normal()
	
	# CHECK DE GRUPO: Si el objeto es un techo, forzamos el rebote sin importar la normal
	if collision.get_collider().is_in_group("TECHO"):
		velocity = incoming_velocity.bounce(normal) * physics_config.bounce_decay
		# Pequeño empujón para evitar que se quede pegado al techo
		global_position += Vector2(0, 2)
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
	velocity = Vector2.ZERO
	landed.emit(pos)
	queue_free()


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
