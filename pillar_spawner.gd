extends Node2D

@export var pillar_scene: PackedScene

## Cada cuánto aparece un pilar (segundos).
@export var interval: float = 3.0
@export var interval_variation: float = 1.0

## Velocidad del pilar hacia la izquierda (px/s).
@export var speed: float = 350.0
@export var speed_variation: float = 50.0

## Distancia a la derecha de la cámara donde aparece el pilar.
@export var spawn_distance_right: float = 1200.0

## Cuánto viaja el pilar antes de destruirse (px).
@export var travel_distance: float = 3500.0

## Altura de aparición (coordenadas del mundo).
@export var spawn_offset_y: float = 0.0
@export var y_variation: float = 0.0

## Escala aleatoria.
@export var min_scale: float = 1.0
@export var max_scale: float = 1.0

## Nodo donde se añaden los pilares. Si es null, usa el padre del spawner.
@export var world_parent: Node = null

var _timer: Timer
var _camera: Camera2D


func _ready() -> void:
	if pillar_scene == null:
		push_warning("PillarSpawner: pillar_scene no asignada.")
		return
	_camera = get_viewport().get_camera_2d()

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.wait_time = randf_range(0.5, 1.5)
	_timer.start()


func _process(_delta: float) -> void:
	# El spawner se pega a la cámara en X, mantiene su Y.
	if _camera:
		global_position.x = _camera.global_position.x


func _on_timer_timeout() -> void:
	_spawn_pillar()
	var next_wait := interval + randf_range(-interval_variation, interval_variation)
	_timer.wait_time = max(0.5, next_wait)
	_timer.start()


func _spawn_pillar() -> void:
	var pillar := pillar_scene.instantiate()

	# Añadir al mundo, NO al spawner (si no, se mueven con él).
	var parent := world_parent if world_parent != null else get_parent()
	parent.add_child(pillar)

	# Aparece a la derecha de la cámara, a la altura definida.
	var start_y := spawn_offset_y + randf_range(-y_variation, y_variation)
	var start_pos := Vector2(global_position.x + spawn_distance_right, start_y)
	pillar.global_position = start_pos

	if max_scale != min_scale:
		var s := randf_range(min_scale, max_scale)
		pillar.scale = Vector2(s, s)

	# Velocidad hacia la izquierda
	var vx := -(speed + randf_range(-speed_variation, speed_variation))
	var duration = travel_distance / abs(vx)
	var end_pos := start_pos + Vector2(vx * duration, 0.0)

	var tw := pillar.create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tw.tween_property(pillar, "global_position", end_pos, duration)
	tw.tween_callback(pillar.queue_free)
