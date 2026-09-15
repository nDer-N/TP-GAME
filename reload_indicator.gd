extends Node2D

@export var radius: float = 30.0
@export var width: float = 5.0
@export var offset: Vector2 = Vector2(50, -20)  # a la derecha y un poco arriba
@export var bg_color: Color = Color(0.2, 0.25, 0.5, 0.6)
@export var fill_color: Color = Color(0.35, 0.55, 1.0, 1.0)

@onready var player: CharacterBody2D = get_parent()

func _ready() -> void:
	z_index = 4096
	z_as_relative = false

func _process(_delta: float) -> void:
	visible = player.is_recharging
	queue_redraw()

func _draw() -> void:
	if not player.is_recharging:
		return
	
	var progress = player.recharge_timer / player.recharge_hold_time
	var start_angle = -PI / 2.0
	var end_angle = start_angle + TAU * progress
	
	draw_arc(offset, radius, 0, TAU, 64, bg_color, width)
	draw_arc(offset, radius, start_angle, end_angle, 64, fill_color, width)
