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
@export var ChargeCam: PhantomCamera2D
@export var max_tp_charges: int = 3
@export var recharge_hold_time: float = 1.0
@export var trajectory_line: Line2D 
@export var max_hits: int = 3
@export var hit_invulnerability_time: float = 1.0
@export var attack_flash_duration: float = 1 
@export var damage_flash_duration: float = 0.7  # cuánto dura el destello
@export var attack_flash_color: Color = Color(1, 1, 1, 1)
@export var damage_flash_color: Color = Color(1, 1, 0, 1)
@export var HitCAM: PhantomCamera2D
@export var HitCAM_duration: float = 1
@export var teleport_vfx_scene: PackedScene
@export var aim_outline_color: Color = Color(1.0, 0.6, 0.0, 1.0)
@export var aim_outline_width: float = 1.5
@export var landing_lock_time: float = 0.10
@export var min_fall_speed_for_landing: float = 200.0
@export var attack_brake_friction: float = 3000.0
@export var side_slash_lunge_speed: float = 450.0      # velocidad inicial del empujón
@export var side_slash_lunge_duration: float = 0.15
@export var knockback_friction: float = 800.0       # qué tan rápido frena el empujón
@export var knockback_gravity_mult: float = 1.0
@export var hit_recoil_multiplier: float = 1.0

var _last_attack_dir_x: float = 1.0
var _slash_lunge_velocity: float = 0.0
var _slash_lunge_timer: float = 0.0
var _last_fall_speed: float = 0.0 
var _was_on_floor: bool = false
var _outline_active: bool = false
var _hit_timer: float = 0.0
var _flash_tween: Tween = null
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
var knockback_timer: float = 0.0


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $PlayerHitbox
@onready var jump_controller: Node = $JumpController
@onready var slash_controller: Node = $SlashController
@onready var noise_emitter: PhantomCameraNoiseEmitter2D = $PhantomCameraNoiseEmitter2D2
@onready var animation_controller: Node = $AnimationController
@onready var outline_sprite: AnimatedSprite2D = $OutlineSprite
@onready var dust_particles: GPUParticles2D = $dust_particles


func _ready() -> void:
	add_to_group("player");
	hits_display = get_tree().get_first_node_in_group("hud")
	Events.enemy_died.connect(_on_enemy_died)
	if hits_display:
		hits_display.setup(max_hits)
		hits_display.update_hits(current_hits)
	else:
		print("No se encontró HitsDisplay en el árbol")
	print("HitStop existe: ", HitStop)
	if slash_controller:
		if slash_controller.has_signal("attack_connected"):
			slash_controller.attack_connected.connect(_on_attack_connected)
		if slash_controller.has_signal("attack_performed"):
			slash_controller.attack_performed.connect(_on_attack_performed)

func _on_attack_performed(direction: Vector2) -> void:
	if animation_controller == null:
		return
	
	if abs(direction.x) > 0.01:
		_last_attack_dir_x = sign(direction.x)
	else:
		# Ataque vertical: usar la dirección en la que mira el sprite
		_last_attack_dir_x = -1.0 if sprite.flip_h else 1.0

	var angle_deg := rad_to_deg(direction.angle())
	var dir_key: String

	if angle_deg >= -135.0 and angle_deg <= -45.0:
		dir_key = "up"
	elif angle_deg >= 45.0 and angle_deg <= 135.0:
		dir_key = "down"
	else:
		dir_key = "side"
		# Lunge lateral en la dirección del slash
		_start_side_slash_lunge(sign(direction.x))
		if sprite:
			sprite.flip_h = direction.x < 0.0
	animation_controller.start_slash_sequence(dir_key)

func _start_side_slash_lunge(direction_x: float) -> void:
	if abs(direction_x) < 0.01:
		return
	_slash_lunge_velocity = sign(direction_x) * side_slash_lunge_speed
	_slash_lunge_timer = side_slash_lunge_duration

func set_outline(active: bool) -> void:
	if outline_sprite == null:
		return
	if _outline_active == active:
		return
	_outline_active = active
	outline_sprite.visible = active
func _on_attack_connected(did_connect: bool) -> void:
	if not did_connect:
		return
	flash_sprite(attack_flash_duration, attack_flash_color)
	_slash_lunge_velocity = -_last_attack_dir_x * side_slash_lunge_speed * hit_recoil_multiplier
	_slash_lunge_timer = side_slash_lunge_duration
	
func _on_enemy_died() -> void:
	print("DEATH")
	# Dar prioridad a la HitCam
	HitCAM.priority = 10
	_hit_timer = HitCAM_duration


func _physics_process(delta: float) -> void:
	
	var is_moving = abs(velocity.x)>10
	var on_ground = is_on_floor()
	
	
	dust_particles.emitting = is_moving and on_ground
	
	if _slash_lunge_timer > 0.0:
		_slash_lunge_timer -= delta
	if _hit_timer > 0.0:
		_hit_timer -= delta
		if _hit_timer <= 0.0:
			HitCAM.priority = 0
			
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
	
	var in_knockback := invulnerable_timer > 0.0 and knockback_timer > 0.0
	if knockback_timer > 0.0:
		knockback_timer -= delta
	
	if in_knockback:
		# Aplicar gravedad normal
		if not is_on_floor():
			velocity.y += gravity * knockback_gravity_mult * delta
		# Frenar horizontalmente con fricción suave (para que se sienta el empujón)
		velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)
		move_and_slide()
		# Saltar el resto de la lógica de input/movimiento
		# Pero seguir actualizando animación y chequeos
		update_character_state()
		_was_on_floor = is_on_floor()
		if not is_on_floor():
			_last_fall_speed = velocity.y
		var now_on_floor := is_on_floor()
		if not _was_on_floor and now_on_floor:
			_play_landing_animation()
		_was_on_floor = now_on_floor
		check_enemy_contact()
		check_height()
		return
	
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	
	if invulnerable_timer > 0.0:
		input_dir = Vector2.ZERO
	
	current_speed = speed
	
	
	
	if Input.is_action_pressed("sprint"):
		noise_emitter.emit()
		current_speed *= sprint_multiplier
	
	if not is_on_floor():
		if velocity.y < 0 and not Input.is_action_pressed("jump"):
			velocity.y += gravity * low_jump_multiplier * delta
		else:
			velocity.y += gravity * delta
	
	# ¿El slash bloquea el movimiento? Solo en el suelo y en START/LOOP.
	var movement_locked := false
	if animation_controller and animation_controller.is_movement_locked() and is_on_floor():
		movement_locked = true

	if _slash_lunge_timer > 0.0 and is_on_floor():
		# Lunge lateral con decaimiento lineal
		var t := _slash_lunge_timer / side_slash_lunge_duration
		velocity.x = _slash_lunge_velocity * t
	elif movement_locked:
		velocity.x = move_toward(velocity.x, 0.0, attack_brake_friction * delta)
	elif invulnerable_timer > 0.0:
		# Knockback: se frena suave para que se sienta el empujón
		velocity.x = move_toward(velocity.x, 0.0, friction * 0.5 * delta)
	elif input_dir:
		velocity.x = input_dir.x * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		
	if tp_charges>0:	
			if is_charging:
				charge_power =min(charge_power + charge_rate * delta, max_charge)
				update_trajectory_preview()
		#print("NO CHARGES LEFT!")
	jump_controller.jump_processing(delta)
	if Input.is_action_just_pressed("reload") and tp_charges < max_tp_charges and not is_recharging:
		if animation_controller.is_aiming():
			animation_controller.cancel_aim_sequence()
			_cancel_tp_charge()
		if animation_controller.is_in_sequence():
			animation_controller.cancel_sequence()
		is_recharging = true
		recharge_timer = 0.0
		ChargeCam.priority = 10
		set_outline(true)
		animation_controller.force_state(
		animation_controller.VisualState.RECHARGING,
		recharge_hold_time 
	)
	if is_recharging:
		if input_dir != Vector2.ZERO or Input.is_action_pressed("jump"):
			is_recharging = false
			recharge_timer = 0.0
			ChargeCam.priority = 0
			animation_controller.unlock()
			set_outline(false)
		else:
			recharge_timer += delta
			if recharge_timer >= recharge_hold_time:
				start_recharge()
				ChargeCam.priority = 0
				set_outline(false)
				ScreenFlashLayer.flash(0.3, 1)
				is_recharging = false
				animation_controller.unlock()
				recharge_timer = 0.0
	print(recharge_timer)
	update_character_state()
	slash_controller.attack_processing(delta)
	_was_on_floor = is_on_floor()
	if not is_on_floor():
		_last_fall_speed = velocity.y
	move_and_slide()
	var now_on_floor := is_on_floor()
	if not _was_on_floor and now_on_floor:
		_play_landing_animation()
	_was_on_floor = now_on_floor
	
	if invulnerable_timer > 0:
		invulnerable_timer -= delta
		# Parpadeo físico: visible / invisible alternando
		sprite.visible = fmod(invulnerable_timer, 0.15) >= 0.075
		# Si al terminar de parpadear quedó invisible, forzar visible
		if invulnerable_timer <= 0.0:
			sprite.visible = true
	else:
		sprite.visible = true
	
	check_enemy_contact()
	check_height()
	

func _play_landing_animation() -> void:
	if animation_controller == null:
		return
	if animation_controller.is_in_sequence() or animation_controller.is_aiming():
		return

	# Ignorar caídas suaves
	if _last_fall_speed < min_fall_speed_for_landing:
		return

	var dur := landing_lock_time
	var anim_name: String = animation_controller.animation_map.get(
		int(animation_controller.VisualState.LANDING), "")
	if anim_name != "" and sprite.sprite_frames.has_animation(anim_name):
		dur = sprite.sprite_frames.get_frame_count(anim_name) / sprite.sprite_frames.get_animation_speed(anim_name)

	animation_controller.force_state(animation_controller.VisualState.LANDING,dur)
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
	var in_slash: bool = animation_controller != null and animation_controller.is_in_sequence()
	if not in_slash:
		if velocity.x > 10:
			facing_direction = 1
			sprite.flip_h = false
		elif velocity.x < -10:
			facing_direction = -1
			sprite.flip_h = true

	_update_visual_state()

func _update_visual_state() -> void:
	if animation_controller == null:
		return
	if is_recharging:
		animation_controller.set_state(animation_controller.VisualState.RECHARGING)
		return
	# ¿Está apuntando?
	if animation_controller.is_aiming():
		if abs(velocity.x) < 10.0 and is_on_floor():
			animation_controller.show_aim()
			return
		else:
			animation_controller.hide_aim()
	


	# --- Slash sigue bloqueando todo lo demás ---
	if animation_controller.is_in_sequence():
		return
		
	

	# --- En el aire ---
	if not is_on_floor():
		if velocity.y < 0:
			animation_controller.set_state(animation_controller.VisualState.JUMP)
		else:
			animation_controller.set_state(animation_controller.VisualState.FALL)
		return

	# --- En el suelo ---
	if abs(velocity.x) < 10.0:
		animation_controller.set_state(animation_controller.VisualState.IDLE)
	elif Input.is_action_pressed("sprint"):
		animation_controller.set_state(animation_controller.VisualState.RUN)
	else:
		animation_controller.set_state(animation_controller.VisualState.WALK)
	

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return

	# --- CANCELAR CARGA DEL TP CON ATTACK ---
	# Si estamos cargando el TP y el jugador presiona attack, cancelar.
	if is_charging and event.is_action_pressed("attack"):
		_cancel_tp_charge()
		set_outline(false)
		if animation_controller:
			animation_controller.cancel_aim_sequence()
		# Opcional: que el slash también se ejecute al cancelar
		slash_controller.try_attack()
		print("TP cancelado con slash")
		return

	# --- ATTACK NORMAL ---
	if event.is_action_pressed("attack"):
	
		slash_controller.try_attack()
		print("ATTCK")
		return

	# --- TP ---
	if tp_charges > 0:
		if event.is_action_pressed("shoot_tp"):
			is_charging = true
			aim_pcam.priority = 10
			charge_power = 0.0
			if trajectory_line:
				trajectory_line.visible = true
				update_trajectory_preview()
			set_outline(true)
			if animation_controller:
				animation_controller.start_aim_sequence()
		elif event.is_action_released("shoot_tp"):
			if is_charging:
				is_charging = false
				set_outline(false)
				if trajectory_line:
					trajectory_line.visible = false
					trajectory_line.clear_points()
				if animation_controller:
					animation_controller.end_aim_sequence()
				if charge_power >= min_power_threshold:
					var mouse_world_pos = get_viewport().get_camera_2d().get_global_mouse_position()
					shoot_tp(mouse_world_pos, charge_power)
					print(charge_power)
				charge_power = 0.0
				aim_pcam.priority = 0

func _cancel_tp_charge() -> void:
	is_charging = false
	charge_power = 0.0
	set_outline(false) 
	if trajectory_line:
		trajectory_line.visible = false
		trajectory_line.clear_points()
	aim_pcam.priority = 0
	if animation_controller and animation_controller.is_aiming():
		animation_controller.cancel_aim_sequence()
	
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
	if ChargeCam.priority > 0:
		ChargeCam.priority = 0
	landing_position.y = landing_position.y - 64.0
	if teleport_vfx_scene:
		var vfx_out = teleport_vfx_scene.instantiate()
		get_tree().current_scene.add_child(vfx_out)
		vfx_out.global_position = global_position
		vfx_out.setup(-1.0) # Dirección -1 para colapsar
	global_position = landing_position
	velocity = Vector2.ZERO
	
	if teleport_vfx_scene:
		var vfx_in = teleport_vfx_scene.instantiate()
		get_tree().current_scene.add_child(vfx_in)
		vfx_in.global_position = global_position
		vfx_in.setup(1.0) # Dirección 1 para expandir
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
	if invulnerable_timer > 0.0 or is_dead:
		return
	set_outline(false) 
	_slash_lunge_timer = 0.0           # ← reset
	_slash_lunge_velocity = 0.0
	
	if animation_controller and animation_controller.is_aiming():
		animation_controller.cancel_aim_sequence()
		_cancel_tp_charge()
	current_hits += 1
	invulnerable_timer = hit_invulnerability_time
	
	
	animation_controller.force_state(
		animation_controller.VisualState.HURT,
		hit_invulnerability_time
	)
	
	print("Golpe recibido: ", current_hits, "/", max_hits)
	flash_sprite(damage_flash_duration, damage_flash_color)
	if hits_display:
		hits_display.update_hits(current_hits)
	if current_hits >= max_hits:
		die()

func flash_sprite(duration: float, color: Color ) -> void:
	if sprite == null or sprite.material == null:
		return
	var mat := sprite.material as ShaderMaterial
	if mat == null:
		return
	
	# Matar el tween anterior si existe (para que golpes seguidos no se pisen)
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	
	# Setear color y arrancar el flash en 1.0
	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("flash_amount", 1.0)
	
	# Bajar de 1.0 a 0.0 durante `duration`
	_flash_tween = create_tween()
	_flash_tween.tween_method(
		func(v: float): mat.set_shader_parameter("flash_amount", v),
		1.0,   # desde
		0.0,   # hasta
		duration
	)
func die() -> void:
	set_outline(false) 
	_slash_lunge_timer = 0.0           # ← reset
	_slash_lunge_velocity = 0.0
	if animation_controller and animation_controller.is_aiming():
		animation_controller.cancel_aim_sequence()
	if animation_controller and animation_controller.is_in_sequence():
		animation_controller.cancel_sequence()
	current_hits = max_hits
	hits_display.update_hits(current_hits)
	is_dead = true
	velocity = Vector2.ZERO
	sprite.modulate = Color(1, 0, 0, 1)  # amarillo
	print("Jugador murió")
