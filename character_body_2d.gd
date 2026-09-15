extends CharacterBody2D

@export var speed: float = 300.0
@export var sprint_multiplier: float = 1.6
@export var gravity: float = 980.0
@export var low_jump_multiplier: float = 2.5
@export var friction: float = 1500
@export var tp_projectile_scene: PackedScene
@export var  charge_rate: float = 10.0
@export var min_power_threshold: float = 0.08
@export var max_charge: float = 7.0
@export var physics_config: ProjectilePhysicsConfig
@export var aim_pcam: PhantomCamera2D
@export var CeilingCam: PhantomCamera2D
@export var BasementCam: PhantomCamera2D
@export var max_tp_charges: int = 3
@export var recharge_hold_time: float = 1.0
@export var trajectory_line: Line2D 
@export var max_hits: int = 3
@export var hit_invulnerability_time: float = 1.0



var current_speed: float = speed
var jumps_left: int = 2
var facing_direction: int = 1
var is_charging: bool = false
var charge_power: float = 0.0
var tp_charges: int = 0
var recharge_timer: float = 0.0
var is_recharging: bool = false
var current_hits: int = 0
var invulnerable_timer: float = 0.0
var is_dead: bool = false
var hits_display: Control
var death_barrier: CollisionShape2D
var is_on_Ceiling: bool = false
var is_on_basement: bool = false








@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $PlayerHitbox
@onready var jump_controller: Node = $JumpController
@onready var slash_controller: Node = $SlashController


func _ready() -> void:
	
	hits_display = get_tree().get_first_node_in_group("hud")
	if hits_display:
		hits_display.setup(max_hits)
		hits_display.update_hits(current_hits)
	else:
		print("No se encontró HitsDisplay en el árbol")


func _physics_process(delta: float) -> void:
	if is_on_Ceiling:
		print("CEILING")
		CeilingCam.priority = 5
	else:
		CeilingCam.priority = 0
		
	if is_on_basement:
		print("BASEMENT")
		BasementCam.priority = 5
	else:
		BasementCam.priority = 0
	if is_dead:
		return
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	
	current_speed = speed
	
	if Input.is_action_pressed("sprint"):
		current_speed *= sprint_multiplier
	
	if not is_on_floor():
		if velocity.y < 0 and not Input.is_action_pressed("jump"):
			velocity.y += gravity * low_jump_multiplier * delta
		else:
			velocity.y += gravity * delta
	
	if input_dir:
		velocity.x = input_dir.x * current_speed
	elif not input_dir:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	if tp_charges>0:	
		if is_charging:
			charge_power =min(charge_power + charge_rate * delta, max_charge)
			update_trajectory_preview()
		
		
		#print("NO CHARGES LEFT!")
	jump_controller.jump_processing(delta)
	if Input.is_action_just_pressed("reload") and tp_charges < max_tp_charges and not is_recharging:
		is_recharging = true
		recharge_timer = 0.0
	if is_recharging:
		if input_dir != Vector2.ZERO or Input.is_action_pressed("jump"):
			is_recharging = false
			recharge_timer = 0.0
		else:
			recharge_timer += delta
			if recharge_timer >= recharge_hold_time:
				start_recharge()
				is_recharging = false
				recharge_timer = 0.0
	print(recharge_timer)
	update_character_state()
	slash_controller.attack_processing(delta)
	move_and_slide()
	
	if invulnerable_timer > 0:
		sprite.modulate = Color(1, 1, 0, 1)
		invulnerable_timer -= delta
	else:
		sprite.modulate = Color(1, 1, 1, 1)
	
	check_enemy_contact()
	check_height()
	

func check_height():
	print(global_position)
	if global_position.y <-1920:
		is_on_Ceiling = true
	else:
		is_on_Ceiling = false
	
	if global_position.y > 0:
		is_on_basement = true
	else:
		is_on_basement = false
	


func update_character_state():
	if velocity.x > 10:
		facing_direction = 1
		sprite.flip_h = false
	elif velocity.x < -10:
		facing_direction = -1
		sprite.flip_h = true
		


func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if event.is_action_pressed("attack"):
		slash_controller.try_attack()
		print("ATTCK")
	if tp_charges>0:
		if event.is_action_pressed("shoot_tp"):
			is_charging = true
			aim_pcam.priority = 10
			charge_power = 0.0
			if trajectory_line:
				trajectory_line.visible = true
				update_trajectory_preview()
		elif event.is_action_released("shoot_tp"):
			if is_charging:
				
				is_charging = false
				if trajectory_line:
					trajectory_line.visible = false
					trajectory_line.clear_points()  # Limpiar puntos
				if charge_power >= min_power_threshold:
					var mouse_world_pos = get_viewport().get_camera_2d().get_global_mouse_position()
					shoot_tp(mouse_world_pos, charge_power)
					#shoot_tp(get_global_mouse_position(), charge_power)
					print(charge_power)
				charge_power = 0.0
	
	
func update_trajectory_preview():
	if trajectory_line and physics_config:
		var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
		var start_pos = global_position + Vector2(0, -10)
		
		# Usar el charge_power actual o mínimo para predicción
		var power = max(charge_power, min_power_threshold)
		
		# Actualizar la línea de trayectoria
		trajectory_line.update_trajectory(start_pos, mouse_pos, power, physics_config)
		trajectory_line.visible = true
		
func start_recharge():
	tp_charges = min(tp_charges + 1, max_tp_charges)
	pass


func shoot_tp(target_position: Vector2, charge_power2: float):
	tp_charges-=1
	var projectile = tp_projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	var half_height := 0.0
	if collision_shape.shape is RectangleShape2D:
		half_height = collision_shape.shape.size.y / 2.0
	elif collision_shape.shape is CapsuleShape2D:
		half_height = collision_shape.shape.height / 2.0
	elif collision_shape.shape is CircleShape2D:
		half_height = collision_shape.shape.radius
		
		

	projectile.launch(global_position, target_position, charge_power2, half_height)
	projectile.landed.connect(_on_tp_landed)
	
	
func _on_tp_landed(landing_position: Vector2) -> void:
	landing_position.y = landing_position.y - 64.0
	global_position = landing_position
	velocity = Vector2.ZERO
	aim_pcam.priority = 0

func check_enemy_contact() -> void:
	if is_dead or invulnerable_timer > 0:
		return
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider.is_in_group("enemies"):
			take_hit()
			break  # un solo golpe por frame, aunque toques varios enemigos a la vez


func take_hit() -> void:
	current_hits += 1
	invulnerable_timer = hit_invulnerability_time
	print("Golpe recibido: ", current_hits, "/", max_hits)
	if hits_display:
		hits_display.update_hits(current_hits)
	if current_hits >= max_hits:
		die()
		
func die() -> void:
	current_hits = max_hits
	hits_display.update_hits(current_hits)
	is_dead = true
	velocity = Vector2.ZERO
	sprite.modulate = Color(1, 0, 0, 1)  # amarillo
	print("Jugador murió")
