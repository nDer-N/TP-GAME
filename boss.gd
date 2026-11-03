class_name Boss
extends CharacterBody2D
## Primer jefe: 2 fases.
## Fase 1: Disparo a distancia + Salto (tras disparar OBLIGATORIAMENTE salta antes de volver a disparar).
## Fase 2 (<= 40% de vida): Disparo doble + Doble salto + Dash lateral.

signal phase_changed(new_phase: int)
signal health_changed(current: int, maximum: int)
signal died

enum Attack { SHOOT, JUMP, DASH }

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
@export var bar_height := 22.0

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

var health := 0
var phase := 1
var active := false
var dead := false

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
var _bar_fill: ColorRect
var _bar_trail: ColorRect
var _bar_label: Label
var _bar_tween: Tween

@onready var visual: ColorRect = $Visual
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D


func _ready() -> void:
	health = max_health
	_visual_base_pos = visual.position
	_arena_left = global_position.x - arena_half_width
	_arena_right = global_position.x + arena_half_width
	add_to_group("boss")
	add_to_group("enemies")
	# El daño al jugador se calcula por codigo; el Area2D solo se usa para definir el tamaño.
	damage_area.monitoring = false
	damage_area.monitorable = false
	if show_health_bar:
		_build_health_bar()


func _physics_process(delta: float) -> void:
	if dead or _scripted:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()
	global_position.x = clampf(global_position.x, _arena_left, _arena_right)

	if not active:
		var p := _get_player()
		if p and p.global_position.x >= _arena_left and p.global_position.x <= _arena_right \
				and absf(p.global_position.y - global_position.y) <= activation_height:
			active = true
			_show_health_bar()
			_music_start()
			_attack_loop()


func _unhandled_input(event: InputEvent) -> void:
	if debug_keys and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			take_damage(40)


# ---------------------------------------------------------------- VIDA

func take_damage(amount = 1, _a = null, _b = null) -> void:
	if dead:
		return
	var dmg := 1
	if amount is int or amount is float:
		dmg = maxi(int(amount), 1)
	health = maxi(health - dmg, 0)
	health_changed.emit(health, max_health)
	_update_health_bar()
	_flash_hit()
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
	velocity = Vector2.ZERO
	_hide_marker()
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
	_music_player.stream = stream
	_music_player.bus = music_bus
	_music_player.volume_db = -60.0
	get_parent().add_child(_music_player)      # fuera del jefe para que pueda terminar su fade out cuando muera
	_music_player.play()
	_music_tween = _music_player.create_tween()
	_music_tween.tween_property(_music_player, "volume_db", music_volume_db, music_fade_in)
	_duck_set(true)


## Termina la musica (con fade out) cuando el jefe muere.
func _music_stop() -> void:
	_duck_set(false)
	if _music_player == null or not is_instance_valid(_music_player):
		return
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	var player := _music_player
	_music_player = null
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
	if _music_player and is_instance_valid(_music_player):
		_music_player.queue_free()


# ---------------------------------------------------------------- BARRA DE VIDA

func _build_health_bar() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	# Contenedor arriba al centro (la mitad del ancho de la pantalla).
	_bar_root = Control.new()
	_bar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_root.anchor_left = 0.25
	_bar_root.anchor_right = 0.75
	_bar_root.anchor_top = 0.0
	_bar_root.anchor_bottom = 0.0
	_bar_root.offset_left = 0.0
	_bar_root.offset_right = 0.0
	_bar_root.offset_top = 56.0
	_bar_root.offset_bottom = 56.0 + bar_height
	_bar_root.visible = false
	layer.add_child(_bar_root)

	var back := ColorRect.new()
	back.color = Color(0.05, 0.05, 0.05, 0.9)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_root.add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Barra "fantasma": se queda un momento para que veas cuanta vida acabas de quitar.
	_bar_trail = _make_bar_rect(Color(1.0, 0.85, 0.3))
	_bar_fill = _make_bar_rect(Color(0.85, 0.1, 0.1))

	# Marca del 40% (donde empieza la fase 2).
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

	var title := Label.new()
	title.text = boss_name
	title.position = Vector2(0, -30)
	title.add_theme_font_size_override("font_size", 20)
	_bar_root.add_child(title)

	_bar_label = Label.new()
	_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_root.add_child(_bar_label)
	_bar_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_update_health_bar(false)


func _make_bar_rect(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.anchor_left = 0.0
	r.anchor_right = 1.0
	r.anchor_top = 0.0
	r.anchor_bottom = 1.0
	r.offset_left = 0.0
	r.offset_right = 0.0
	r.offset_top = 0.0
	r.offset_bottom = 0.0
	_bar_root.add_child(r)
	return r


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


# ---------------------------------------------------------------- CEREBRO

func _attack_loop() -> void:
	await _wait(0.5)
	while not dead:
		if phase == 1 and health <= max_health * phase2_threshold:
			await _enter_phase2()
			if dead:
				return

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
				await _attack_shoot()
			Attack.JUMP:
				await _attack_jump()
			Attack.DASH:
				await _attack_dash()
		if dead:
			return
		# Nunca se queda quieto: persigue al jugador hasta el siguiente ataque.
		await _chase(rest_time_phase2 if phase == 2 else rest_time)


func _enter_phase2() -> void:
	phase = 2
	_last_attack = -1
	_repeat_count = 0
	phase_changed.emit(phase)
	visual.color = visual.color.darkened(0.35)
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
	await _telegraph(shoot_charge_phase2 if phase == 2 else shoot_charge, Color(1, 0.9, 0.3))
	if dead:
		return

	if phase == 1:
		# Fase 1: UN solo proyectil hacia donde esta el jugador (de frente o en diagonal).
		# Despues el arma se esta cargando, asi que el siguiente ataque sera el salto.
		_fire_projectile()
		await _wait(0.3)
	else:
		# Fase 2: DISPARO DOBLE, dos proyectiles con 1 segundo de retraso.
		_fire_projectile()
		await _wait(double_shot_delay)
		if dead:
			return
		_fire_projectile()
		await _wait(0.3)


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
		_telegraph_tween(windup, Color(1, 0.6, 0.2))

		# La marca roja SIGUE al jugador durante el aviso y se fija en el momento de saltar.
		var target := _landing_point()
		var elapsed := 0.0
		while elapsed < windup and not dead:
			target = _landing_point()
			_show_marker(target)
			await get_tree().physics_frame
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
	velocity = Vector2.ZERO
	var elapsed := 0.0
	_jump_takeoff_vfx()
	_ghost_timer = 0.0
	while elapsed < t and not dead:
		await get_tree().physics_frame
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
		var target_x := _arena_right if dir > 0.0 else _arena_left
		target_x = _dash_limit_x(dir, target_x)   # se acorta si hay un vacio en el camino

		velocity.x = 0.0
		if dash_show_warning:
			_show_dash_path(target_x)
			await _dash_warning(dash_windup if i == 0 else 0.4)
			_hide_dash_path()
		else:
			await _wait(dash_windup if i == 0 else 0.15)
		if dead:
			return

		_hit_this_attack = false
		_dash_vfx_start(dir)
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
			await get_tree().physics_frame
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


# ---------------------------------------------------------------- DAÑO AL JUGADOR (por codigo, sin depender de capas)

func _damage_window(duration: float) -> void:
	_hit_this_attack = false
	var elapsed := 0.0
	while elapsed < duration and not dead:
		_try_damage_player()
		await get_tree().physics_frame
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
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	velocity.x = 0.0


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


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
