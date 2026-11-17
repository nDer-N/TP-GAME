class_name BossProjectile
extends Area2D
## Proyectil del jefe. No necesita escena: el jefe lo crea con BossProjectile.new()
## PARRY: si lo golpeas con la espada, regresa hacia el jefe y le hace daño.

## Todo lo que este en este GRUPO (piso, paredes y techo EXTERIORES del tren) destruye el proyectil.
## Las plataformas NO deben estar en este grupo: esas las sigue atravesando.
const KILL_GROUP := &"train_bounds"

var direction := Vector2.RIGHT
var speed := 600.0
var damage := 1
var lifetime := 5.0
var radius := 14.0

var source: Boss = null            # el jefe que lo disparo (a quien regresa al hacer parry)
var reflect_damage := 40           # daño al jefe cuando regresa
var reflect_speed_mult := 1.6      # se acelera al ser devuelto
var reflected := false

# -- Apariencia (los llena el jefe desde el inspector) ---
## Animacion: si hay SpriteFrames se usa un AnimatedSprite2D (tiene prioridad sobre texture).
var frames: SpriteFrames = null
var animation_name := &"default"
## Animacion que se reproduce al hacer parry (vacio = sigue con la misma).
var reflected_animation_name := &""
var animation_speed := 1.0
## Imagen fija (solo se usa si no hay frames).
var texture: Texture2D = null
var visual_scale := 1.0
var tint := Color.WHITE
var reflected_tint := Color(0.2, 0.9, 1.0)
var rotate_to_direction := true
var scale_hitbox := false

## Escena del dibujo (lo mas facil): una escena con tu AnimatedSprite2D ya configurado en el editor.
## Tiene prioridad sobre frames y texture.
var visual_scene: PackedScene = null

var _visual: CanvasItem          # escena, AnimatedSprite2D, Sprite2D o ColorRect (placeholder)
var _is_sprite := false          # true si no es el cuadrito de color
var _anim: AnimatedSprite2D = null   # el AnimatedSprite2D que se reproduce (si hay)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0xFFFFF   # detecta todas las capas; abajo filtramos que hacer con cada cosa
	add_to_group("enemies")    # tu SlashController busca este grupo + take_damage()

	var hit_radius := radius * (visual_scale if scale_hitbox else 1.0)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = hit_radius
	shape.shape = circle
	add_child(shape)

	_build_visual()

	var timer := Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(queue_free)
	add_child(timer)

	_sync_slash_layer()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


## La zona transparente del tren (Area2D en el grupo KILL_GROUP) destruye el proyectil.
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(KILL_GROUP):
		queue_free()


func _find_animated(n: Node) -> AnimatedSprite2D:
	if n is AnimatedSprite2D:
		return n
	for c in n.get_children():
		var r := _find_animated(c)
		if r:
			return r
	return null


func _build_visual() -> void:
	if visual_scene:
		var inst := visual_scene.instantiate()
		add_child(inst)
		if inst is Node2D:
			(inst as Node2D).scale *= visual_scale
		if inst is CanvasItem:
			(inst as CanvasItem).modulate = tint
			_visual = inst
			_is_sprite = true
		_anim = _find_animated(inst)
		if _anim:
			_anim.speed_scale = animation_speed
			if _anim.sprite_frames and _anim.sprite_frames.has_animation(animation_name):
				_anim.play(animation_name)
			else:
				_anim.play()   # reproduce la animacion que tengas por defecto en la escena
	elif frames:
		var a := AnimatedSprite2D.new()
		a.sprite_frames = frames
		a.scale = Vector2.ONE * visual_scale
		a.modulate = tint
		a.speed_scale = animation_speed
		add_child(a)
		# Si la animacion pedida no existe, usa la primera que haya.
		var anim := animation_name
		if not frames.has_animation(anim):
			var names := frames.get_animation_names()
			if names.is_empty():
				push_warning("BossProjectile: el SpriteFrames no tiene animaciones.")
			else:
				anim = names[0]
		if frames.has_animation(anim):
			a.play(anim)   # respeta el Loop que configures en el panel SpriteFrames
		_visual = a
		_anim = a
		_is_sprite = true
	elif texture:
		var s := Sprite2D.new()
		s.texture = texture
		s.scale = Vector2.ONE * visual_scale
		s.modulate = tint
		add_child(s)
		_visual = s
		_is_sprite = true
	else:
		# Placeholder: cuadrito de color (se agranda con visual_scale tambien).
		var r := ColorRect.new()
		var size := Vector2.ONE * radius * 2.0 * visual_scale
		r.size = size
		r.position = -size / 2.0
		r.color = Color(1.0, 0.7, 0.1) * tint
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)
		_visual = r
		_is_sprite = false
	_update_rotation()


func _update_rotation() -> void:
	if _is_sprite and rotate_to_direction and _visual is Node2D:
		(_visual as Node2D).rotation = direction.angle()


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
	var prev := global_position
	global_position += direction * speed * delta
	# El proyectil es rapido: revisamos todo el tramo recorrido para que no atraviese un piso delgado.
	if _crossed_kill_wall(prev, global_position):
		queue_free()


## true si entre `from` y `to` hay algo del grupo KILL_GROUP (ignora todo lo demas, como las plataformas).
func _crossed_kill_wall(from: Vector2, to: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var ex: Array[RID] = [get_rid()]
	for i in 12:
		var q := PhysicsRayQueryParameters2D.create(from, to, collision_mask)
		q.collide_with_areas = true    # la zona transparente del tren es un Area2D
		q.exclude = ex
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return false
		var c = hit.collider
		if c is Node and (c as Node).is_in_group(KILL_GROUP):
			return true
		ex.append(hit.rid)   # no es del tren: sigue buscando mas adelante en el tramo
	return false


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
	_update_rotation()  # el dibujo gira hacia el jefe
	# Cambia de color para que se vea que ahora es tuyo.
	if _visual is ColorRect:
		(_visual as ColorRect).color = reflected_tint
	elif _visual:
		_visual.modulate = reflected_tint
		# Si el proyectil es animado y hay una animacion de parry, la reproduce.
		if _anim and reflected_animation_name != &"":
			if _anim.sprite_frames and _anim.sprite_frames.has_animation(reflected_animation_name):
				_anim.play(reflected_animation_name)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(KILL_GROUP):
		queue_free()
		return
	if reflected:
		# Devuelto: solo le hace daño al jefe (no al jugador).
		if body is Boss:
			body.take_damage(reflect_damage, "parry")   # "parry" = no cuenta para el anti-spam
			queue_free()
		return

	if body.is_in_group("player"):
		Boss.apply_damage(body, damage)
		queue_free()
	# Ya NO se destruye contra el piso ni las paredes: las atraviesa (se borra por tiempo de vida).
