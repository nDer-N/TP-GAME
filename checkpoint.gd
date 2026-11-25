extends Area2D

@export var sprite: Sprite2D
## Textura del checkpoint apagado (oscuro).
@export var texture_off: Texture2D
## Textura del checkpoint encendido (claro).
@export var texture_on: Texture2D
@export var activation_vfx_scene: PackedScene

@export_group("Fuego")
## Escena del fuego (la raíz debe ser un AnimatedSprite2D).
@export var fire_scene: PackedScene
@export var fire_animation: StringName = &"full"
## Punto donde va la base de la llama, en píxeles de la textura (origen = esquina superior izquierda).
@export var fire_anchor_px: Vector2 = Vector2(555, 668)
## Alto visible del fuego, en píxeles de la textura.
@export var fire_height_px: float = 70.0

var _activated: bool = false
var _fire: AnimatedSprite2D
var _fire_scale: float = 1.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_visual(false, false)
	# Si esta partida ya había pasado por este checkpoint, se ve activado.
	if SaveManager.in_game and SaveManager.session_activated.has(_key()):
		_activated = true
		_apply_visual(true, false)


func _key() -> String:
	return str(get_path())


func _on_body_entered(body: Node2D) -> void:
	if _activated:
		return
	if not body.has_method("set_checkpoint"):
		return
	_activated = true
	body.set_checkpoint(global_position)
	SaveManager.register_checkpoint(_key(), global_position)

	_apply_visual(true, true)

	#if sprite:
		# Pop de escala relativo a la escala original del sprite
		#var base := sprite.scale
		#var tw := create_tween()
		#tw.tween_property(sprite, "scale", base * 1.3, 0.1)
		#tw.tween_property(sprite, "scale", base, 0.15)

	if activation_vfx_scene:
		var vfx := activation_vfx_scene.instantiate()
		get_tree().current_scene.add_child(vfx)
		vfx.global_position = global_position


# Cambia la textura y muestra u oculta el fuego.
func _apply_visual(on: bool, animated: bool) -> void:
	if sprite == null:
		return
	sprite.modulate = Color.WHITE
	sprite.texture = texture_on if on else texture_off
	if on:
		_show_fire(animated)
	else:
		_hide_fire()


func _show_fire(animated: bool) -> void:
	if fire_scene == null or _fire != null or sprite.texture == null:
		return

	var node := fire_scene.instantiate()
	if not (node is AnimatedSprite2D):
		push_warning("Checkpoint: la raíz de fire_scene debe ser un AnimatedSprite2D.")
		node.queue_free()
		return
	_fire = node
	if _fire.sprite_frames == null or not _fire.sprite_frames.has_animation(fire_animation):
		push_warning("Checkpoint: el fuego no tiene la animación '%s'." % fire_animation)
		_fire.queue_free()
		_fire = null
		return

	_fire.centered = true
	_fire.offset = Vector2.ZERO
	sprite.add_child(_fire)   # hijo del sprite: hereda su escala y el pop

	# Área visible del primer frame, para ignorar el margen transparente
	var tex := _fire.sprite_frames.get_frame_texture(fire_animation, 0)
	var tam := tex.get_size()
	var rect := Rect2(Vector2.ZERO, tam)
	var img := tex.get_image()
	if img != null:
		var r := img.get_used_rect()
		if r.size != Vector2i.ZERO:
			rect = Rect2(r)

	_fire_scale = fire_height_px / rect.size.y

	# Punto de anclaje en coordenadas locales del sprite
	var origin := sprite.texture.get_size() / 2.0 if sprite.centered else Vector2.ZERO
	var anchor_local := fire_anchor_px - origin + sprite.offset

	# Colocamos la base-centro VISIBLE del fuego sobre ese punto
	var bottom_center := Vector2(rect.get_center().x, rect.end.y) - tam / 2.0
	_fire.position = anchor_local - bottom_center * _fire_scale

	# Frame inicial aleatorio, como en la UI
	_fire.play(fire_animation)
	_fire.frame = randi() % _fire.sprite_frames.get_frame_count(fire_animation)
	_fire.frame_progress = randf()

	if animated:
		_fire.scale = Vector2.ZERO
		var tw := create_tween()
		tw.tween_property(_fire, "scale", Vector2.ONE * _fire_scale, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_fire.scale = Vector2.ONE * _fire_scale


func _hide_fire() -> void:
	if _fire != null:
		_fire.queue_free()
		_fire = null
