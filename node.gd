extends Node

@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.1
@export var first_jump_force: float = 600.0
@export var second_jump_force: float = 735.0

@onready var body: CharacterBody2D = get_parent()

var jumps_left: int = 2
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0


func jump_processing(delta: float) -> void:
	if body.is_on_floor():
		coyote_timer = coyote_time
		jumps_left = 2
	else:
		coyote_timer -= delta
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta
	
	if jump_buffer_timer > 0:
		try_jump()


func try_jump() -> void:
	if coyote_timer > 0 and jumps_left == 2:
		body.velocity.y = -first_jump_force
		jumps_left -= 1
		coyote_timer = 0
		jump_buffer_timer = 0
	elif jumps_left == 1:
		body.velocity.y = -second_jump_force
		jumps_left -= 1
		jump_buffer_timer = 0
