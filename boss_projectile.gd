class_name BossProjectile
extends Area2D
## Proyectil del jefe. No necesita escena: el jefe lo crea con BossProjectile.new()
## PARRY: si lo golpeas con la espada, regresa hacia el jefe y le hace daño.

var direction := Vector2.RIGHT
var speed := 600.0
var damage := 1
var lifetime := 5.0
var radius := 14.0

var source: Boss = null            # el jefe que lo disparo (a quien regresa al hacer parry)
var reflect_damage := 40           # daño al jefe cuando regresa
var reflect_speed_mult := 1.6      # se acelera al ser devuelto
var reflected := false

var _visual: ColorRect


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0xFFFFF   # detecta todas las capas; abajo filtramos que hacer con cada cosa
	add_to_group("enemies")    # tu SlashController busca este grupo + take_damage()

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)

	_visual = ColorRect.new()   # cuadrito placeholder, cambialo por tu Sprite luego
	_visual.size = Vector2.ONE * radius * 2.0
	_visual.position = -_visual.size / 2.0
	_visual.color = Color(1.0, 0.7, 0.1)
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_visual)

	var timer := Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(queue_free)
	add_child(timer)

	_sync_slash_layer()
	body_entered.connect(_on_body_entered)


## Para que la espada (SlashHitbox) pueda detectar el proyectil, le damos las capas de su mascara.
func _sync_slash_layer() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var hb := player.get_node_or_null("SlashHitbox") as Area2D
	if hb == null:
		return
	var layers := hb.collision_mask & ~1
	if layers == 0:
		layers = hb.collision_mask
	collision_layer = layers


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


## Lo llama tu SlashController al golpearlo: take_damage(daño, direccion). Aqui hace el PARRY.
func take_damage(_amount = 1, _dir = null) -> void:
	if reflected:
		return
	reflected = true
	if is_instance_valid(source):
		var target := source.get_shoot_origin()   # regresa al centro del jefe
		direction = (target - global_position).normalized()
	else:
		direction = -direction
	speed *= reflect_speed_mult
	_visual.color = Color(0.2, 0.9, 1.0)   # cambia de color para que se vea que es tuyo


func _on_body_entered(body: Node2D) -> void:
	if reflected:
		# Devuelto: solo le hace daño al jefe (no al jugador).
		if body is Boss:
			body.take_damage(reflect_damage)
			queue_free()
		elif body is StaticBody2D or body is TileMapLayer or body is TileMap:
			queue_free()
		return

	if body.is_in_group("player"):
		Boss.apply_damage(body, damage)
		queue_free()
	elif body is StaticBody2D or body is TileMapLayer or body is TileMap:
		queue_free()   # choca con el piso/pared
