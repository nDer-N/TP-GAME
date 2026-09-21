extends Node

@export var attack_range: float = 70.0
@export var attack_damage: int = 40
@export var attack_cooldown: float = 0.2
@export var arc_angle_degrees: float = 100.0
@export var enemy_group: String = "enemies"
@export var breakable_group: String = "breakable"

@export var slash_animation_name: String = "slash"
@export var slash_offset_distance: float = 40.0
@export var slash_rotation_offset_degrees: float = 0.0   # <- nuevo

signal attack_performed(direction: Vector2)
signal attack_connected(didConnect: bool)

@onready var body: CharacterBody2D = get_parent()
@onready var slash_sprite: AnimatedSprite2D = get_parent().get_node("SlashEffect")
@onready var noise_emitter: PhantomCameraNoiseEmitter2D = $PhantomCameraNoiseEmitter2D

var cooldown_timer: float = 0.0
var is_attacking: bool = false


func _ready() -> void:
	slash_sprite.visible = false
	slash_sprite.sprite_frames.set_animation_loop(slash_animation_name, false)
	slash_sprite.animation_finished.connect(_on_slash_finished)


func attack_processing(delta: float) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta


func try_attack() -> void:
	if cooldown_timer > 0 or is_attacking:
		return
	
	cooldown_timer = attack_cooldown
	is_attacking = true
	
	var target = body.get_global_mouse_position()
	var origin = body.global_position
	var direction = (target - origin).normalized()
	
	attack_performed.emit(direction)
	
	slash_sprite.global_position = origin + direction * slash_offset_distance
	slash_sprite.rotation = direction.angle() + deg_to_rad(slash_rotation_offset_degrees)
	slash_sprite.visible = true
	slash_sprite.play(slash_animation_name)
	
	var arc_half_angle = deg_to_rad(arc_angle_degrees) / 2.0
	
	print("--- ATTACK ---")
	print("Enemies en grupo: ", get_tree().get_nodes_in_group(enemy_group).size())
	
	for enemy in get_tree().get_nodes_in_group(enemy_group):
		var to_enemy = enemy.global_position - origin
		var distance = to_enemy.length()
		var angle_to_enemy = direction.angle_to(to_enemy.normalized())
		
		print("Enemigo: ", enemy.name, " | distancia: ", distance, " | ángulo: ", rad_to_deg(angle_to_enemy))
		
		if distance > attack_range:
			print("  -> FUERA DE RANGO (range=", attack_range, ")")
			continue
		
		if abs(angle_to_enemy) <= arc_half_angle:
			print("  -> HIT!")
			if enemy.has_method("take_damage"):
				enemy.take_damage(attack_damage, direction)
				attack_connected.emit(true)
				noise_emitter.emit()
				HitStop.request(0.4)
				
				
		else:
			print("  -> FUERA DEL ARCO (arc_half=", rad_to_deg(arc_half_angle), ")")
		
	_hit_breakable_tiles(origin, direction, arc_half_angle)
			

func _hit_breakable_tiles(origin: Vector2, direction: Vector2, arc_half_angle: float) -> void:
	for layer in get_tree().get_nodes_in_group(breakable_group):
		if not (layer is TileMapLayer):
			continue

		for cell in layer.get_used_cells():
			var cell_world: Vector2 = layer.to_global(layer.map_to_local(cell))
			var to_cell = cell_world - origin
			var distance = to_cell.length()

			if distance > attack_range:
				continue

			var angle_to_cell = direction.angle_to(to_cell.normalized())
			if abs(angle_to_cell) <= arc_half_angle:
				layer.hit_cell(cell)



func _on_slash_finished() -> void:
	slash_sprite.visible = false
	is_attacking = false
