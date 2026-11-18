extends Control
## Cinemática inicial: imágenes + texto con efecto máquina de escribir.
## Todo se edita desde el Inspector del nodo.

@export_group("Secuencia")
## Agrega aquí tus escenas (Escena 1, 2, 3...). Cada una lleva imagen y texto.
@export var scenes: Array[CinematicScene] = []
## Escena que se abre al terminar la cinemática (tu gameplay).
@export_file("*.tscn") var next_scene: String = "res://tutorial.tscn"

@export_group("Imagen")
@export var background_color: Color = Color.BLACK
@export var image_stretch: TextureRect.StretchMode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
## Duración del fundido a negro entre escenas.
@export var fade_time: float = 0.6

@export_group("Texto")
@export var text_font: Font
@export var text_font_size: int = 28
@export var text_color: Color = Color.WHITE
## Letras por segundo.
@export var typing_speed: float = 40.0
@export var box_color: Color = Color(0, 0, 0, 0.75)
@export var box_height: float = 220.0
@export var box_margin: float = 40.0

@export_group("Botones")
@export var button_font: Font
@export var button_font_size: int = 24
@export var text_next: String = "Continuar"
## Texto del botón en la última escena.
@export var text_last: String = "Comenzar"
@export var allow_skip: bool = true
@export var text_skip: String = "Saltar"

@export_group("Sonido")
@export var music: AudioStream
@export_range(-40.0, 6.0) var music_volume_db: float = -6.0
@export var music_bus: String = "Master"
## Sonido que suena al escribir cada letra (opcional, mejor uno muy corto).
@export var type_sound: AudioStream
## Suena cada X letras.
@export var type_sound_every: int = 2

var _tex: TextureRect
var _label: Label
var _next_btn: Button
var _skip_btn: Button
var _fade: ColorRect
var _music: AudioStreamPlayer
var _type_player: AudioStreamPlayer
var _index: int = -1
var _typing: bool = false
var _busy: bool = false
var _type_tween: Tween
var _last_char: int = 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_ui()
	_build_audio()
	if scenes.is_empty():
		_finish()
		return
	await _show_scene(0)


# ============================================================ CONSTRUCCIÓN

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = background_color
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_tex = TextureRect.new()
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.stretch_mode = image_stretch
	_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tex)

	# Caja de texto abajo
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = box_margin
	panel.offset_right = -box_margin
	panel.offset_bottom = -box_margin
	panel.offset_top = -(box_height + box_margin)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = box_color
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", text_font_size)
	_label.add_theme_color_override("font_color", text_color)
	if text_font != null:
		_label.add_theme_font_override("font", text_font)
	vbox.add_child(_label)

	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(200, 48)
	_next_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	_next_btn.visible = false
	_next_btn.pressed.connect(_on_next_pressed)
	_style_button(_next_btn)
	vbox.add_child(_next_btn)

	# Botón saltar (arriba a la derecha)
	_skip_btn = Button.new()
	_skip_btn.text = text_skip
	_skip_btn.visible = allow_skip
	_skip_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_skip_btn.offset_left = -170
	_skip_btn.offset_right = -20
	_skip_btn.offset_top = 20
	_skip_btn.offset_bottom = 64
	_skip_btn.focus_mode = Control.FOCUS_NONE
	_skip_btn.pressed.connect(_finish)
	_style_button(_skip_btn)
	add_child(_skip_btn)

	# Capa negra para los fundidos (siempre encima)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _style_button(b: Button) -> void:
	b.add_theme_font_size_override("font_size", button_font_size)
	if button_font != null:
		b.add_theme_font_override("font", button_font)


func _build_audio() -> void:
	_type_player = AudioStreamPlayer.new()
	_type_player.stream = type_sound
	_type_player.bus = music_bus
	add_child(_type_player)

	if music == null:
		return
	_music = AudioStreamPlayer.new()
	_music.bus = music_bus
	var stream := music.duplicate() as AudioStream
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music.stream = stream
	_music.volume_db = music_volume_db
	add_child(_music)
	_music.play()


# ============================================================ SECUENCIA

func _fade_to(alpha: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, fade_time)
	await t.finished


func _show_scene(i: int) -> void:
	_busy = true
	_index = i
	var s: CinematicScene = scenes[i]
	if _fade.color.a < 1.0:
		await _fade_to(1.0)
	_tex.texture = s.image if s != null else null
	_label.text = s.text if s != null else ""
	_label.visible_characters = 0
	_next_btn.visible = false
	await _fade_to(0.0)
	_busy = false
	_start_typing(s)


func _start_typing(s: CinematicScene) -> void:
	var total: int = _label.text.length()
	var speed: float = typing_speed
	if s != null and s.text_speed > 0.0:
		speed = s.text_speed
	_typing = true
	_last_char = 0
	if total == 0:
		_on_typing_done()
		return
	_type_tween = create_tween()
	_type_tween.tween_method(_set_chars, 0, total, float(total) / maxf(speed, 1.0))
	_type_tween.finished.connect(_on_typing_done)


func _set_chars(v) -> void:
	var n: int = int(v)
	_label.visible_characters = n
	if n != _last_char:
		_last_char = n
		if type_sound != null and n % maxi(type_sound_every, 1) == 0:
			_type_player.play()


func _on_typing_done() -> void:
	_typing = false
	_label.visible_characters = -1
	_next_btn.text = text_last if _index >= scenes.size() - 1 else text_next
	_next_btn.visible = true
	_next_btn.grab_focus()


func _on_next_pressed() -> void:
	if _busy or _typing:
		return
	if _index + 1 < scenes.size():
		await _show_scene(_index + 1)
	else:
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	# Clic o Enter mientras se escribe = mostrar todo el texto de golpe
	var pressed: bool = event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if pressed and _typing and not _busy:
		if _type_tween and _type_tween.is_valid():
			_type_tween.kill()
		_on_typing_done()
		get_viewport().set_input_as_handled()
	elif allow_skip and event.is_action_pressed("ui_cancel"):
		_finish()
		get_viewport().set_input_as_handled()


func _finish() -> void:
	if _busy and _index == -2:
		return
	_busy = true
	var old_index := _index
	_index = -2
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	if _music != null:
		create_tween().tween_property(_music, "volume_db", -60.0, fade_time)
	await _fade_to(1.0)
	if next_scene != "" and ResourceLoader.exists(next_scene):
		get_tree().change_scene_to_file(next_scene)
	else:
		push_warning("Cinemática: next_scene no es válida (índice %d)." % old_index)
