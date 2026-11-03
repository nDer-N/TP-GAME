extends Node

@export var attack_damage: int = 40
@export var attack_cooldown: float = 0.2
@export var enemy_group: String = "enemies"
@export var breakable_group: String = "breakable"

@export var slash_animation_name: String = "slash"
@export var slash_offset_distance: float = 40.0
@export var slash_rotation_offset_degrees: float = 0.0

## Delay (segundos) antes de aplicar el daño desde que se presiona el botón.
## Sirve para que el sprite del slash "llegue" visualmente al enemigo.
@export var hit_delay: float = 0.05

## Radio del arco (debe coincidir con el CollisionPolygon2D). Solo para romper tiles.
@export var hit_radius: float = 70.0
@export var hit_arc_degrees: float = 100.0
@export var hit_detect_Timer: float = 1.0

signal attack_performed(direction: Vector2)
signal attack_connected(didConnect: bool)

@onready var body: CharacterBody2D = get_parent()
@onready var slash_sprite: AnimatedSprite2D = get_parent().get_node("SlashEffect")
@onready var hitbox: Area2D = get_parent().get_node("SlashHitbox")
@onready var noise_emitter: PhantomCameraNoiseEmitter2D = $PhantomCameraNoiseEmitter2D

var cooldown_timer: float = 0.0
var is_attacking: bool = false
var hitTime: float = 0.0

var _pending_hit: bool = false
var _hit_delay_timer: float = 0.0
var _pending_direction: Vector2 = Vector2.ZERO

var _already_hit := {}
var _hit_active: bool = false
var _hit_any: bool = false


func _ready() -> void:
	slash_sprite.visible = false
	slash_sprite.sprite_frames.set_animation_loop(slash_animation_name, false)
	slash_sprite.animation_finished.connect(_on_slash_finished)
	hitbox.monitoring = false


func attack_processing(delta: float) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta

	if _pending_hit:
		_hit_delay_timer -= delta
		if _hit_delay_timer <= 0.0:
			_pending_hit = false
			_hit_active = true
			# Tiles: solo una vez, al empezar la ventana
			if _hit_breakable_tiles(_pending_direction):
				_register_hit()

	if _hit_active:
		_apply_hit()

	if hitTime > 0:
		hitTime -= delta
		if hitTime <= 0:
			hitbox.monitoring = false
			_hit_active = false
			if not _hit_any:
				attack_connected.emit(false)


func try_attack() -> void:
	if cooldown_timer > 0 or is_attacking:
		return
		
	_already_hit.clear()
	_hit_any = false

	cooldown_timer = attack_cooldown
	is_attacking = true
	hitTime = hit_detect_Timer

	var target = body.get_global_mouse_position()
	var origin = body.global_position
	var direction = (target - origin).normalized()

	attack_performed.emit(direction)

	# Posicionar y rotar el sprite del slash
	slash_sprite.global_position = origin + direction * slash_offset_distance
	slash_sprite.rotation = direction.angle() + deg_to_rad(slash_rotation_offset_degrees)
	slash_sprite.visible = true
	slash_sprite.play(slash_animation_name)

	# Posicionar y rotar el hitbox
	# El hitbox está centrado en el jugador; el CollisionPolygon2D ya está
	# dibujado con el origen en (0,0), así que solo hay que rotarlo.
	hitbox.global_position = origin
	hitbox.global_rotation = direction.angle() + deg_to_rad(slash_rotation_offset_degrees)

	# Activar monitoring para que el Area2D empiece a detectar overlaps
	hitbox.monitoring = true

	# Esperar el delay antes de aplicar daño (para que el sprite llegue visualmente)
	_pending_hit = true
	_hit_delay_timer = hit_delay
	_pending_direction = direction


func _apply_hit() -> void:
	var candidates: Array = hitbox.get_overlapping_bodies() + hitbox.get_overlapping_areas()
	for c in candidates:
			var target := _find_damageable(c)
			if target == null or _already_hit.has(target):
				continue
			_already_hit[target] = true
			target.take_damage(attack_damage, _pending_direction)
			_register_hit()
			
func _register_hit() -> void:
	_hit_any = true
	attack_connected.emit(true)
	noise_emitter.emit()
	HitStop.request(0.1)
	
func _find_damageable(node: Node) -> Node:
	var n: Node = node
	while n != null:
		if n.is_in_group(enemy_group) and n.has_method("take_damage"):
			return n
		n = n.get_parent()
	return null

func _hit_breakable_tiles(direction: Vector2) -> bool:
	var hit_something := false
	var arc_half_angle := deg_to_rad(hit_arc_degrees) / 2.0
	var origin := hitbox.global_position

	for layer in get_tree().get_nodes_in_group(breakable_group):
		if not (layer is TileMapLayer):
			continue

		for cell in layer.get_used_cells():
			var cell_world: Vector2 = layer.to_global(layer.map_to_local(cell))
			var to_cell := cell_world - origin
			var distance := to_cell.length()

			if distance > hit_radius:
				continue

			var angle_to_cell := direction.angle_to(to_cell.normalized())
			if abs(angle_to_cell) <= arc_half_angle:
				layer.hit_cell(cell)
				hit_something = true

	return hit_something


func _on_slash_finished() -> void:
	slash_sprite.visible = false
	is_attacking = false
