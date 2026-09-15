extends Line2D

@export var max_points: int = 200
@export var show_landing_marker: bool = true
@export var landing_marker_scene: PackedScene

var landing_position: Vector2 = Vector2.ZERO
var marker_instance: Node2D = null
var physics_config: ProjectilePhysicsConfig



func apply_fade_gradient() -> void:
	var point_count = points.size()
	if point_count < 2:
		gradient = null
		return
	
	# Longitud acumulada real de cada punto (así el offset del gradient
	# coincide con lo que Line2D usa internamente para pintar)
	var cumulative := PackedFloat32Array()
	cumulative.resize(point_count)
	cumulative[0] = 0.0
	for i in range(1, point_count):
		cumulative[i] = cumulative[i - 1] + points[i].distance_to(points[i - 1])
	
	var total_length = cumulative[point_count - 1]
	if total_length <= 0.0:
		gradient = null
		return
	
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	
	var half_index = float(point_count) * 0.7
	
	for i in range(point_count):
		# alpha 1.0 en el punto 0, baja lineal y llega a 0.0 en point_count/2
		var alpha = clamp(1.0 - float(i) / half_index, 0.0, 1.0)
		offsets.append(cumulative[i] / total_length)
		colors.append(Color(1, 1, 1, alpha))
	
	var grad = Gradient.new()
	grad.offsets = offsets
	grad.colors = colors
	gradient = grad

func update_trajectory(from: Vector2, target: Vector2, charge_power: float, config: ProjectilePhysicsConfig):
	clear_points()
	physics_config = config
	landing_position = Vector2.ZERO
	
	hide_landing_marker()
	
	if charge_power <= 0:
		return
	
	simulate_projectile(from, target, charge_power, config)
	apply_fade_gradient()
	update_landing_marker()

func simulate_projectile(from: Vector2, target: Vector2, charge_power: float, config: ProjectilePhysicsConfig):
	var pos = from
	var dir = (target - from).normalized()
	var vel = dir * config.base_speed * charge_power
	var grav = Vector2(0, config.gravity)
	var step_time = 0.02
	
	var time = 0.0
	var max_time = 5.0
	var bounces = 0
	var has_landed = false
	
	while time < max_time and points.size() < max_points and not has_landed:
		var prev_pos = pos
		var prev_vel = vel
		
		# Aplicar gravedad
		vel.y += config.gravity * step_time
		pos += vel * step_time
		time += step_time
		
		add_point(to_local(pos))
		
		var collision = detect_collision(prev_pos, pos)
		if collision:
				var normal = collision.normal
				var collider = collision.collider
				
				if collider and collider.is_in_group("TECHO"):
					vel = prev_vel.bounce(normal) * config.bounce_decay
					bounces += 1
					pos = collision.position + normal * 2
					if bounces >= config.max_bounces:
						has_landed = true
						landing_position = pos
						add_point(to_local(landing_position))
					continue
				
				# CASO 1: SUELO (Normal apunta hacia arriba). ¡NO REBOTA, ATERRIZA!
				if normal.y > 0.7:
					landing_position = _get_surface_top(collision.position)
					has_landed = true
					add_point(to_local(landing_position))
					break
				
				# CASO 2: TECHO DE PLATAFORMA (Normal apunta hacia abajo). ¡NO REBOTA, ATERRIZA DEBAJO!
				elif normal.y < -0.7:
					landing_position = _get_platform_bottom(collision.position)
					has_landed = true
					add_point(to_local(landing_position))
					break
				
			# CASO 3: PARED (Normal es horizontal). ¡SÍ REBOTA!
				else:  
					vel = prev_vel.bounce(normal) * config.bounce_decay
					bounces += 1
					pos = collision.position + normal * 2
					if bounces >= config.max_bounces:
						has_landed = true
						landing_position = pos
						add_point(to_local(landing_position))
		
		# Si el proyectil va muy lento (para evitar rebotes infinitos)
		if vel.length() < 10 and pos.y > from.y:
			has_landed = true
			landing_position = pos
			add_point(to_local(landing_position))
			break
		
		if pos.y > 2000:
			has_landed = true
			landing_position = pos
			add_point(to_local(landing_position))
			break

func detect_collision(from: Vector2, to: Vector2) -> Dictionary:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [get_parent()]
	
	var result = space_state.intersect_ray(query)
	if result:
		return {
			"position": result.position,
			"normal": result.normal,
			"collider": result.collider
		}
	return {}

# Buscar la superficie superior (cuando caes encima)
func _get_surface_top(collision_point: Vector2) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var from = Vector2(collision_point.x, collision_point.y - 240.0)
	var to = Vector2(collision_point.x, collision_point.y + 4.0)
	var query = PhysicsRayQueryParameters2D.create(from, to)
	
	# EXCLUIR el nodo padre Y TODOS los nodos con el grupo "TECHO"
	query.exclude = [get_parent()] + get_tree().get_nodes_in_group("TECHO")
	
	
	var result = space_state.intersect_ray(query)
	if result:
		return Vector2(collision_point.x, result.position.y - 10)
	return Vector2(collision_point.x, collision_point.y - 10)

# Buscar la superficie INFERIOR (cuando chocas el techo de una plataforma)
func _get_platform_bottom(collision_point: Vector2) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var from = Vector2(collision_point.x, collision_point.y + 240.0)
	var to = Vector2(collision_point.x, collision_point.y - 4.0)
	var query = PhysicsRayQueryParameters2D.create(from, to)
	
	# EXCLUIR el nodo padre Y TODOS los nodos con el grupo "TECHO"
	query.exclude = [get_parent()] + get_tree().get_nodes_in_group("TECHO")
	
	var result = space_state.intersect_ray(query)
	if result:
		return Vector2(collision_point.x, result.position.y + 10)
	return Vector2(collision_point.x, collision_point.y + 10)

func update_landing_marker():
	hide_landing_marker()
	
	if show_landing_marker and landing_position != Vector2.ZERO and landing_marker_scene:
		marker_instance = landing_marker_scene.instantiate()
		add_child(marker_instance)
		marker_instance.global_position = landing_position
		marker_instance.visible = true

func hide_landing_marker():
	if marker_instance:
		marker_instance.queue_free()
		marker_instance = null
