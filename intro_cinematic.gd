extends Control
## Cinemática inicial: imágenes + texto con efecto máquina de escribir.
## Todo se edita desde el Inspector del nodo.

enum TextStyle { OUTLINE_ONLY, OUTLINE_GRADIENT, SMALL_BOX }

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
## Estilo del texto: solo contorno, contorno + degradado, o caja pequeña.
@export var text_style: TextStyle = TextStyle.OUTLINE_GRADIENT
@export var text_font: Font
@export var text_font_size: int = 28
## Tamaño mínimo al que puede bajar la letra si el texto es muy largo.
@export var text_min_font_size: int = 16
@export var text_color: Color = Color.WHITE
## Letras por segundo (más bajo = más lento).
@export var typing_speed: float = 22.0
## Segundos de pausa cuando el texto llega a un salto de línea / párrafo.
@export var paragraph_pause: float = 1.5
## Altura (en px) del difuminado superior del texto.
@export var text_fade_height: float = 56.0
@export var box_height: float = 160.0
@export var box_margin: float = 40.0

@export_group("Texto - Contorno")
@export var outline_color: Color = Color.BLACK
@export_range(0, 30) var outline_size: int = 8
@export var shadow_color: Color = Color(0, 0, 0, 0.6)
@export var shadow_offset: Vector2 = Vector2(2, 2)

@export_group("Texto - Degradado y caja")
## Altura del degradado negro de abajo (solo en OUTLINE_GRADIENT).
@export var gradient_height: float = 320.0
@export_range(0.0, 1.0) var gradient_strength: float = 0.8
## Color de la caja (solo en SMALL_BOX).
@export var box_color: Color = Color(0, 0, 0, 0.45)

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
## Volumen del sonido de escribir (en dB). Más bajo = más silencioso.
@export_range(-60.0, 6.0) var type_sound_volume_db: float = -10.0
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
var _scroll: ScrollContainer
var _scroll_target: float = 0.0

# Controla cuándo el scroll automático está activo.
# Mientras se escribe SIEMPRE sigue al texto; al terminar baja al final
# y después suelta el control para que el jugador mueva la barra libremente.
var _auto_scroll: bool = true


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

	# Degradado negro suave abajo (solo en OUTLINE_GRADIENT)
	if text_style == TextStyle.OUTLINE_GRADIENT:
		var grad := Gradient.new()
		grad.set_color(0, Color(0, 0, 0, 0))
		grad.set_color(1, Color(0, 0, 0, gradient_strength))
		var gtex := GradientTexture2D.new()
		gtex.gradient = grad
		gtex.fill_from = Vector2(0, 0)
		gtex.fill_to = Vector2(0, 1)
		var shade := TextureRect.new()
		shade.texture = gtex
		shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shade.stretch_mode = TextureRect.STRETCH_SCALE
		shade.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		shade.offset_top = -gradient_height
		shade.offset_bottom = 0
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shade)

	# Contenedor del texto abajo
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = box_margin
	panel.offset_right = -box_margin
	panel.offset_bottom = -box_margin
	panel.offset_top = -(box_height + box_margin)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var sb := StyleBoxFlat.new()
	if text_style == TextStyle.SMALL_BOX:
		sb.bg_color = box_color
		sb.set_corner_radius_all(12)
	else:
		sb.bg_color = Color(0, 0, 0, 0)
	sb.set_content_margin_all(16)
	sb.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.custom_minimum_size = Vector2(0, 60)
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_scroll)

	# Detectar cuando el jugador mueve la barra o la rueda (solo cuenta al terminar de escribir).
	_scroll.get_v_scroll_bar().scrolling.connect(_on_user_scrolled)
	_scroll.gui_input.connect(_on_scroll_gui_input)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_label.add_theme_font_size_override("font_size", text_font_size)
	_label.add_theme_color_override("font_color", text_color)
	if text_font != null:
		_label.add_theme_font_override("font", text_font)
	if text_style != TextStyle.SMALL_BOX:
		_label.add_theme_color_override("font_outline_color", outline_color)
		_label.add_theme_constant_override("outline_size", outline_size)
		_label.add_theme_color_override("font_shadow_color", shadow_color)
		_label.add_theme_constant_override("shadow_offset_x", int(shadow_offset.x))
		_label.add_theme_constant_override("shadow_offset_y", int(shadow_offset.y))
	_scroll.add_child(_label)

	# Difuminado: el texto se desvanece al salir por arriba del rectángulo
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float top_y = 0.0;
uniform float fade_px = 0.0;
varying vec2 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	if (fade_px > 0.0) {
		COLOR.a *= smoothstep(top_y, top_y + fade_px, wpos.y);
	}
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_label.material = mat

	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(200, 48)
	_next_btn.visible = false
	_next_btn.pressed.connect(_on_next_pressed)
	_style_button(_next_btn)
	add_child(_next_btn)
	_next_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_next_btn.offset_left = -(200 + box_margin)
	_next_btn.offset_right = -box_margin
	_next_btn.offset_top = -(48 + 20)
	_next_btn.offset_bottom = -20

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
	# Fondo semitransparente para no tapar el arte
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0.5)
	normal.set_corner_radius_all(8)
	normal.set_border_width_all(2)
	normal.border_color = Color(1, 1, 1, 0.6)
	normal.set_content_margin_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.15, 0.15, 0.15, 0.8)
	hover.border_color = Color(1, 0.9, 0.5)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("pressed", normal)


func _build_audio() -> void:
	_type_player = AudioStreamPlayer.new()
	_type_player.stream = type_sound
	_type_player.volume_db = type_sound_volume_db
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
	_scroll.scroll_vertical = 0
	_scroll_target = 0.0

	# Activar el scroll automático al comenzar cada escena.
	_auto_scroll = true

	_next_btn.visible = false
	await _fade_to(0.0)
	_busy = false
	_start_typing(s)


func _start_typing(s: CinematicScene) -> void:
	var text: String = _label.text
	var total: int = text.length()
	var speed: float = typing_speed
	if s != null and s.text_speed > 0.0:
		speed = s.text_speed
	_typing = true
	_auto_scroll = true
	_last_char = 0
	if total == 0:
		_on_typing_done()
		return

	_type_tween = create_tween()
	var pos := 0
	while pos < total:
		# Busca el siguiente salto de línea y agrupa los que vengan seguidos
		var end := text.find("\n", pos)
		if end == -1:
			end = total
		else:
			while end < total and text[end] == "\n":
				end += 1
		_type_tween.tween_method(_set_chars, pos, end, float(end - pos) / maxf(speed, 1.0))
		if end < total:
			_type_tween.tween_interval(paragraph_pause)
		pos = end
	_type_tween.finished.connect(_on_typing_done)


func _set_chars(v) -> void:
	var n: int = int(v)
	_label.visible_characters = n
	# La línea que se escribe se mantiene en la parte baja del rectángulo
	var lines: int = _label.get_visible_line_count()
	var line_h: float = _label.get_minimum_size().y / maxf(_label.get_line_count(), 1)
	_scroll_target = maxf(0.0, lines * line_h - _scroll.size.y + 8.0)
	if n != _last_char:
		_last_char = n
		if type_sound != null and n % maxi(type_sound_every, 1) == 0:
			_type_player.play()


# ============================================================ SCROLL AUTOMÁTICO

# Máximo valor al que realmente puede llegar la barra.
func _max_scroll() -> float:
	var bar := _scroll.get_v_scroll_bar()
	return maxf(0.0, bar.max_value - bar.page)


func _process(delta: float) -> void:
	if _scroll == null:
		return

	# Scroll suave hacia la línea que se está escribiendo.
	# Mientras se escribe siempre sigue al texto (aunque haya pausas de párrafo).
	if _auto_scroll:
		var target := minf(_scroll_target, _max_scroll())
		var cur := float(_scroll.scroll_vertical)
		var diff := target - cur
		if absf(diff) <= 1.0:
			_scroll.scroll_vertical = int(target)
			# Solo suelta el control cuando ya terminó de escribir y llegó al final
			if not _typing:
				_auto_scroll = false
		else:
			var step := maxf(absf(diff) * minf(1.0, delta * 8.0), 1.0)
			step = minf(step, absf(diff))
			_scroll.scroll_vertical = int(cur + signf(diff) * step)

	# Difuminado superior: solo aparece cuando ya hay texto arriba que se sale
	var mat := _label.material as ShaderMaterial
	if mat:
		var fade := clampf(float(_scroll.scroll_vertical) / maxf(text_fade_height, 1.0), 0.0, 1.0) * text_fade_height
		mat.set_shader_parameter("top_y", _scroll.get_global_rect().position.y)
		mat.set_shader_parameter("fade_px", fade)


func _on_typing_done() -> void:
	_typing = false
	_type_player.stop()  # corta el sonido de escribir
	_label.visible_characters = -1

	# Lleva el scroll suavemente al final del texto completo.
	# Cuando llegue, _process suelta el control y el jugador puede mover la barra.
	_auto_scroll = true
	_scroll_target = maxf(0.0, _label.get_minimum_size().y - _scroll.size.y + 8.0)

	_next_btn.text = text_last if _index >= scenes.size() - 1 else text_next
	_next_btn.visible = true
	_next_btn.grab_focus()


# ============================================================ DETECCIÓN DEL JUGADOR

# Mientras se escribe se ignora al jugador (la barra sigue sola);
# al terminar, cualquier movimiento suyo cancela el scroll automático.
func _on_user_scrolled() -> void:
	if _typing:
		return
	_auto_scroll = false


func _on_scroll_gui_input(event: InputEvent) -> void:
	if _typing:
		return
	var wheel: bool = event is InputEventMouseButton and event.pressed \
		and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN)

	if wheel or event is InputEventScreenDrag or event is InputEventPanGesture:
		_auto_scroll = false


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
	_type_player.stop()  # corta el sonido de escribir
	if _music != null:
		create_tween().tween_property(_music, "volume_db", -60.0, fade_time)
	await _fade_to(1.0)
	if next_scene != "" and ResourceLoader.exists(next_scene):
		get_tree().change_scene_to_file(next_scene)
	else:
		push_warning("Cinemática: next_scene no es válida (índice %d)." % old_index)
