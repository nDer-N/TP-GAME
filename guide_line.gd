extends Node2D  # o el nodo donde quieras dibujar la línea

@export var dash_length: float = 6.0
@export var gap_length: float = 8.0
@export var line_color: Color = Color(1, 1, 1, 0.15)

@onready var player: CharacterBody2D = get_parent()  # ajusta según tu jerarquía

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var start = player.global_position
	var end = get_global_mouse_position()
	draw_dashed_line(to_local(start), to_local(end), line_color, 1.0, dash_length)
