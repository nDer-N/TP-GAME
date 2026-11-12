class_name Boss
extends CharacterBody2D
## Primer jefe: 2 fases.
## Fase 1: Disparo a distancia + Salto (tras disparar OBLIGATORIAMENTE salta antes de volver a disparar).
## Fase 2 (<= 40% de vida): Disparo doble + Doble salto + Dash lateral.

signal phase_changed(new_phase: int)
signal health_changed(current: int, maximum: int)
signal died

enum Attack { SHOOT, JUMP, DASH }
enum BarPosition { TOP_CENTER, BOTTOM_CENTER, TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT }

## Metodos que se intentaran llamar en el jugador para dañarlo (en orden).
const DAMAGE_METHODS := ["take_hit", "take_damage", "hit", "damage", "hurt"]

@export_group("Vida")
## Tu espada pega 40 por golpe: 400 de vida = 10 golpes.
@export var max_health := 400
## Cuando la vida baja a este porcentaje empieza la fase 2 (0.4 = 40%).
@export_range(0.0, 1.0) var phase2_threshold := 0.4

@export_group("Arena")
## La arena va desde (x del jefe - esto) hasta (x del jefe + esto). Coloca el jefe en el CENTRO de la arena.
@export var arena_half_width := 700.0
## El combate empieza cuando el jugador entra a la arena y esta a esta altura maxima de diferencia.
@export var activation_height := 700.0
## Si es true, el salto SIEMPRE cae donde esta el jugador aunque este fuera de la arena (y la arena se amplia hasta ahi).
## Si es false, el aterrizaje se limita a los bordes de la arena (el jefe puede saltar "en su lugar" si el jugador esta fuera).
@export var jump_can_leave_arena := true

@export_group("Daño")
@export var contact_damage := 1
@export var projectile_damage := 1

@export_group("Parry")
## Daño que le hace al jefe un proyectil devuelto con la espada.
@export var parry_damage := 40
@export var parry_speed_multiplier := 1.6

@export_group("Barra de vida")
@export var show_health_bar := true
@export var boss_name := "JEFE"
@export var bar_name_font_size := 20
@export var show_bar_text := true                       # el "275 / 275"
@export var show_phase_tick := true                     # marca de la fase 2
@export_subgroup("Posicion y tamaño")
@export var bar_position := BarPosition.BOTTOM_CENTER
@export_range(0.1, 1.0) var bar_width_ratio := 0.5      # ancho respecto a la pantalla
@export var bar_height := 22.0
@export var bar_margin := Vector2(40, 40)               # separacion del borde de la pantalla
@export var bar_extra_offset := Vector2.ZERO            # ajuste fino extra en pixeles
@export_subgroup("Diseño")
@export var bar_background_texture: Texture2D           # fondo (vacio = color)
@export var bar_background_color := Color(0.05, 0.05, 0.05, 0.9)
@export var bar_fill_texture: Texture2D                 # relleno (vacio = color)
@export var bar_fill_color := Color(0.85, 0.1, 0.1)
@export var bar_trail_texture: Texture2D                # estela de daño (vacio = color)
@export var bar_trail_color := Color(1.0, 0.85, 0.3)
@export var bar_frame_texture: Texture2D                # marco opcional encima de la barra
@export var bar_frame_padding := Vector2(8, 8)          # cuanto sobresale el marco

@export_group("Alerta de disparo fuera de pantalla")
@export var offscreen_alert_enabled := true
## Arrastra aqui tu propio dibujo para cambiar el diseño. Vacio = usa el texto "?".
@export var alert_texture: Texture2D
@export var alert_tint := Color.WHITE                 # color aplicado a tu dibujo
@export var alert_text := "?"
@export var alert_font_size := 72
@export var alert_color := Color(1.0, 0.85, 0.2)
@export var alert_size := Vector2(64, 64)
@export var alert_edge_margin := 30.0                 # distancia al borde de la pantalla
@export var alert_pulse := true                       # late para que se note

@export_group("Disparo")
## Si es true, el proyectil sale del CENTRO del cuerpo del jefe (y el parry regresa ahi). Si es false usa muzzle_offset.
@export var shoot_from_center := true
@export var muzzle_offset := Vector2(0, -80)   # solo si shoot_from_center = false (respecto a los pies del jefe)
@export var aim_offset := Vector2(0, -40)      # a que parte del jugador apunta
@export var projectile_speed := 1600.0         # antes 600
@export var projectile_speed_phase2 := 1900.0  # antes 800
@export var double_shot_delay := 1.0           # retraso entre los 2 proyectiles del disparo doble
@export var shoot_charge := 0.7                # aviso antes de disparar
@export var shoot_charge_phase2 := 0.45

@export_group("Salto")
@export var gravity := 2400.0
@export var jump_time := 0.8                   # duracion del vuelo (segundos)
@export var jump_time_phase2 := 0.6
@export var jump_windup := 0.7                 # aviso: la marca roja te sigue durante este tiempo
@export var jump_windup_phase2 := 0.5
@export var second_jump_windup := 0.3
@export var impact_duration := 0.2             # tiempo que dura el daño al aterrizar

@export_group("Dash")
@export var dash_speed := 1500.0
@export var dash_windup := 0.7                 # tiempo de aviso antes de embestir
## Aviso antes del dash: el jefe TIEMBLA, parpadea y se marca el recorrido en el piso.
@export var dash_show_warning := true
@export var dash_shake_pixels := 8.0           # cuanto tiembla durante el aviso
@export var dash_passes := 2                   # 2 = cruza la arena de ida y vuelta
## El dash se mueve por codigo e IGNORA plataformas y paredes (no se atora), pero se detiene antes de un vacio.
@export var dash_stop_at_edges := true
@export var dash_edge_margin := 50.0            # distancia de seguridad antes del borde (pixeles)

@export_group("Efectos del dash")
@export var dash_vfx := true                   # polvo, escombros y explosion al arrancar/frenar
@export var dash_afterimages := true           # estela de copias del jefe
@export var dust_color := Color(0.6, 0.5, 0.42, 0.8)
@export var debris_color := Color(0.28, 0.16, 0.1, 1.0)

@export_group("Efectos del salto")
@export var jump_vfx := true                   # polvo, escombros y explosion al despegar/aterrizar
@export var jump_afterimages := true           # estela de copias del jefe mientras vuela
@export var jump_cracks := true                # grietas temporales en el piso al aterrizar
@export var crack_only_on_ground := true       # las grietas se cortan donde el piso se termina (no salen al aire)
@export var crack_max_depth := 80.0            # hasta que profundidad bajan (que no pasen del grosor de la plataforma)
@export var crack_count := 6                   # cuantas grietas salen del impacto
@export var crack_length := 190.0              # largo maximo de cada grieta (pixeles)
@export var crack_lifetime := 3.0              # segundos que se quedan las grietas antes de desvanecerse
@export var crack_fade_time := 1.0             # lo que tardan en desvanecerse
@export var crack_color := Color(0.06, 0.03, 0.02, 1.0)
@export var crack_glow_color := Color(1.0, 0.45, 0.1, 0.9)   # brillo naranja dentro de la grieta
@export var crack_z_index := 10                # que tan "arriba" se dibujan (subelo si el arte del piso las tapa)
@export var jump_camera_shake := 12.0          # fuerza del temblor de camara al aterrizar (0 = nada)

@export_group("Animaciones")
@export var animation_controller: Node

@export_group("Cinematica fase 2")
@export var cinematic_enabled := true
## Marker2D sobre la SUPERFICIE de la plataforma de la IZQUIERDA (donde queda el jugador).
@export var cinematic_player_spot: Node2D
## Marker2D sobre la SUPERFICIE de la plataforma de la DERECHA (donde cae el jefe).
@export var cinematic_boss_spot: Node2D
## Si es true, la cinematica solo se ve la primera vez (no cada vez que mueres y reinicias).
@export var cinematic_only_first_time := false
@export var cinematic_windup := 0.4               # aviso antes de que salten los dos
@export var cinematic_jump_time := 0.8            # duracion del salto de ambos
@export var cinematic_pause_after_land := 0.5
@export var cinematic_aim_time := 0.7             # cuanto tiempo apunta el jugador
@export var cinematic_release_delay := 0.1        # de que empieza el disparo a que sale el tp
@export var cinematic_tp_flight_time := 0.45
@export var cinematic_tp_offset := Vector2(0, -40)   # desde donde sale el tp (respecto al jugador)
## Tu dibujo del tp. Vacio = un circulo de color.
@export var cinematic_tp_texture: Texture2D
@export var cinematic_tp_color := Color(0.0, 1.0, 0.9)
@export var cinematic_tp_size := 36.0
@export var cinematic_break_pop_delay := 0.3      # en que momento de "break_tp" se rompe el tp
@export var cinematic_pause_before_scream := 0.3
## AJUSTE DE CÁMARA: Mueve este valor en Y para subir/bajar el encuadre del jefe. (0 = centro, -80 = más arriba)
@export var cinematic_camera_offset := Vector2(0, -80)
## ARRASTRA AQUÍ TU RECURSO PhantomCameraTween (.res o .tres) para las transiciones.
@export var cinematic_tween: Resource

@export_group("Musica")
## Arrastra aqui tu cancion (.mp3, .ogg o .wav). Vacio = sin musica. Para quitarla/cambiarla solo cambia este campo.
@export var boss_music: AudioStream
@export_range(-40.0, 6.0) var music_volume_db := -6.0
@export var music_fade_in := 1.5
@export var music_fade_out := 2.0
@export var music_loop := true                 # que se repita mientras dure la pelea
@export var music_bus := "Master"
## Opcional: nombre del bus de la musica normal del nivel para bajarle el volumen durante el jefe (vacio = no tocar nada).
@export var duck_bus := ""
@export var duck_amount_db := -40.0

@export_group("Moverse entre plataformas")
## Cada cierto tiempo el jefe salta a otra plataforma (o al piso) para no quedarse siempre en el mismo lugar.
@export var reposition_enabled := true
@export_range(0.0, 1.0) var reposition_chance := 0.3    # probabilidad de moverse antes de cada ataque
@export var reposition_min_attacks := 2                  # minimo de ataques entre un movimiento y otro
@export var reposition_windup := 0.6                     # aviso antes de saltar (se marca donde caera)
@export var reposition_max_up := 450.0                   # hasta que altura puede subir (pixeles)
@export var reposition_max_down := 700.0                 # hasta que profundidad puede bajar
@export var reposition_min_distance := 250.0             # distancia minima horizontal respecto a donde esta
@export var reposition_scan_step := 40.0                 # cada cuantos pixeles busca plataformas

@export_group("Anti-spam (onda de choque)")
## Si le pegan `spam_hits_needed` golpes seguidos sin que se haya movido, suelta una onda que empuja al jugador y se mueve.
@export var spam_defense_enabled := true
@export var spam_hits_needed := 8
@export var spam_window := 6.0                           # los golpes tienen que ser dentro de estos segundos
@export var spam_position_tolerance := 200.0             # si se mueve mas que esto, el conteo se reinicia
@export var shockwave_windup := 0.8                      # aviso antes de la onda (tiembla y brilla)
@export var shockwave_speed := 1000.0
@export var shockwave_range := 900.0                     # hasta donde llega a cada lado
@export var shockwave_height := 70.0                     # altura de la onda (se puede saltar por encima)
@export var shockwave_damage := 1
@export var shockwave_push_distance := 420.0             # cuanto empuja al jugador
@export var shockwave_color := Color(1.0, 0.85, 0.5, 0.85)

@export_group("Variedad (fase 2)")
## Maximo de veces SEGUIDAS que puede repetir el mismo ataque en fase 2 (2 = puede hacerlo dos veces y luego cambia).
@export var max_repeats_phase2 := 2
## Si es true, cada cruce del dash cuenta como un uso (con 2 cruces, un dash ya agota el limite y el siguiente ataque cambia).
@export var dash_passes_count_as_repeats := true

@export_group("Ritmo")
## Tiempo entre ataques. Durante este tiempo el jefe PERSIGUE al jugador, nunca se queda quieto.
@export var rest_time := 0.5
@export var rest_time_phase2 := 0.2

@export_group("Persecucion")
@export var chase_speed := 220.0
@export var chase_speed_phase2 := 340.0
@export var chase_stop_distance := 180.0

@export_group("Debug")
## F1 = quita 40 de vida al jefe (como un golpe de espada) (para probar la fase 2). Desactivalo al terminar.
@export var debug_keys := true

@export var cinematic_pivot: Node2D



var health := 0
var phase := 1
var active := false

# --- Reinicio del jefe cuando mata al jugador ---
var _dead := false
var _fight_over := false        # true mientras se aborta el combate por reinicio
var _resetting := false
var _loop_running := false
var _start_position := Vector2.ZERO
var _start_arena_left := 0.0
var _start_arena_right := 0.0

## "dead" es true si el jefe murio O mientras se aborta el combate por reinicio.
## Asi TODAS las comprobaciones "if dead: return" cortan los ataques en curso sin tocarlas.
var dead: bool:
	get:
		return _dead or _fight_over
	set(v):
		_dead = v

var _last_attack := -1
var _repeat_count := 0          # cuantas veces seguidas se ha usado el mismo ataque
var _hit_this_attack := false
var _scripted := false          # true mientras el salto mueve al jefe por codigo (atraviesa todo)
var _exceptions_done := false
var _warned_clamp := false
var _music_player: AudioStreamPlayer
var _music_tween: Tween
var _duck_original_db := 0.0
var _ducked := false
var _recent_hits: Array[float] = []
var _spam_anchor := Vector2.ZERO
var _attacks_since_move := 0
var _push_prev := 0.0
var _player: Node2D
var _arena_left := 0.0
var _arena_right := 0.0
var _marker: ColorRect
var _dash_marker: ColorRect
var _dash_dust: CPUParticles2D
var _dash_debris: CPUParticles2D
var _ghost_timer := 0.0
var _visual_base_pos := Vector2.ZERO
var _bar_root: Control
var _bar_fill: Control
var _bar_trail: Control
var _bar_label: Label
var _bar_tween: Tween
var _bar_inner: Array[Control] = []
var _alert_root: Control
var _alert_active := false
var _cinematic_active := false
var _cinematic_seen := false
var _cine_tp: Node2D
var _cine_falling := false
var _cine_temp_cam: Camera2D # Cámara exclusiva para la cinemática

@onready var visual: ColorRect = $Visual
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D



func _ready() -> void:
	health = max_health
	_visual_base_pos = visual.position
	_arena_left = global_position.x - arena_half_width
	_arena_right = global_position.x + arena_half_width
	# Guardamos el estado original para el reinicio
	_start_position = global_position
	_start_arena_left = _arena_left
	_start_arena_right = _arena_right
	_hook_death_signals(get_node_or_null("/root/Events"), ["player_died", "player_dead", "player_death"])
	add_to_group("boss")
	add_to_group("enemies")
	# El daño al jugador se calcula por codigo; el Area2D solo se usa para definir el tamaño.
	damage_area.monitoring = false
	damage_area.monitorable = false
	if show_health_bar:
		_build_health_bar()


func _process(_delta: float) -> void:
	if _alert_active:
		_alert_update()
	_check_player_dead()

var _player_was_dead := false

## Vigila la variable is_dead del jugador y reinicia el combate cuando muere.
func _check_player_dead() -> void:
	var dead_now: bool = is_instance_valid(_player) and "is_dead" in _player and _player.is_dead
	var was_dead := _player_was_dead
	_player_was_dead = dead_now
	if not active or _resetting:
		return
	if not is_instance_valid(_player) or not _player.is_inside_tree():
		reset_fight()
		return
	if dead_now and not was_dead:
		reset_fight()


func _physics_process(delta: float) -> void:
	if dead or _scripted:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()
	global_position.x = clampf(global_position.x, _arena_left, _arena_right)

	if not active:
		var p := _get_player()
		if p and not ("is_dead" in p and p.is_dead) \
				and p.global_position.x >= _arena_left and p.global_position.x <= _arena_right \
				and absf(p.global_position.y - global_position.y) <= activation_height:
			active = true
			_show_health_bar()
			_boss_cam_on()
			_music_start()
			_attack_loop()


func _unhandled_input(event: InputEvent) -> void:
	if debug_keys and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			take_damage(40)


# ---------------------------------------------------------------- REINICIO (el jefe gano)

## Conecta (sin importar cuantos argumentos tenga la señal) las señales de muerte que existan en `obj`.
func _hook_death_signals(obj: Object, names: Array) -> void:
	if obj == null:
		return
	for s in obj.get_signal_list():
		if s.name in names:
			var c := _on_player_died.unbind(s.args.size())
			if not obj.is_connected(s.name, c):
				obj.connect(s.name, c)


func _on_player_died() -> void:
	reset_fight()


## Llamala cuando el jugador muera (si no usas ninguna de las señales de arriba):
## el jefe se cura por completo, vuelve a su lugar original y espera a que el jugador regrese.
func reset_fight() -> void:
	if _dead or _resetting or not active:
		return
	_resetting = true
	_fight_over = true      # corta todos los ataques en curso (ver "dead")

	# Espera a que el bucle de ataques termine solo (maximo 3 s por seguridad).
	var waited := 0.0
	while _loop_running and waited < 3.0:
		await _next_frame()
		waited += get_physics_process_delta_time()

	# Limpieza de efectos y estados
	_cinematic_end()
	_alert_active = false
	_alert_hide()
	_hide_marker()
	_hide_dash_path()
	_dash_vfx_stop(0.0, false)
	_scripted = false
	_hit_this_attack = false
	velocity = Vector2.ZERO
	visual.position = _visual_base_pos
	visual.modulate = Color.WHITE
	visual.self_modulate = Color.WHITE

	# Musica, camara y barra
	_music_stop()
	_boss_cam_off()
	if _bar_root:
		_bar_root.visible = false

	# Vida, fase y memoria de ataques
	health = max_health
	phase = 1
	_last_attack = -1
	_repeat_count = 0
	_attacks_since_move = 0
	_recent_hits.clear()
	health_changed.emit(health, max_health)
	_update_health_bar(false)

	# Posicion y arena originales
	global_position = _start_position
	_arena_left = _start_arena_left
	_arena_right = _start_arena_right

	if animation_controller:
		animation_controller.is_phase_2 = false
		animation_controller.set_state(animation_controller.VisualState.IDLE)

	active = false          # volvera a pelear cuando el jugador entre otra vez a la arena
	_fight_over = false
	_resetting = false


# ---------------------------------------------------------------- VIDA

func take_damage(amount = 1, a = null, _b = null) -> void:
	if dead or _cinematic_active:
		return
	if not (a is String and a == "parry"):
		_register_hit()
	var dmg := 1
	if amount is int or amount is float:
		dmg = maxi(int(amount), 1)
	health = maxi(health - dmg, 0)
	health_changed.emit(health, max_health)
	_update_health_bar()
	_flash_hit()
	
	if animation_controller:
		animation_controller.force_state(animation_controller.VisualState.HURT, 0.3)
		
	if health == 0:
		_die()


# Alias: tu espada / proyectil puede llamar a cualquiera de estos nombres.
func hit(amount = 1, a = null, b = null) -> void:
	take_damage(amount, a, b)

func take_hit(amount = 1, a = null, b = null) -> void:
	take_damage(amount, a, b)

func damage(amount = 1, a = null, b = null) -> void:
	take_damage(amount, a, b)

func hurt(amount = 1, a = null, b = null) -> void:
	take_damage(amount, a, b)

func on_hit(amount = 1, a = null, b = null) -> void:
	take_damage(amount, a, b)

func receive_damage(amount = 1, a = null, b = null) -> void:
	take_damage(amount, a, b)


func _flash_hit() -> void:
	var tw := create_tween()
	visual.self_modulate = Color(3, 3, 3)
	tw.tween_property(visual, "self_modulate", Color.WHITE, 0.12)


func _die() -> void:
	dead = true
	_alert_active = false
	_alert_hide()
	
	if animation_controller:
		animation_controller.force_state(animation_controller.VisualState.DEATH)
		
	velocity = Vector2.ZERO
	_hide_marker()
	_boss_cam_off()
	_hide_dash_path()
	_dash_vfx_stop(0.0, false)
	_music_stop()
	visual.position = _visual_base_pos
	died.emit()
	_hide_health_bar()
	# Avisa a tu sistema de eventos (camara HitCAM, etc.), igual que los demas enemigos.
	var events := get_node_or_null("/root/Events")
	if events and events.has_signal("enemy_died"):
		events.emit_signal("enemy_died")
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.5)
	await tw.finished
	queue_free()


# ---------------------------------------------------------------- MUSICA DE JEFE

## Empieza la musica cuando arranca el combate (con fade in).
func _music_start() -> void:
	if boss_music == null or _music_player != null:
		return
	var stream := boss_music.duplicate() as AudioStream
	if music_loop:
		if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
			stream.loop = true
		elif stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_player = AudioStreamPlayer.new()
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS   # no se pausa con el hit stop
	if not get_tree().process_frame.is_connected(_music_sync_pitch):
		get_tree().process_frame.connect(_music_sync_pitch)
	_music_player.stream = stream
	_music_player.bus = music_bus
	_music_player.volume_db = -60.0
	get_parent().add_child(_music_player)      # fuera del jefe para que pueda terminar su fade out cuando muera
	_music_player.play()
	_music_tween = _music_player.create_tween()
	_music_tween.tween_property(_music_player, "volume_db", music_volume_db, music_fade_in)
	_duck_set(true)


## Compensa Engine.time_scale para que la musica siempre suene a velocidad normal durante el hit stop.
func _music_sync_pitch() -> void:
	if _music_player and is_instance_valid(_music_player):
		_music_player.pitch_scale = clampf(1.0 / maxf(Engine.time_scale, 0.05), 0.01, 4.0)


## Termina la musica (con fade out) cuando el jefe muere.
func _music_stop() -> void:
	_duck_set(false)
	if get_tree().process_frame.is_connected(_music_sync_pitch):
		get_tree().process_frame.disconnect(_music_sync_pitch)
	if _music_player == null or not is_instance_valid(_music_player):
		return
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	var player := _music_player
	_music_player = null
	player.pitch_scale = 1.0
	var tw := player.create_tween()
	tw.tween_property(player, "volume_db", -60.0, music_fade_out)
	tw.finished.connect(player.queue_free)


## Baja (o restaura) el volumen del bus de la musica normal del nivel.
func _duck_set(on: bool) -> void:
	if duck_bus.is_empty():
		return
	var idx := AudioServer.get_bus_index(duck_bus)
	if idx < 0:
		return
	if on and not _ducked:
		_duck_original_db = AudioServer.get_bus_volume_db(idx)
		_ducked = true
		AudioServer.set_bus_volume_db(idx, _duck_original_db + duck_amount_db)
	elif not on and _ducked:
		_ducked = false
		AudioServer.set_bus_volume_db(idx, _duck_original_db)


## Si el jefe desaparece sin morir (reinicio de nivel, etc.) no dejamos la musica ni el bus alterados.
func _exit_tree() -> void:
	_duck_set(false)
	if is_inside_tree() and get_tree().process_frame.is_connected(_music_sync_pitch):
		get_tree().process_frame.disconnect(_music_sync_pitch)
	if _music_player and is_instance_valid(_music_player):
		_music_player.queue_free()


# ---------------------------------------------------------------- BARRA DE VIDA

func _build_health_bar() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	_bar_root = Control.new()
	_bar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_bar_layout()
	_bar_root.visible = false
	layer.add_child(_bar_root)
	_bar_root.resized.connect(_sync_bar_inner)

	_make_bar_layer(bar_background_texture, bar_background_color, false)
	# Barra "fantasma": se queda un momento para que veas cuanta vida acabas de quitar.
	_bar_trail = _make_bar_layer(bar_trail_texture, bar_trail_color, true)
	_bar_fill = _make_bar_layer(bar_fill_texture, bar_fill_color, true)

	# Marca del 40% (donde empieza la fase 2).
	if show_phase_tick:
		var tick := ColorRect.new()
		tick.color = Color(1, 1, 1, 0.85)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick.anchor_left = phase2_threshold
		tick.anchor_right = phase2_threshold
		tick.anchor_top = 0.0
		tick.anchor_bottom = 1.0
		tick.offset_left = -1.0
		tick.offset_right = 1.0
		_bar_root.add_child(tick)

	if bar_frame_texture:
		var fr := TextureRect.new()
		fr.texture = bar_frame_texture
		fr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fr.stretch_mode = TextureRect.STRETCH_SCALE
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bar_root.add_child(fr)
		fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fr.offset_left = -bar_frame_padding.x
		fr.offset_right = bar_frame_padding.x
		fr.offset_top = -bar_frame_padding.y
		fr.offset_bottom = bar_frame_padding.y

	var title := Label.new()
	title.text = boss_name
	title.position = Vector2(0, -bar_name_font_size - 10)
	title.add_theme_font_size_override("font_size", bar_name_font_size)
	_bar_root.add_child(title)

	_bar_label = Label.new()
	_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_label.visible = show_bar_text
	_bar_root.add_child(_bar_label)
	_bar_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_update_health_bar(false)
	_sync_bar_inner.call_deferred()


## Coloca la barra segun bar_position, bar_width_ratio, bar_margin y bar_extra_offset.
func _apply_bar_layout() -> void:
	var w := bar_width_ratio
	var is_top := bar_position in [BarPosition.TOP_CENTER, BarPosition.TOP_LEFT, BarPosition.TOP_RIGHT]
	match bar_position:
		BarPosition.TOP_LEFT, BarPosition.BOTTOM_LEFT:
			_bar_root.anchor_left = 0.0
			_bar_root.anchor_right = w
			_bar_root.offset_left = bar_margin.x
			_bar_root.offset_right = bar_margin.x
		BarPosition.TOP_RIGHT, BarPosition.BOTTOM_RIGHT:
			_bar_root.anchor_left = 1.0 - w
			_bar_root.anchor_right = 1.0
			_bar_root.offset_left = -bar_margin.x
			_bar_root.offset_right = -bar_margin.x
		_:
			_bar_root.anchor_left = 0.5 - w / 2.0
			_bar_root.anchor_right = 0.5 + w / 2.0
			_bar_root.offset_left = 0.0
			_bar_root.offset_right = 0.0
	if is_top:
		var top := bar_margin.y + bar_name_font_size + 10.0   # deja espacio para el nombre
		_bar_root.anchor_top = 0.0
		_bar_root.anchor_bottom = 0.0
		_bar_root.offset_top = top
		_bar_root.offset_bottom = top + bar_height
	else:
		_bar_root.anchor_top = 1.0
		_bar_root.anchor_bottom = 1.0
		_bar_root.offset_bottom = -bar_margin.y
		_bar_root.offset_top = -bar_margin.y - bar_height
	_bar_root.offset_left += bar_extra_offset.x
	_bar_root.offset_right += bar_extra_offset.x
	_bar_root.offset_top += bar_extra_offset.y
	_bar_root.offset_bottom += bar_extra_offset.y


## Crea una capa de la barra (color o textura). Las "clipped" se recortan segun la vida.
func _make_bar_layer(tex: Texture2D, color: Color, clipped: bool) -> Control:
	var content: Control
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		content = tr
	else:
		var cr := ColorRect.new()
		cr.color = color
		content = cr
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not clipped:
		_bar_root.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		return content
	var box := Control.new()
	box.clip_contents = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.anchor_left = 0.0
	box.anchor_top = 0.0
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	_bar_root.add_child(box)
	box.add_child(content)
	_bar_inner.append(content)
	return box


## El contenido de relleno/estela siempre mide lo de la barra completa; el contenedor solo lo recorta.
func _sync_bar_inner() -> void:
	for c in _bar_inner:
		c.position = Vector2.ZERO
		c.size = _bar_root.size


func _update_health_bar(animate := true) -> void:
	if _bar_fill == null:
		return
	var ratio := float(health) / float(max_health)
	_bar_fill.anchor_right = ratio
	_bar_label.text = "%d / %d" % [health, max_health]
	if _bar_tween and _bar_tween.is_valid():
		_bar_tween.kill()
	if animate:
		_bar_tween = create_tween()
		_bar_tween.tween_interval(0.35)
		_bar_tween.tween_property(_bar_trail, "anchor_right", ratio, 0.5)
	else:
		_bar_trail.anchor_right = ratio


func _show_health_bar() -> void:
	if _bar_root == null:
		return
	_bar_root.modulate.a = 0.0
	_bar_root.visible = true
	create_tween().tween_property(_bar_root, "modulate:a", 1.0, 0.5)


func _hide_health_bar() -> void:
	if _bar_root == null:
		return
	create_tween().tween_property(_bar_root, "modulate:a", 0.0, 1.0)


# ---------------------------------------------------------------- ALERTA "?" FUERA DE PANTALLA

func _alert_build() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 21
	add_child(layer)
	_alert_root = Control.new()
	_alert_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alert_root.size = alert_size
	_alert_root.pivot_offset = alert_size / 2.0
	_alert_root.visible = false
	layer.add_child(_alert_root)
	if alert_texture:
		var tr := TextureRect.new()
		tr.texture = alert_texture
		tr.modulate = alert_tint
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_alert_root.add_child(tr)
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		var l := Label.new()
		l.text = alert_text
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_size_override("font_size", alert_font_size)
		l.add_theme_color_override("font_color", alert_color)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 12)
		_alert_root.add_child(l)
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Si el origen del disparo esta fuera de la camara, pone la alerta pegada al borde, en la direccion de donde viene.
func _alert_update() -> void:
	if not offscreen_alert_enabled or dead:
		_alert_hide()
		return
	if _alert_root == null:
		_alert_build()
	var vp := get_viewport()
	var rect := vp.get_visible_rect()
	var screen_pos: Vector2 = vp.get_canvas_transform() * get_shoot_origin()
	if rect.has_point(screen_pos):
		_alert_root.visible = false
		return
	var c := rect.size / 2.0
	var d := screen_pos - c
	var half := c - Vector2(alert_edge_margin, alert_edge_margin) - alert_size / 2.0
	var s := minf(half.x / maxf(absf(d.x), 0.001), half.y / maxf(absf(d.y), 0.001))
	_alert_root.position = c + d * s - alert_size / 2.0
	if alert_pulse:
		_alert_root.scale = Vector2.ONE * (1.0 + 0.15 * sin(Time.get_ticks_msec() / 1000.0 * 12.0))
	_alert_root.visible = true


func _alert_hide() -> void:
	if _alert_root:
		_alert_root.visible = false


# ---------------------------------------------------------------- CEREBRO

## Envoltura del bucle: marca cuando esta corriendo para que el reinicio sepa cuando termino.
func _attack_loop() -> void:
	_loop_running = true
	await _attack_loop_body()
	_loop_running = false


func _attack_loop_body() -> void:
	await _wait(0.5)
	while not dead:
		if phase == 1 and health <= max_health * phase2_threshold:
			await _enter_phase2()
			if dead:
				return

		# Defensa anti-spam: si lo estan golpeando sin parar, suelta una onda y se reubica.
		if spam_defense_enabled and _recent_hits.size() >= spam_hits_needed:
			await _attack_shockwave()
			if dead:
				return
			await _attack_reposition()
			if dead:
				return
			_after_special()
			await _chase(rest_time_phase2 if phase == 2 else rest_time)
			continue
		# De vez en cuando se mueve a otra plataforma en lugar de atacar.
		if reposition_enabled and _attacks_since_move >= reposition_min_attacks and randf() < reposition_chance:
			await _attack_reposition()
			if dead:
				return
			_after_special()
			await _chase(rest_time_phase2 if phase == 2 else rest_time)
			continue

		var attack := _choose_attack()
		# Un dash cuenta como tantos usos como cruces haga (ida y vuelta = 2), para que el limite de repeticiones sea real.
		var weight := dash_passes if (attack == Attack.DASH and dash_passes_count_as_repeats) else 1
		if attack == _last_attack:
			_repeat_count += weight
		else:
			_repeat_count = weight
		_last_attack = attack
		match attack:
			Attack.SHOOT:
				_alert_active = true
				await _attack_shoot()
				_alert_active = false
				_alert_hide()
			Attack.JUMP:
				await _attack_jump()
			Attack.DASH:
				await _attack_dash()
		_attacks_since_move += 1
		if dead:
			return
		# Nunca se queda quieto: persigue al jugador hasta el siguiente ataque.
		await _chase(rest_time_phase2 if phase == 2 else rest_time)


func _enter_phase2() -> void:
	# Cinematica previa (si esta configurada).
	var cine := _cinematic_available()
	if cine:
		await _phase2_cinematic()
		if dead:
			_cinematic_end()
			return

	phase = 2
	_last_attack = -1
	_repeat_count = 0
	phase_changed.emit(phase)
	
	if animation_controller:
		animation_controller.is_phase_2 = true
		# El grito (weep) sigue con el jugador congelado.
		await animation_controller.play_and_wait(animation_controller.VisualState.WEEP)
	
	# El jugador recupera el control justo antes de que el jefe empiece a atacar.
	_cinematic_end()
	await _telegraph(1.0, Color(1, 0.2, 0.2))


func _choose_attack() -> int:
	if phase == 1:
		# FASE 1: solo Disparo y Salto.
		# Despues de disparar (arma cargando) OBLIGATORIAMENTE usa el salto antes de volver a disparar.
		if _last_attack == Attack.SHOOT:
			return Attack.JUMP
		return [Attack.SHOOT, Attack.JUMP].pick_random()
	# FASE 2: Disparo doble, Doble salto y Dash lateral.
	# Puede repetir el mismo ataque como maximo `max_repeats_phase2` veces seguidas; luego tiene que cambiar.
	var options: Array[int] = [Attack.SHOOT, Attack.JUMP, Attack.DASH]
	if _repeat_count >= max_repeats_phase2:
		options.erase(_last_attack)
	return options.pick_random()


# ---------------------------------------------------------------- ATAQUE: DISPARO

func _attack_shoot() -> void:
	if _get_player() == null:
		await _wait(0.5)
		return
		
	# Fase de carga (telegraph)
	if animation_controller:
		animation_controller.force_state(animation_controller.VisualState.SHOOT_CHARGE)
		
	await _telegraph(shoot_charge_phase2 if phase == 2 else shoot_charge, Color(1, 0.9, 0.3))
	if dead:
		return

	if phase == 1:
		# Fase 1: UN solo proyectil
		if animation_controller:
			var p := _get_player()
			if p:
				$AnimatedSprite2D.flip_h = p.global_position.x < global_position.x
				
			# Espera a que termine la animación de disparo antes de continuar
			await animation_controller.play_and_wait(animation_controller.VisualState.SHOOT_FIRE)
			if dead:
				return
				
		_fire_projectile()
		# Ya no hace falta el await _wait(0.3) porque play_and_wait ya esperó
		
	else:
		# Fase 2: DISPARO DOBLE
		for i in range(2):
			if animation_controller:
				var p := _get_player()
				if p:
					$AnimatedSprite2D.flip_h = p.global_position.x < global_position.x
				
				# Espera a que termine cada animación de disparo
				await animation_controller.play_and_wait(animation_controller.VisualState.SHOOT_FIRE)
				if dead:
					return
				
			_fire_projectile()
			
			# Retraso entre el primer y segundo disparo
			if i == 0:
				await _wait(double_shot_delay)
				
			if dead:
				return


## Punto de donde sale el proyectil (y a donde regresa al hacer parry).
func get_shoot_origin() -> Vector2:
	if shoot_from_center:
		return visual.get_global_transform() * (visual.size / 2.0)   # centro del cuerpo del jefe
	return global_position + muzzle_offset


func _fire_projectile() -> void:
	var p := _get_player()
	if p == null:
		return
	var origin := get_shoot_origin()
	var dir := ((p.global_position + aim_offset) - origin).normalized()

	var proj := BossProjectile.new()
	proj.direction = dir
	proj.speed = projectile_speed_phase2 if phase == 2 else projectile_speed
	proj.damage = projectile_damage
	proj.source = self
	proj.reflect_damage = parry_damage
	proj.reflect_speed_mult = parry_speed_multiplier
	get_parent().add_child(proj)
	proj.global_position = origin


# ---------------------------------------------------------------- ATAQUE: SALTO / DOBLE SALTO

func _attack_jump() -> void:
	if _get_player() == null:
		await _wait(0.5)
		return

	var jumps := 2 if phase == 2 else 1   # fase 2 = doble salto
	var t := jump_time_phase2 if phase == 2 else jump_time

	for i in jumps:
		if _get_player() == null:
			return
		var windup := second_jump_windup if i > 0 else (jump_windup_phase2 if phase == 2 else jump_windup)
		velocity.x = 0.0
		
		if animation_controller:
			animation_controller.force_state(animation_controller.VisualState.JUMP_WINDUP)
			
		_telegraph_tween(windup, Color(1, 0.6, 0.2))

		# La marca roja SIGUE al jugador durante el aviso y se fija en el momento de saltar.
		var target := _landing_point()
		var elapsed := 0.0
		while elapsed < windup and not dead:
			target = _landing_point()
			_show_marker(target)
			await _next_frame()
			elapsed += get_physics_process_delta_time()
		if dead:
			return

		if debug_keys:
			var pl := _get_player()
			if pl and absf(target.x - pl.global_position.x) > 40.0:
				print("Boss: el salto NO apunta al jugador. jugador x=%d, objetivo x=%d, jefe x=%d, arena=%d..%d" % [
					pl.global_position.x, target.x, global_position.x, _arena_left, _arena_right])

		await _do_jump(target, t)
		if dead:
			return
		await _wait(0.15)


## Punto del suelo/plataforma justo debajo del jugador (a donde saltara el jefe).
func _landing_point() -> Vector2:
	var p := _get_player()
	if p == null:
		return global_position
	var from := p.global_position + Vector2(0, -10)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 1500), collision_mask)
	query.exclude = [get_rid()]
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	var pt := Vector2(from.x, global_position.y)
	if result:
		pt = result.position
	if not jump_can_leave_arena:
		var cx := clampf(pt.x, _arena_left, _arena_right)
		if debug_keys and not is_equal_approx(cx, pt.x) and not _warned_clamp:
			_warned_clamp = true
			print("Boss: el jugador esta FUERA de la arena (x=%d, arena=%d..%d): el salto se limita al borde." % [pt.x, _arena_left, _arena_right])
		pt.x = cx
	return pt


## Salto parabolico controlado por codigo: llega EXACTAMENTE a `target` en t segundos,
## sube o baja la altura que haga falta y ATRAVIESA plataformas y paredes durante el vuelo.
func _do_jump(target: Vector2, t: float) -> void:
	var start := global_position
	var vx := (target.x - start.x) / t
	var vy := ((target.y - start.y) - 0.5 * gravity * t * t) / t

	_scripted = true
	
	if animation_controller:
		animation_controller.force_state(animation_controller.VisualState.JUMP_AIR)
		
	velocity = Vector2.ZERO
	var elapsed := 0.0
	_jump_takeoff_vfx()
	_ghost_timer = 0.0
	while elapsed < t and not dead:
		await _next_frame()
		elapsed += get_physics_process_delta_time()
		_jump_vfx_tick(get_physics_process_delta_time())
		var tau := minf(elapsed, t)
		global_position = start + Vector2(vx * tau, vy * tau + 0.5 * gravity * tau * tau)
	if dead:
		return

	global_position = target + Vector2(0, -1)
	if jump_can_leave_arena:
		# Si aterrizo fuera de la arena, la amplia para que no lo regresen de golpe al borde.
		_arena_left = minf(_arena_left, global_position.x)
		_arena_right = maxf(_arena_right, global_position.x)
	_scripted = false
	velocity = Vector2.ZERO
	
	if animation_controller:
		animation_controller.force_state(animation_controller.VisualState.JUMP_LAND)
		
	_hide_marker()
	_jump_impact_vfx()

	# Impacto: dana si el jugador sigue dentro de la zona.
	await _damage_window(impact_duration)


# ---------------------------------------------------------------- ATAQUE: DASH LATERAL

func _attack_dash() -> void:
	for i in dash_passes:
		var p := _get_player()
		if p == null:
			return
		var dir := signf(p.global_position.x - global_position.x)
		if dir == 0.0:
			dir = 1.0
			
		# --- NUEVO: Hacer que el jefe mire hacia donde va a hacer el dash ---
		$AnimatedSprite2D.flip_h = dir < 0.0
		# ------------------------------------------------------------------

		var target_x := _arena_right if dir > 0.0 else _arena_left
		target_x = _dash_limit_x(dir, target_x)   # se acorta si hay un vacio en el camino

		velocity.x = 0.0
		if dash_show_warning:
			if animation_controller:
				animation_controller.force_state(animation_controller.VisualState.DASH_WINDUP)
				
			_show_dash_path(target_x)
			await _dash_warning(dash_windup if i == 0 else 0.4)
			_hide_dash_path()
		else:
			await _wait(dash_windup if i == 0 else 0.15)
		if dead:
			return

		_hit_this_attack = false
		_dash_vfx_start(dir)
		
		if animation_controller:
			animation_controller.force_state(animation_controller.VisualState.DASH_MOVE)
			
		_scripted = true                      # se mueve por codigo: no choca con plataformas ni paredes
		velocity = Vector2.ZERO
		var elapsed := 0.0
		while not dead and (global_position.x - target_x) * dir < 0.0 and elapsed < 3.0:
			var delta := get_physics_process_delta_time()
			# Nunca pasa de target_x (que ya esta recortado antes del vacio).
			var step := minf(dash_speed * delta, absf(target_x - global_position.x))
			global_position.x += dir * step
			_try_damage_player()
			_dash_vfx_tick(delta)
			await _next_frame()
			elapsed += delta
		_scripted = false
		velocity = Vector2.ZERO
		_dash_vfx_stop(dir)
		if dead:
			return
		await _wait(0.4)

## Hasta donde puede llegar el dash: se detiene `dash_edge_margin` antes de un vacio.
func _dash_limit_x(dir: float, target_x: float) -> float:
	if not dash_stop_at_edges:
		return target_x
	var y := global_position.y
	var x := global_position.x
	var last := x
	while (x - target_x) * dir < 0.0:
		x += dir * 16.0
		if not _ground_at(x + dir * dash_edge_margin, y):
			return last
		last = x
	return target_x


## true si hay piso en esa x a la altura de los pies del jefe (ignora plataformas mas altas/bajas).
func _ground_at(x: float, surface_y: float) -> bool:
	var from := Vector2(x, surface_y - 20.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 70.0), collision_mask)
	var ex: Array[RID] = [get_rid()]
	var p := _get_player()
	if p is CollisionObject2D:
		ex.append(p.get_rid())
	query.exclude = ex
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and absf(hit.position.y - surface_y) < 30.0


# ---------------------------------------------------------------- MOVERSE ENTRE PLATAFORMAS

## Despues de moverse / soltar la onda se reinicia el conteo de golpes y de ataques.
func _after_special() -> void:
	_attacks_since_move = 0
	_recent_hits.clear()
	_last_attack = Attack.JUMP        # un movimiento cuenta como salto
	_repeat_count = 1


## Salto tactico: va a otra plataforma (o al piso). Marca en rojo donde va a caer.
func _attack_reposition() -> void:
	var spot := _find_reposition_spot()
	if spot == Vector2.INF:
		await _wait(0.3)
		return
	velocity.x = 0.0
	_telegraph_tween(reposition_windup, Color(0.5, 0.85, 1.0))
	_show_marker(spot)
	await _wait(reposition_windup)
	if dead:
		return
	await _do_jump(spot, jump_time_phase2 if phase == 2 else jump_time)


## Busca superficies planas dentro de la arena a las que pueda saltar y elige una al azar.
func _find_reposition_spot() -> Vector2:
	var space := get_world_2d().direct_space_state
	var ex: Array[RID] = [get_rid()]
	var p := _get_player()
	if p is CollisionObject2D:
		ex.append(p.get_rid())
	var body_h := visual.size.y
	var y_min := global_position.y - reposition_max_up
	var y_max := global_position.y + reposition_max_down
	var spots: Array[Vector2] = []
	var x := _arena_left + 40.0
	while x <= _arena_right - 40.0:
		if absf(x - global_position.x) >= reposition_min_distance:
			var y := y_min - 20.0
			var guard := 0
			while y < y_max and guard < 8:
				guard += 1
				var q := PhysicsRayQueryParameters2D.create(Vector2(x, y), Vector2(x, y_max + 60.0), collision_mask)
				q.exclude = ex
				var hit := space.intersect_ray(q)
				if hit.is_empty():
					break
				var top: Vector2 = hit.position
				if hit.normal.y < -0.7 and top.y >= y_min and top.y <= y_max and _spot_is_free(top, body_h, space, ex):
					if p == null or absf(top.x - p.global_position.x) > 120.0 or absf(top.y - p.global_position.y) > 150.0:
						spots.append(top)
				y = top.y + 45.0       # sigue buscando superficies mas abajo (atraviesa el grosor de la plataforma)
		x += reposition_scan_step
	if spots.is_empty():
		return Vector2.INF
	return spots.pick_random()


## Que haya espacio para el cuerpo del jefe y que no este en la orilla de la plataforma.
func _spot_is_free(top: Vector2, body_h: float, space: PhysicsDirectSpaceState2D, ex: Array[RID]) -> bool:
	var q := PhysicsRayQueryParameters2D.create(top + Vector2(0, -2), top + Vector2(0, -body_h), collision_mask)
	q.exclude = ex
	if not space.intersect_ray(q).is_empty():
		return false          # hay techo encima
	return _ground_at(top.x - 40.0, top.y) and _ground_at(top.x + 40.0, top.y)


# ---------------------------------------------------------------- ANTI-SPAM: ONDA DE CHOQUE

## Cuenta los golpes recibidos mientras el jefe no se mueve de lugar.
func _register_hit() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if _recent_hits.is_empty() or global_position.distance_to(_spam_anchor) > spam_position_tolerance:
		_recent_hits.clear()
		_spam_anchor = global_position
	_recent_hits.append(now)
	while not _recent_hits.is_empty() and now - _recent_hits[0] > spam_window:
		_recent_hits.pop_front()


func _attack_shockwave() -> void:
	if _get_player() == null:
		return
	velocity.x = 0.0
	
	if animation_controller:
		animation_controller.force_state(animation_controller.VisualState.SHOCKWAVE_WINDUP)
		
	_telegraph_tween(shockwave_windup, Color(0.5, 0.85, 1.0))
	await _dash_warning(shockwave_windup)     # tiembla y parpadea
	if dead:
		return
	await _shockwave_blast()


## Dos ondas bajas que corren por el piso hacia los lados; se esquivan saltando. Empujan al jugador.
func _shockwave_blast() -> void:
	if animation_controller:
		animation_controller.play_and_wait(animation_controller.VisualState.SHOCKWAVE_BLAST)
		
	var origin := global_position
	if jump_vfx:
		for side in [-1.0, 1.0]:
			_spawn_burst(side, 40, dust_color, 150.0, 420.0, 12.0, 26.0, Vector2(0, -40), 55.0)
	if jump_camera_shake > 0.0:
		_shake_camera(jump_camera_shake)

	var waves: Array[ColorRect] = []
	var alive := [true, true]
	for i in 2:
		var r := ColorRect.new()
		r.top_level = true
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.color = shockwave_color
		r.size = Vector2(30.0, shockwave_height)
		add_child(r)
		waves.append(r)

	var traveled := 0.0
	var hit_player := false
	while traveled < shockwave_range and not dead:
		var delta := get_physics_process_delta_time()
		traveled += shockwave_speed * delta
		for i in 2:
			if not alive[i]:
				continue
			var side := -1.0 if i == 0 else 1.0
			var wx := origin.x + side * (20.0 + traveled)
			if dash_stop_at_edges and not _ground_at(wx, origin.y):
				alive[i] = false          # se acaba el piso: la onda desaparece
				waves[i].hide()
				continue
			waves[i].global_position = Vector2(wx - 15.0, origin.y - shockwave_height)
		var p := _get_player()
		if p and not hit_player:
			var pr := _player_rect(p)
			for i in 2:
				if alive[i] and Rect2(waves[i].global_position, waves[i].size).intersects(pr):
					hit_player = true
					apply_damage(p, shockwave_damage)
					var push_dir := signf(p.global_position.x - origin.x)
					if push_dir == 0.0:
						push_dir = 1.0
					_push_player(push_dir, shockwave_push_distance)
					break
		await _next_frame()
	for r in waves:
		r.queue_free()


## Empuja al jugador en horizontal (respeta paredes si es CharacterBody2D).
func _push_player(dir: float, distance: float, duration := 0.25) -> void:
	var p := _get_player()
	if p == null:
		return
	if p.has_method("apply_knockback"):
		p.apply_knockback(Vector2(dir, -0.3) * distance * 2.0)
		return
	_push_prev = 0.0
	var tw := create_tween()
	tw.tween_method(_push_step.bind(p, dir, distance), 0.0, 1.0, duration).set_ease(Tween.EASE_OUT)


func _push_step(progress: float, p: Node2D, dir: float, distance: float) -> void:
	if not is_instance_valid(p):
		return
	var dx := (progress - _push_prev) * distance * dir
	_push_prev = progress
	if p is CharacterBody2D:
		p.move_and_collide(Vector2(dx, 0.0))
	else:
		p.global_position.x += dx


# ---------------------------------------------------------------- DAÑO AL JUGADOR (por codigo, sin depender de capas)

func _damage_window(duration: float) -> void:
	_hit_this_attack = false
	var elapsed := 0.0
	while elapsed < duration and not dead:
		_try_damage_player()
		await _next_frame()
		elapsed += get_physics_process_delta_time()


func _try_damage_player() -> void:
	if _hit_this_attack:
		return
	var p := _get_player()
	if p == null:
		return
	if _damage_rect().intersects(_player_rect(p)):
		_hit_this_attack = true
		apply_damage(p, contact_damage)


func _damage_rect() -> Rect2:
	var shape := damage_shape.shape as RectangleShape2D
	var size := shape.size * damage_shape.global_scale.abs()
	return Rect2(damage_shape.global_position - size / 2.0, size)


func _player_rect(p: Node2D) -> Rect2:
	var cs := p.get_node_or_null("PlayerHitbox") as CollisionShape2D
	if cs and cs.shape:
		var size := Vector2(40, 80)
		if cs.shape is RectangleShape2D:
			size = cs.shape.size
		elif cs.shape is CapsuleShape2D:
			size = Vector2(cs.shape.radius * 2.0, cs.shape.height)
		elif cs.shape is CircleShape2D:
			size = Vector2.ONE * cs.shape.radius * 2.0
		size *= cs.global_scale.abs()
		return Rect2(cs.global_position - size / 2.0, size)
	return Rect2(p.global_position - Vector2(20, 40), Vector2(40, 80))


## Intenta danar a `body` llamando al primer metodo que tenga de DAMAGE_METHODS.
static func apply_damage(body: Node, amount: int) -> void:
	for method in DAMAGE_METHODS:
		if body.has_method(method):
			if body.get_method_argument_count(method) == 0:
				body.call(method)
			else:
				body.call(method, amount)
			return
	push_warning("Boss: el jugador no tiene ninguno de estos metodos: %s" % [DAMAGE_METHODS])


# ---------------------------------------------------------------- UTILIDADES

func _get_player() -> Node2D:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		_exceptions_done = false
		if _player == null:
			push_warning("Boss: no hay ningun nodo en el grupo 'player'.")
	# El jefe y el jugador no chocan fisicamente (el jefe ya no empuja al jugador).
	if _player and not _exceptions_done:
		add_collision_exception_with(_player)
		if _player is PhysicsBody2D:
			_player.add_collision_exception_with(self)
		_sync_slash_layers()
		# Escucha la muerte del jugador para reiniciar el combate
		_hook_death_signals(_player, ["died", "player_died", "death", "dead", "player_dead", "player_death"])
		_exceptions_done = true
	return _player


## Asegura que la espada del jugador (SlashHitbox) pueda detectar el cuerpo del jefe:
## si la capa del jefe no coincide con la mascara de SlashHitbox, agrega las capas necesarias.
func _sync_slash_layers() -> void:
	var hb := _player.get_node_or_null("SlashHitbox") as Area2D
	if hb == null:
		return
	if collision_layer & hb.collision_mask != 0:
		return
	var extra := hb.collision_mask & ~1
	if extra == 0:
		extra = hb.collision_mask
	collision_layer |= extra
	print("Boss: capas de colision ajustadas automaticamente para que la espada lo detecte (layer = %d)" % collision_layer)


## Camina hacia el jugador durante `duration` segundos (para que el jefe siempre este presionando).
func _chase(duration: float) -> void:
	if animation_controller: 
		animation_controller.set_state(animation_controller.VisualState.CHASE)
		
	var spd := chase_speed_phase2 if phase == 2 else chase_speed
	var elapsed := 0.0
	while elapsed < duration and not dead:
		var p := _get_player()
		if p and is_on_floor():
			var dx := p.global_position.x - global_position.x
			if absf(dx) > chase_stop_distance:
				velocity.x = signf(dx) * spd
			else:
				velocity.x = 0.0
		await _next_frame()
		elapsed += get_physics_process_delta_time()
	velocity.x = 0.0
	
	if animation_controller and not dead: 
		animation_controller.set_state(animation_controller.VisualState.IDLE)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout

## Espera al siguiente frame de fisica, pero se queda congelado mientras el juego esta pausado.
func _next_frame() -> void:
	await get_tree().physics_frame
	while get_tree().paused:
		await get_tree().physics_frame


## Parpadeo de aviso sin esperar (devuelve el tween).
func _telegraph_tween(time: float, color: Color) -> Tween:
	var tw := create_tween()
	tw.tween_property(visual, "modulate", color, time * 0.5)
	tw.tween_property(visual, "modulate", Color.WHITE, time * 0.5)
	return tw


## Parpadeo de aviso esperando a que termine.
func _telegraph(time: float, color: Color) -> void:
	var tw := _telegraph_tween(time, color)
	await tw.finished


# ---------------------------------------------------------------- EFECTOS DEL SALTO (polvo, estela, grietas)

## Polvo y escombros al despegar.
func _jump_takeoff_vfx() -> void:
	if not jump_vfx:
		return
	for d in [-1.0, 1.0]:
		_spawn_burst(d, 22, dust_color, 100.0, 300.0, 10.0, 22.0, Vector2(0, -40), 50.0)
	_spawn_burst(0.0, 10, debris_color, 250.0, 500.0, 4.0, 9.0, Vector2(0, 1800), 45.0)


## Estela de copias del jefe mientras esta en el aire.
func _jump_vfx_tick(delta: float) -> void:
	if not jump_vfx or not jump_afterimages:
		return
	_ghost_timer -= delta
	if _ghost_timer > 0.0:
		return
	_ghost_timer = 0.04
	var ghost := ColorRect.new()
	ghost.size = visual.size
	ghost.color = Color(1.0, 0.35, 0.25, 0.45)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var parent := get_parent()
	parent.add_child(ghost)
	parent.move_child(ghost, get_index())
	ghost.global_position = visual.global_position
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tw.finished.connect(ghost.queue_free)


## Explosion de polvo + escombros + grietas + temblor de camara al aterrizar.
func _jump_impact_vfx() -> void:
	if not jump_vfx:
		return
	# Nube de polvo hacia los dos lados y escombros hacia arriba.
	for d in [-1.0, 1.0]:
		_spawn_burst(d, 45, dust_color, 150.0, 420.0, 12.0, 28.0, Vector2(0, -40), 45.0)
		_spawn_burst(d, 12, debris_color, 300.0, 650.0, 5.0, 11.0, Vector2(0, 1800), 40.0)
	_spawn_burst(0.0, 22, debris_color, 350.0, 800.0, 5.0, 12.0, Vector2(0, 1800), 55.0)
	if jump_cracks:
		_spawn_cracks(global_position)
	if jump_camera_shake > 0.0:
		_shake_camera(jump_camera_shake)


## Grietas temporales: salen del punto de impacto, crecen rapido y se desvanecen solas.
func _spawn_cracks(origin: Vector2) -> void:
	var holder := Node2D.new()
	holder.z_index = crack_z_index
	var parent := get_parent()
	parent.add_child(holder)
	parent.move_child(holder, get_index())     # detras del jefe
	holder.global_position = origin

	# 1) Grietas que se abren HACIA ABAJO sobre el arte del piso (abanico desde el punto de impacto).
	for i in crack_count:
		var t := (float(i) + 0.5) / float(crack_count)
		var a := deg_to_rad(lerpf(-65.0, 65.0, t) + randf_range(-8.0, 8.0))   # 0 = recto hacia abajo
		var dir := Vector2(sin(a), cos(a))
		var length := crack_length * randf_range(0.6, 1.0)
		var pts := _clip_to_ground(_jagged_points(dir, length), origin)
		if pts.size() < 2:
			continue
		_add_crack_line(holder, pts, 10.0, crack_glow_color)
		_add_crack_line(holder, pts, 4.5, crack_color)
		# Ramita que sale de la mitad de la grieta (tambien hacia abajo).
		if randf() < 0.7 and pts.size() > 4:
			var mid := pts[pts.size() / 2]
			var bdir := dir.rotated(deg_to_rad(randf_range(-50.0, 50.0)))
			if bdir.y < 0.2:
				bdir.y = 0.2
			bdir = bdir.normalized()
			var branch := _clip_to_ground(_jagged_points(bdir, length * 0.4, mid), origin)
			if branch.size() >= 2:
				_add_crack_line(holder, branch, 6.0, crack_glow_color)
				_add_crack_line(holder, branch, 2.5, crack_color)

	# 2) Dos rajaduras pegadas a la superficie del piso, una a cada lado (la "linea" por donde se parte).
	for side in [-1.0, 1.0]:
		var sdir := Vector2(side * cos(deg_to_rad(8.0)), sin(deg_to_rad(8.0)))
		var spts := _clip_to_ground(_jagged_points(sdir, crack_length * 1.1, Vector2(0, 3)), origin)
		if spts.size() < 2:
			continue
		_add_crack_line(holder, spts, 8.0, crack_glow_color)
		_add_crack_line(holder, spts, 3.5, crack_color)

	# Crecen desde el centro, se quedan un rato y se desvanecen.
	holder.modulate.a = 1.0
	var tw := holder.create_tween()
	tw.tween_interval(crack_lifetime)
	tw.tween_property(holder, "modulate:a", 0.0, crack_fade_time)
	tw.finished.connect(holder.queue_free)


## Corta la grieta en el primer punto que ya no esta sobre el piso (y la deja hasta ahi).
func _clip_to_ground(pts: PackedVector2Array, origin: Vector2) -> PackedVector2Array:
	if not crack_only_on_ground:
		return pts
	var out := PackedVector2Array()
	for p in pts:
		if not _point_on_ground(origin + p, origin.y):
			break
		out.append(p)
	return out


## true si debajo de ese punto hay piso a la altura de la superficie donde cayo el jefe
## y no esta mas abajo que `crack_max_depth`.
func _point_on_ground(world_pt: Vector2, surface_y: float) -> bool:
	if world_pt.y - surface_y > crack_max_depth:
		return false
	var from := Vector2(world_pt.x, surface_y - 20.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 60.0), collision_mask)
	query.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and absf(hit.position.y - surface_y) < 30.0


func _jagged_points(dir: Vector2, length: float, start := Vector2.ZERO) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 7
	var normal := Vector2(-dir.y, dir.x)
	pts.append(start)
	for k in range(1, steps + 1):
		var f := float(k) / steps
		pts.append(start + dir * length * f + normal * randf_range(-9.0, 9.0) * (1.0 - f * 0.4))
	return pts


func _add_crack_line(holder: Node2D, pts: PackedVector2Array, width: float, color: Color) -> void:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var curve := Curve.new()                  # gruesa en el centro, fina en la punta
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.1))
	line.width_curve = curve
	holder.add_child(line)
	# Animacion de crecimiento: revela los puntos poco a poco.
	var tw := line.create_tween()
	tw.tween_method(_grow_line.bind(line, pts), 0.0, 1.0, 0.15).set_ease(Tween.EASE_OUT)


func _grow_line(progress: float, line: Line2D, pts: PackedVector2Array) -> void:
	if not is_instance_valid(line):
		return
	var n := maxi(2, int(ceil(pts.size() * progress)))
	line.points = pts.slice(0, n)


func _shake_camera(strength: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var tw := create_tween()
	for i in 6:
		var k := 1.0 - float(i) / 6.0
		tw.tween_property(cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * k, 0.03)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.04)


# ---------------------------------------------------------------- EFECTOS DEL DASH (polvo, escombros, estela)

func _make_particles(amount: int, life: float, color: Color, vmin: float, vmax: float,
		smin: float, smax: float, grav: Vector2, spread_deg: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = false
	p.amount = amount
	p.lifetime = life
	p.local_coords = false          # las particulas se quedan en el mundo, no siguen al jefe
	p.direction = Vector2.UP
	p.spread = spread_deg
	p.gravity = grav
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.scale_amount_min = smin
	p.scale_amount_max = smax
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(30, 3)
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.2))
	p.scale_amount_curve = curve
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([color, Color(color.r, color.g, color.b, 0.0)])
	p.color_ramp = g
	return p


func _spawn_burst(dir: float, amount: int, color: Color, vmin: float, vmax: float,
		smin: float, smax: float, grav: Vector2, spread_deg: float) -> void:
	var p := _make_particles(amount, 0.8, color, vmin, vmax, smin, smax, grav, spread_deg)
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector2(dir, -0.6)
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	p.finished.connect(p.queue_free)


func _dash_vfx_start(dir: float) -> void:
	if not dash_vfx:
		return
	if _dash_dust == null:
		_dash_dust = _make_particles(70, 0.9, dust_color, 30.0, 160.0, 8.0, 20.0, Vector2(0, -60), 40.0)
		add_child(_dash_dust)
		_dash_debris = _make_particles(35, 0.7, debris_color, 250.0, 580.0, 4.0, 10.0, Vector2(0, 1800), 35.0)
		add_child(_dash_debris)
	# El humo sale hacia atras y los escombros salen disparados hacia arriba.
	_dash_dust.direction = Vector2(-dir, -0.4)
	_dash_debris.direction = Vector2(-dir * 0.5, -1.0)
	_dash_dust.emitting = true
	_dash_debris.emitting = true
	# Explosion de arranque (hacia atras)
	_spawn_burst(-dir, 40, dust_color, 120.0, 380.0, 10.0, 24.0, Vector2(0, -40), 55.0)
	_spawn_burst(-dir, 16, debris_color, 300.0, 650.0, 5.0, 11.0, Vector2(0, 1800), 45.0)
	_ghost_timer = 0.0


func _dash_vfx_tick(delta: float) -> void:
	if not dash_vfx or not dash_afterimages:
		return
	_ghost_timer -= delta
	if _ghost_timer > 0.0:
		return
	_ghost_timer = 0.04
	# Copia del jefe que se desvanece (estela).
	var ghost := ColorRect.new()
	ghost.size = visual.size
	ghost.color = Color(1.0, 0.35, 0.25, 0.5)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var parent := get_parent()
	parent.add_child(ghost)
	parent.move_child(ghost, get_index())      # detras del jefe
	ghost.global_position = visual.global_position
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tw.finished.connect(ghost.queue_free)


func _dash_vfx_stop(dir: float, burst := true) -> void:
	if _dash_dust:
		_dash_dust.emitting = false
	if _dash_debris:
		_dash_debris.emitting = false
	if burst and dash_vfx:
		# Derrape al frenar: nube grande de polvo hacia adelante.
		_spawn_burst(dir, 50, dust_color, 150.0, 450.0, 12.0, 28.0, Vector2(0, -40), 60.0)
		_spawn_burst(dir, 14, debris_color, 250.0, 550.0, 5.0, 11.0, Vector2(0, 1800), 50.0)


## Aviso del dash: el jefe tiembla y parpadea (blanco brillante / oscuro) durante `time` segundos.
func _dash_warning(time: float) -> void:
	var elapsed := 0.0
	var bright := false
	while elapsed < time and not dead:
		bright = not bright
		visual.self_modulate = Color(2.5, 2.5, 2.5) if bright else Color(0.4, 0.4, 0.4)
		visual.position = _visual_base_pos + Vector2(
			randf_range(-dash_shake_pixels, dash_shake_pixels),
			randf_range(-dash_shake_pixels * 0.4, dash_shake_pixels * 0.4))
		await _wait(0.06)
		elapsed += 0.06
	visual.position = _visual_base_pos
	visual.self_modulate = Color.WHITE


## Franja roja en el piso que muestra por donde va a pasar el dash.
func _show_dash_path(target_x: float) -> void:
	if _dash_marker == null:
		_dash_marker = ColorRect.new()
		_dash_marker.top_level = true
		_dash_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dash_marker.color = Color(1, 0, 0, 0.22)
		add_child(_dash_marker)
	var rect := damage_shape.shape as RectangleShape2D
	var left := minf(global_position.x, target_x)
	var width := absf(target_x - global_position.x)
	_dash_marker.size = Vector2(width, rect.size.y)
	_dash_marker.global_position = Vector2(left, global_position.y + damage_shape.position.y - rect.size.y / 2.0)
	_dash_marker.show()


func _hide_dash_path() -> void:
	if _dash_marker:
		_dash_marker.hide()


func _show_marker(target: Vector2) -> void:
	if _marker == null:
		_marker = ColorRect.new()
		_marker.top_level = true
		_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_marker.color = Color(1, 0, 0, 0.3)
		add_child(_marker)
	var rect := damage_shape.shape as RectangleShape2D
	_marker.size = rect.size
	_marker.global_position = target + damage_shape.position - rect.size / 2.0
	_marker.show()


func _hide_marker() -> void:
	if _marker:
		_marker.hide()

func _boss_cam_on() -> void:
	var p := _get_player()
	if p and p.has_method("activate_boss_cam"):
		p.activate_boss_cam()

func _boss_cam_off() -> void:
	var p := _get_player()
	if p and p.has_method("deactivate_boss_cam"):
		p.deactivate_boss_cam()


# ---------------------------------------------------------------- CINEMATICA DE LA FASE 2

func _cinematic_available() -> bool:
	if not cinematic_enabled:
		return false
	if cinematic_only_first_time and _cinematic_seen:
		return false
	if cinematic_player_spot == null or cinematic_boss_spot == null:
		push_warning("Boss: asigna cinematic_player_spot y cinematic_boss_spot para ver la cinematica de la fase 2.")
		return false
	return _get_player() != null


func _phase2_cinematic() -> void:
	var p = _get_player()
	var pac = p.get("animation_controller")
	var psprite = p.get("sprite")
	
	# --- NUEVO: Crear una cámara temporal con Tween (transición suave) ---
	_cine_temp_cam = Camera2D.new()
	get_parent().add_child(_cine_temp_cam)
	
	# Posicionamos la cámara temporal donde estaba la del jugador originalmente
	var current_cam := get_viewport().get_camera_2d()
	var start_pos: Vector2 = current_cam.global_position if current_cam else p.global_position
	_cine_temp_cam.global_position = start_pos
	
	# APLICAMOS EL OFFSET AQUÍ PARA QUE SE MANTENGA EN TODA LA CINEMÁTICA
	_cine_temp_cam.offset = cinematic_camera_offset
	_cine_temp_cam.position_smoothing_enabled = false # Desactivado para que el Tween controle todo
	_cine_temp_cam.make_current() 
	
	# CALCULAMOS LA POSICIÓN DEL PIVOTE:
	# Tomamos la posición del jefe y le sumamos el desplazamiento del pivote (que ajustas en el inspector)
	var pivot_offset := Vector2.ZERO
	if is_instance_valid(cinematic_pivot):
		pivot_offset = cinematic_pivot.global_position - global_position
	
	var target_pivot_pos := global_position + pivot_offset
	
	# Hacemos que la cámara viaje desde su posición original hasta el PIVOTE del jefe
	var cam_tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if cinematic_tween:
		cam_tween.set_trans(cinematic_tween.transition).set_ease(cinematic_tween.ease).set_parallel(false)
		cam_tween.tween_property(_cine_temp_cam, "global_position", target_pivot_pos, cinematic_tween.duration)
	else:
		cam_tween.tween_property(_cine_temp_cam, "global_position", target_pivot_pos, 1.0)
	# -------------------------------------------------------------

	_cinematic_active = true
	_cinematic_seen = true
	velocity = Vector2.ZERO
	_hide_marker()
	_cine_freeze_player(p)

	# 1) Aviso: el jefe se prepara para saltar.
	_face_player_visual()
	if animation_controller:
		animation_controller.force_state(animation_controller.VisualState.JUMP_WINDUP)
	_telegraph_tween(cinematic_windup, Color(1, 0.6, 0.2))
	await _wait(cinematic_windup)
	if dead:
		return

	# 2) Saltan a la vez: jugador a la izquierda, jefe a la derecha.
	var boss_target: Vector2 = cinematic_boss_spot.global_position
	var feet_offset: float = _player_rect(p).end.y - p.global_position.y
	var player_target: Vector2 = cinematic_player_spot.global_position + Vector2(0, -feet_offset - 1.0)
	var t := cinematic_jump_time
	var start: Vector2 = p.global_position
	var vx := (player_target.x - start.x) / t
	var vy := ((player_target.y - start.y) - 0.5 * gravity * t * t) / t
	if psprite:
		psprite.flip_h = player_target.x < start.x
	if pac:
		pac.force_state(pac.VisualState.JUMP)
	_cine_falling = false
	var tw := create_tween()
	tw.tween_method(_cine_player_arc.bind(p, start, vx, vy), 0.0, t, t)
	
	# Movemos la cámara temporal al pivote del jefe mientras salta
	var cam_jump_tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if cinematic_tween:
		cam_jump_tween.set_trans(cinematic_tween.transition).set_ease(cinematic_tween.ease).set_parallel(false)
		cam_jump_tween.tween_property(_cine_temp_cam, "global_position", boss_target + pivot_offset, cinematic_tween.duration)
	else:
		cam_jump_tween.tween_property(_cine_temp_cam, "global_position", boss_target + pivot_offset, t)
	
	await _do_jump(boss_target, t)
	if tw.is_valid() and tw.is_running():
		await tw.finished
	if cam_jump_tween.is_valid() and cam_jump_tween.is_running():
		await cam_jump_tween.finished
	if dead:
		return
	p.global_position = player_target

	# 3) Se miran de frente.
	if psprite:
		psprite.flip_h = boss_target.x < player_target.x
	_face_player_visual()
	if pac:
		pac.force_state(pac.VisualState.IDLE)
	await _wait(cinematic_pause_after_land)
	if dead:
		return

	# 4) El jugador apunta y lanza el tp.
	if pac:
		pac.start_aim_sequence()
	await _wait(cinematic_aim_time)
	if dead:
		return
	if pac:
		pac.end_aim_sequence()
	await _wait(cinematic_release_delay)
	if dead:
		return
	var dir := signf(boss_target.x - player_target.x)
	if dir == 0.0:
		dir = 1.0
	_cine_spawn_tp(p.global_position + Vector2(cinematic_tp_offset.x * dir, cinematic_tp_offset.y))
	var flight := create_tween()
	flight.tween_property(_cine_tp, "global_position", get_shoot_origin(), cinematic_tp_flight_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await flight.finished
	if dead:
		return

	# 5) El jefe lo atrapa y lo rompe.
	await _cine_boss_anim("CATCH_TP")
	if dead:
		return
	get_tree().create_timer(cinematic_break_pop_delay, false).timeout.connect(_cine_break_tp)
	await _cine_boss_anim("BREAK_TP")
	if dead:
		return
	await _wait(cinematic_pause_before_scream)
	# Despues de esto, _enter_phase2 reproduce el grito (weep) y activa la fase 2.


func _cine_boss_anim(state_name: String, fallback := 0.6) -> void:
	if animation_controller:
		await animation_controller.play_and_wait(animation_controller.VisualState[state_name], fallback)
	else:
		await _wait(fallback)


## Movimiento parabolico del jugador (lo llama el tween).
func _cine_player_arc(tau: float, p, start: Vector2, vx: float, vy: float) -> void:
	if not is_instance_valid(p):
		return
	p.global_position = start + Vector2(vx * tau, vy * tau + 0.5 * gravity * tau * tau)
	# Al pasar el punto mas alto cambia a la animacion de caida.
	if not _cine_falling and vy + gravity * tau > 0.0:
		_cine_falling = true
		var ac = p.get("animation_controller")
		if ac:
			ac.force_state(ac.VisualState.FALL)


func _cine_spawn_tp(pos: Vector2) -> void:
	if cinematic_tp_texture:
		var s := Sprite2D.new()
		s.texture = cinematic_tp_texture
		_cine_tp = s
	else:
		var poly := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 20:
			var a := TAU * i / 20.0
			pts.append(Vector2(cos(a), sin(a)) * cinematic_tp_size * 0.5)
		poly.polygon = pts
		poly.color = cinematic_tp_color
		_cine_tp = poly
	_cine_tp.z_index = 20
	get_parent().add_child(_cine_tp)
	_cine_tp.global_position = pos


## El jefe rompe el tp: explosion de particulas + temblor de camara.
func _cine_break_tp() -> void:
	if not is_instance_valid(_cine_tp):
		return
	var pos := _cine_tp.global_position
	_cine_tp.queue_free()
	_cine_tp = null
	var ps := _make_particles(45, 0.8, cinematic_tp_color, 250.0, 700.0, 5.0, 12.0, Vector2(0, 1200), 180.0)
	ps.one_shot = true
	ps.explosiveness = 1.0
	get_parent().add_child(ps)
	ps.global_position = pos
	ps.emitting = true
	ps.finished.connect(ps.queue_free)
	if jump_camera_shake > 0.0:
		_shake_camera(jump_camera_shake * 1.5)


func _face_player_visual() -> void:
	var p := _get_player()
	var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if p and spr:
		spr.flip_h = p.global_position.x < global_position.x


## Termina la cinematica (idempotente): devuelve el control al jugador.
func _cinematic_end() -> void:
	if not _cinematic_active:
		return
		
	# --- NUEVO: Regresar suavemente al jugador antes de destruir la cámara ---
	if is_instance_valid(_cine_temp_cam):
		var p = _get_player()
		var player_dead: bool = "is_dead" in p and p.is_dead
		
		if is_instance_valid(p) and not player_dead:
			# Hacemos que la cámara temporal empiece a seguir al jugador suavemente
			_cine_temp_cam.position_smoothing_enabled = true
			_cine_temp_cam.position_smoothing_speed = 3.0
			_cine_temp_cam.offset = Vector2.ZERO # Le quitamos el offset para que encuadre al jugador normal
			
			# Movemos el target de la cámara hacia el jugador
			_cine_temp_cam.global_position = p.global_position
			
			# Esperamos un momento para que el suavizado haga su magia y se deslice hasta el jugador
			await get_tree().create_timer(0.5, false).timeout
		
		# Ahora que ya está sobre el jugador, destruimos la cámara temporal.
		# La cámara original del jugador tomará el control exactamente en la misma posición,
		# por lo que no habrá ningún salto brusco.
		_cine_temp_cam.queue_free()
		_cine_temp_cam = null
	# -------------------------------------------------------------------------

	_cinematic_active = false
	if is_instance_valid(_cine_tp):
		_cine_tp.queue_free()
	_cine_tp = null
	_cine_unfreeze_player(_player)


## Congela al jugador SIN tocar su script: apaga su fisica y su input, y lo hace invulnerable.
func _cine_freeze_player(p) -> void:
	if p.has_method("_cancel_tp_charge"):
		p._cancel_tp_charge()
	if "is_recharging" in p:
		p.is_recharging = false
	if "ChargeCam" in p and p.ChargeCam:
		p.ChargeCam.priority = 0
	if "invulnerable_timer" in p:
		p.invulnerable_timer = 9999.0
	if "sprite" in p and p.sprite:
		p.sprite.visible = true
	if "dust_particles" in p and p.dust_particles:
		p.dust_particles.emitting = false
	var ac = p.get("animation_controller")
	if ac:
		ac.cancel_sequence()
		ac.unlock()
	p.velocity = Vector2.ZERO
	p.set_physics_process(false)
	p.set_process_unhandled_input(false)
	p.set_process_input(false)


func _cine_unfreeze_player(p) -> void:
	if not is_instance_valid(p):
		return
	var player_dead: bool = "is_dead" in p and p.is_dead
	if not player_dead:
		if "invulnerable_timer" in p:
			p.invulnerable_timer = 0.5
		var ac = p.get("animation_controller")
		if ac:
			ac.cancel_sequence()
			ac.unlock()
	if "_last_fall_speed" in p:
		p._last_fall_speed = 0.0
	p.velocity = Vector2.ZERO
	p.set_physics_process(true)
	p.set_process_unhandled_input(true)
	p.set_process_input(true)
