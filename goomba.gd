extends CharacterBody2D

@export var speed: float = 80.0
@export var gravity: float = 980.0
@export var max_hp: int = 80

@export var knockback_force: float = 1000
@export var knockback_up_force: float = 400
@export var knockback_duration: float = 0.5

var direction: int = 1
var current_hp: int = max_hp
var is_dead: bool = false

var knockback_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	current_hp = max_hp


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if knockback_timer > 0:
		knockback_timer -= delta
		sprite.modulate = Color(0,1,0,1)
	else:
		velocity.x = direction * speed
		sprite.modulate = Color(1,1,1,1)
	
	move_and_slide()
	
	if knockback_timer <= 0 and is_on_wall():
		direction *= -1
		sprite.flip_h = direction < 0


func take_damage(amount: int, hit_direction: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	
	current_hp -= amount
	
	if current_hp <= 0:
		die()
		return
	
	if hit_direction != Vector2.ZERO:
		apply_knockback(hit_direction)


func apply_knockback(hit_direction: Vector2) -> void:
	knockback_timer = knockback_duration
	velocity.x = hit_direction.x * knockback_force
	velocity.y = -knockback_up_force


func die() -> void:
	is_dead = true
	queue_free()
