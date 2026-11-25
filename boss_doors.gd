extends Node2D
## Cierra las puertas del vagón del jefe al entrar el jugador
## y las abre cuando el jefe muere.

@export_group("Nodos")
@export var triggers: Array[Area2D] = []
@export var doors: Array[Node2D] = []
@export var boss: Node
## OPCIONAL: arrastra aquí a tu jugador para que sea lo único que active las puertas.
## Si lo dejas vacío, cualquier CharacterBody2D/RigidBody2D que no sea el jefe cuenta.
@export var player: Node
## Nombres de señal que se intentarán para detectar la muerte del jefe.
@export var boss_death_signals: PackedStringArray = ["died", "defeated", "boss_died", "dead", "killed", "death"]

@export_group("Depuración")
## Imprime información en la salida.
@export var debug_print: bool = true
## Con F1 cierras las puertas a mano para probar (quítalo cuando todo funcione).
@export var debug_key_f1: bool = true
## Las zonas detectan cuerpos de TODAS las capas (evita problemas de máscara).
@export var detect_all_layers: bool = true
## Las puertas ocupan TODAS las capas, así el jugador no las atraviesa
## aunque su máscara sea distinta.
@export var doors_on_all_layers: bool = true

@export_group("Animación")
## Segundos que pasan desde que el jugador entra hasta que se cierran las puertas.
@export var close_delay: float = 3.0
## Dónde están las puertas abiertas, relativo a su posición cerrada.
## (0, -200) = arriba. Pon (-200, 0) para que se deslicen a un lado.
@export var open_offset: Vector2 = Vector2(0, -200)
## Calcula solo cuánto subir según el alto de cada puerta (recomendado).
## Si la desactivas se usa Open Offset tal cual.
@export var auto_open_distance: bool = true
## Píxeles extra que sube de más, para que quede bien escondida.
@export var open_extra: float = 60.0
## Oculta la puerta cuando está abierta del todo.
@export var hide_when_open: bool = true
@export var close_time: float = 0.45
@export var open_time: float = 0.9
## Espera tras morir el jefe antes de abrir.
@export var open_delay: float = 1.0

@export_group("Sonido")
@export var close_sound: AudioStream
@export var open_sound: AudioStream
@export var sound_volume_db: float = 0.0
## Retraso del sonido de cerrar, para que coincida con el golpe.
@export var close_sound_delay: float = 0.2

var _closed_pos: Dictionary = {}
var _open_pos: Dictionary = {}
var _closed: bool = false
var _boss_dead: bool = false
var _pending: bool = false
var _tween: Tween
var _sfx: AudioStreamPlayer


func _ready() -> void:
	_sfx = AudioStreamPlayer.new()
	_sfx.volume_db = sound_volume_db
	add_child(_sfx)

	# Las puertas empiezan abiertas y sin colisión
	for d in doors:
		_closed_pos[d] = d.position
		_open_pos[d] = d.position + _open_offset_for(d)
		d.position = _open_pos[d]
		d.visible = not hide_when_open
		if doors_on_all_layers and d is CollisionObject2D:
			d.collision_layer = 0xFFFFFFFF
		_set_door_collision(d, false)

	for t in triggers:
		t.monitoring = true
		if detect_all_layers:
			t.collision_mask = 0xFFFFFFFF
		t.body_entered.connect(_on_body_entered)
		if debug_print:
			print("BossDoors: zona '", t.name, "' en ", t.global_position)

	if debug_print:
		print("BossDoors: LISTO. zonas=", triggers.size(), " puertas=", doors.size(), " jefe=", boss)

	_connect_boss()


func _connect_boss() -> void:
	if boss == null:
		push_warning("BossDoors: no asignaste el jefe en el Inspector.")
		return
	if not is_instance_valid(boss):
		_boss_dead = true
		return

	# Señal de muerte, si el jefe tiene alguna de las conocidas
	for sig_name in boss_death_signals:
		if boss.has_signal(sig_name):
			var argc: int = 0
			for s in boss.get_signal_list():
				if s["name"] == sig_name:
					argc = s["args"].size()
					break
			boss.connect(sig_name, _on_boss_died.unbind(argc), CONNECT_ONE_SHOT)
			if debug_print:
				print("BossDoors: conectado a la señal '", sig_name, "' del jefe")
			break

	# Respaldo: si el jefe se elimina de la escena, también cuenta
	boss.tree_exiting.connect(_on_boss_died, CONNECT_ONE_SHOT)


func _physics_process(_delta: float) -> void:
	# Cubre el caso de que el jugador ya esté dentro de la zona al empezar
	# (por ejemplo, al reaparecer en un checkpoint).
	if _closed or _boss_dead:
		return
	for t in triggers:
		for b in t.get_overlapping_bodies():
			if _is_player(b):
				_request_close()
				return


func _unhandled_input(event: InputEvent) -> void:
	if not debug_key_f1:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		if debug_print:
			print("BossDoors: F1 -> cerrando a mano")
		_close_doors()


func _on_body_entered(body: Node) -> void:
	if debug_print:
		print("BossDoors: tocó ", body.name, " (", body.get_class(), ")")
	if _closed or _boss_dead:
		return
	if not _is_player(body):
		return
	_request_close()


func _is_player(body: Node) -> bool:
	# Si asignaste al jugador, solo él cuenta
	if player != null and is_instance_valid(player):
		return body == player or player.is_ancestor_of(body)
	# Si no, cualquier cuerpo con movimiento que no sea el jefe
	if not (body is CharacterBody2D or body is RigidBody2D):
		return false
	if boss != null and is_instance_valid(boss):
		if body == boss or boss.is_ancestor_of(body):
			return false
	return true


func _request_close() -> void:
	# Da unos segundos de margen antes de cerrar.
	if _closed or _pending or _boss_dead:
		return
	_pending = true
	if debug_print:
		print("BossDoors: jugador dentro, cerrando en ", close_delay, " s")
	if close_delay > 0.0:
		await get_tree().create_timer(close_delay).timeout
	_pending = false
	if not is_inside_tree() or _boss_dead:
		return
	_close_doors()


func _close_doors() -> void:
	if _closed:
		return
	_closed = true
	if debug_print:
		print("BossDoors: CERRANDO puertas")
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	for d in doors:
		d.visible = true
		_set_door_collision(d, true)   # bloquea de inmediato
		_tween.tween_property(d, "position", _closed_pos[d], close_time)

	_play_sound(close_sound, close_sound_delay)


func _on_boss_died() -> void:
	if _boss_dead or not is_inside_tree():
		return
	_boss_dead = true
	if debug_print:
		print("BossDoors: el jefe murió")
	if not _closed:
		return

	await get_tree().create_timer(open_delay).timeout
	if not is_inside_tree():
		return
	_open_doors()


func _open_doors() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	for d in doors:
		_tween.tween_property(d, "position", _open_pos[d], open_time)

	_play_sound(open_sound, 0.0)
	await _tween.finished
	for d in doors:
		_set_door_collision(d, false)
		d.visible = not hide_when_open
	_closed = false


func _open_offset_for(door: Node2D) -> Vector2:
	if not auto_open_distance:
		return open_offset
	var h: float = _door_height(door)
	if h <= 0.0:
		return open_offset
	return Vector2(0.0, -(h + open_extra))


func _door_height(door: Node2D) -> float:
	var h: float = 0.0
	# Alto del sprite (o de varios sprites)
	for sp in door.find_children("*", "Sprite2D", true, false):
		var sprite := sp as Sprite2D
		var sprite_h: float = sprite.get_rect().size.y * absf(sprite.scale.y) * absf(door.scale.y)
		h = maxf(h, sprite_h + absf(sprite.position.y) * absf(door.scale.y))
	# Alto de la colisión, por si no hay sprite
	if h <= 0.0:
		for cs in door.find_children("*", "CollisionShape2D", true, false):
			var shape: Shape2D = (cs as CollisionShape2D).shape
			if shape is RectangleShape2D:
				h = maxf(h, (shape as RectangleShape2D).size.y * absf(door.scale.y))
	return h


func _set_door_collision(door: Node, enabled: bool) -> void:
	for c in door.find_children("*", "CollisionShape2D", true, false):
		c.set_deferred("disabled", not enabled)


func _play_sound(stream: AudioStream, delay: float) -> void:
	if stream == null:
		return
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	_sfx.stream = stream
	_sfx.play()
