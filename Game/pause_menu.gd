extends CanvasLayer
## Menú de pausa (Esc durante el juego).
## Se usa como Autoload a partir de la escena pause_menu.tscn.
## Abre pause_menu.tscn, selecciona el nodo raíz y edita todo desde el Inspector.

# ============================================================ INSPECTOR
@export_group("General")
@export_file("*.tscn") var main_menu_scene: String = "res://main_menu.tscn"
@export var pause_action: StringName = &"ui_cancel"
@export var pause_title: String = "PAUSA"
## Opcional: si pones un Theme aquí (por ejemplo el mismo del menú principal)
## se usa en lugar de las opciones de fuentes y botones de abajo.
@export var menu_theme: Theme

@export_group("Fondo")
@export var dim_color: Color = Color(0, 0, 0, 0.65)
@export var background_texture: Texture2D

@export_group("Título")
@export var title_font: Font
@export var title_font_size: int = 56
@export var title_color: Color = Color.WHITE

@export_group("Fuente general")
@export var font: Font
@export var font_size: int = 24
@export var font_color: Color = Color.WHITE

@export_group("Botones - Aspecto")
@export var button_font: Font
@export var button_font_size: int = 24
@export var button_size: Vector2 = Vector2(360, 48)
@export var button_spacing: int = 12
@export var button_font_color: Color = Color.WHITE
@export var button_hover_font_color: Color = Color(1, 0.9, 0.5)
@export var button_pressed_font_color: Color = Color(0.8, 0.8, 0.8)
@export var button_disabled_font_color: Color = Color(0.5, 0.5, 0.5)

@export_group("Botones - Imágenes")
@export var button_normal_texture: Texture2D
@export var button_hover_texture: Texture2D
@export var button_pressed_texture: Texture2D
@export var button_disabled_texture: Texture2D

@export_group("Botones - Efecto hover")
## Recorta el margen transparente de las imágenes de los botones, para que el
## dibujo llene todo el botón y no se vea más chico que su tamaño.
@export var button_textures_trim: bool = true
## true = la imagen de hover se dibuja ENCIMA de la normal y aparece con un fundido
## (ideal para un contorno). false = reemplaza a la normal.
@export var button_hover_overlay: bool = true
## Cuánto sobresale la imagen de hover del borde del botón, en píxeles.
@export var button_hover_outline_grow: float = 0.0
## Escala del botón seleccionado (1.0 = tamaño normal).
@export_range(1.0, 1.5) var button_hover_scale: float = 1.1
## Escala de los demás botones del grupo mientras uno está seleccionado.
@export_range(0.5, 1.0) var button_other_scale: float = 0.95
## Duración de la transición, en segundos.
@export_range(0.0, 1.0) var button_fx_time: float = 0.18
## Color del texto de los botones del menú cuando están seleccionados.
@export var button_hover_text_color: Color = Color.BLACK
## Grosor del marco del texto cuando está seleccionado (0 = sin marco, se lee mejor en negro).
@export_range(0, 12) var button_hover_text_outline: int = 0

@export_group("Botones - Hover animado")
## Animación del contorno de hover, como en un AnimatedSprite2D: crea un recurso
## SpriteFrames, agrégale los cuadros y arrástralo aquí. Vacío = imagen estática.
@export var button_hover_sprite_frames: SpriteFrames
## Nombre de la animación dentro del SpriteFrames.
@export var button_hover_animation: StringName = &"default"
## Alternativa sencilla: arrastra aquí los PNG de cada cuadro, en orden.
## (Se usa solo si no hay SpriteFrames.)
@export var button_hover_frame_textures: Array[Texture2D] = []
## Cuadros por segundo para la lista de arriba. Con SpriteFrames se usa la
## velocidad (FPS) que tenga la animación.
@export_range(1.0, 30.0) var button_hover_fps: float = 8.0

@export_group("Botones - Variantes")
## Imágenes extra para el botón normal. El 1.er botón usa la imagen normal de arriba,
## el 2.º la 1.ª variante de esta lista, y así en ciclo.
@export var button_normal_variants: Array[Texture2D] = []
## Imagen de hover de cada variante (misma posición que en la lista de arriba).
## Si falta alguna, esa variante usa la imagen de hover principal.
@export var button_hover_variants: Array[Texture2D] = []
## Variación automática (no necesita imágenes extra). Todo desactivado por defecto.
## Voltea horizontalmente algunos botones al azar.
@export var button_variation_flip: bool = false
## Inclinación máxima aleatoria, en grados (prueba 0.8).
@export_range(0.0, 5.0) var button_variation_tilt: float = 0.0
## Variación aleatoria del ancho, como fracción (prueba 0.04 = ±4%).
@export_range(0.0, 0.3) var button_variation_width: float = 0.0
## Cambia este número para obtener otra combinación aleatoria.
@export var button_variation_seed: int = 7

@export_group("Botones - Colores (sin imagen)")
@export var button_normal_color: Color = Color(0.12, 0.12, 0.2, 0.85)
@export var button_hover_color: Color = Color(0.25, 0.25, 0.4, 0.95)
@export var button_pressed_color: Color = Color(0.08, 0.08, 0.15, 1.0)
@export var button_disabled_color: Color = Color(0.1, 0.1, 0.1, 0.5)
@export var button_corner_radius: int = 8

@export_group("Confirmación")
## Gris parecido al del diálogo original. Cámbialo a tu gusto.
@export var confirm_bg_color: Color = Color(0.2, 0.2, 0.2, 1.0)
@export var confirm_border_color: Color = Color(0.35, 0.35, 0.35, 1.0)
@export var confirm_border_width: int = 2
@export var confirm_dim_color: Color = Color(0, 0, 0, 0.45)
@export var confirm_padding: int = 24
@export var confirm_button_size: Vector2 = Vector2(220, 48)

@export_group("Textos")
@export var text_resume: String = "Volver al juego"
@export var text_settings: String = "Ajustes"
@export var text_to_menu: String = "Salir al menú principal"
@export var text_quit: String = "Salir del juego"
@export var text_back: String = "Volver"
@export var text_settings_title: String = "Ajustes"
@export var text_volume: String = "Volumen general"
@export var text_fullscreen: String = "Pantalla completa"
@export var text_save_title: String = "Guardar y salir"
@export_multiline var text_save_message: String = "Tu progreso se guardará en el último checkpoint alcanzado.\n¿Quieres guardar y salir?"
@export_multiline var text_save_message_none: String = "Todavía no has alcanzado ningún checkpoint.\nTu partida se guardará desde el inicio del nivel.\n¿Quieres guardar y salir?"
@export var text_save_yes: String = "Sí, guardar y salir"
@export var text_save_no: String = "No"

@export_group("Sonido")
@export var click_sound: AudioStream
@export var hover_sound: AudioStream
## Sonido SOLO para los botones que dicen "Volver" (text_back). Vacío = usa el click normal.
@export var back_sound: AudioStream
## Volumen de cada efecto en decibeles (0 = original, negativo = más bajo, -6 ≈ la mitad).
@export_range(-60.0, 6.0, 0.5, "suffix:dB") var click_volume_db: float = 0.0
@export_range(-60.0, 6.0, 0.5, "suffix:dB") var hover_volume_db: float = 0.0
@export_range(-60.0, 6.0, 0.5, "suffix:dB") var back_volume_db: float = 0.0
## Al pausar, congela TODA la musica/audio del juego (aunque el reproductor este en "Siempre" procesar,
## como la musica del jefe) y la reanuda al volver. Los sonidos del propio menu siguen sonando.
@export var pause_game_audio: bool = true
## Los nodos que esten en este grupo NO se pausan (por si quieres musica de menu o algo que siga sonando).
@export var keep_playing_group: StringName = &"pause_menu_keep_playing"

# ============================================================== INTERNO
var is_open: bool = false
var pages: Dictionary = {}
var root: Control
var confirm_overlay: ColorRect
var confirm_label: Label
var confirm_yes: Button
var pending_exit: String = ""
var volume_slider: HSlider
var fullscreen_check: CheckButton
var click_player: AudioStreamPlayer
var hover_player: AudioStreamPlayer
var back_player: AudioStreamPlayer
var _paused_audio: Array = []   # reproductores que pausamos nosotros (para reanudar solo esos)

var _n_tex: Texture2D
var _h_tex: Texture2D
var _p_tex: Texture2D
var _d_tex: Texture2D
var _fx_normal_texs: Array[Texture2D] = []
var _fx_hover_texs: Array[Texture2D] = []
var _fx_hover_frames: Array[Texture2D] = []
var _fx_hover_fps: float = 8.0
var _fx_counter: int = 0
var _fx_rng := RandomNumberGenerator.new()


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_fx_rng.seed = button_variation_seed
	_build_audio()
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(pause_action):
		return
	if not SaveManager.in_game:
		return
	get_viewport().set_input_as_handled()
	if not is_open:
		_open()
	elif confirm_overlay.visible:
		_close_confirm()
	elif pages["main"].visible:
		_resume()
	else:
		_show_page("main")


# ================================================================= TEMA

func _make_box(tex: Texture2D, color: Color) -> StyleBox:
	if tex != null:
		var sbt := StyleBoxTexture.new()
		sbt.texture = tex
		return sbt
	var sbf := StyleBoxFlat.new()
	sbf.bg_color = color
	sbf.set_corner_radius_all(button_corner_radius)
	sbf.content_margin_left = 16
	sbf.content_margin_right = 16
	return sbf


## Prepara las imágenes de los botones (recorte, variantes y cuadros de hover).
func _prepare_fx_assets() -> void:
	_n_tex = _prep_button_tex(button_normal_texture)
	_h_tex = _prep_button_tex(button_hover_texture)
	_p_tex = _prep_button_tex(button_pressed_texture)
	_d_tex = _prep_button_tex(button_disabled_texture)

	# Imágenes por variante (la 0 es la principal)
	_fx_normal_texs.clear()
	_fx_hover_texs.clear()
	if _n_tex != null:
		_fx_normal_texs.append(_n_tex)
		_fx_hover_texs.append(_h_tex)
		for i in button_normal_variants.size():
			var vn: Texture2D = _prep_button_tex(button_normal_variants[i])
			if vn == null:
				continue
			var vh: Texture2D = _h_tex
			if i < button_hover_variants.size() and button_hover_variants[i] != null:
				vh = _prep_button_tex(button_hover_variants[i])
			_fx_normal_texs.append(vn)
			_fx_hover_texs.append(vh)

	# Cuadros de la animación de hover (si hay)
	var raw: Array[Texture2D] = []
	_fx_hover_fps = button_hover_fps
	if button_hover_sprite_frames != null and button_hover_sprite_frames.has_animation(button_hover_animation):
		var an: StringName = button_hover_animation
		for i in button_hover_sprite_frames.get_frame_count(an):
			var ft: Texture2D = button_hover_sprite_frames.get_frame_texture(an, i)
			if ft != null:
				raw.append(ft)
		_fx_hover_fps = maxf(1.0, button_hover_sprite_frames.get_animation_speed(an))
	else:
		for tx in button_hover_frame_textures:
			if tx != null:
				raw.append(tx)
	_fx_hover_frames = _trim_union(raw)


func _make_theme() -> Theme:
	_prepare_fx_assets()
	if menu_theme != null:
		return menu_theme
	var t := Theme.new()
	if font != null:
		t.default_font = font
	t.default_font_size = font_size
	t.set_color("font_color", "Label", font_color)
	if button_font != null:
		t.set_font("font", "Button", button_font)
	t.set_font_size("font_size", "Button", button_font_size)
	t.set_color("font_color", "Button", button_font_color)
	t.set_color("font_hover_color", "Button", button_hover_font_color)
	t.set_color("font_focus_color", "Button", button_hover_font_color)
	t.set_color("font_pressed_color", "Button", button_pressed_font_color)
	t.set_color("font_disabled_color", "Button", button_disabled_font_color)

	var normal_box: StyleBox = _make_box(_n_tex, button_normal_color)
	var hover_box: StyleBox
	if button_hover_overlay and _n_tex != null and _h_tex != null:
		hover_box = normal_box
	else:
		hover_box = _make_box(_h_tex, button_hover_color)
	var pressed_box: StyleBox = normal_box if (_p_tex == null and _n_tex != null) else _make_box(_p_tex, button_pressed_color)
	var disabled_box: StyleBox = normal_box if (_d_tex == null and _n_tex != null) else _make_box(_d_tex, button_disabled_color)
	t.set_stylebox("normal", "Button", normal_box)
	t.set_stylebox("hover", "Button", hover_box)
	t.set_stylebox("focus", "Button", hover_box)
	t.set_stylebox("pressed", "Button", pressed_box)
	t.set_stylebox("disabled", "Button", disabled_box)
	return t


## Devuelve el logo sin el margen transparente que lo rodea.
func _trim_texture(tex: Texture2D) -> Texture2D:
	var img: Image = tex.get_image()
	if img == null:
		return tex
	var used: Rect2i = img.get_used_rect()
	if used.size == Vector2i.ZERO or used.size == img.get_size():
		return tex
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(used)
	atlas.filter_clip = true
	return atlas


## Recorta todos los cuadros con el MISMO rectángulo (la unión de todos), para
## que la animación no "salte" ni se deforme de un cuadro a otro.
func _trim_union(texs: Array[Texture2D]) -> Array[Texture2D]:
	if not button_textures_trim or texs.is_empty():
		return texs
	var union := Rect2i()
	var found: bool = false
	for t in texs:
		var img: Image = t.get_image()
		if img == null:
			return texs
		var r: Rect2i = img.get_used_rect()
		if r.size == Vector2i.ZERO:
			continue
		union = r if not found else union.merge(r)
		found = true
	if not found:
		return texs
	var out: Array[Texture2D] = []
	for t in texs:
		var a := AtlasTexture.new()
		a.atlas = t
		a.region = Rect2(union)
		a.filter_clip = true
		out.append(a)
	return out


func _prep_button_tex(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	return _trim_texture(tex) if button_textures_trim else tex


# ================================================================ AUDIO

func _build_audio() -> void:
	click_player = AudioStreamPlayer.new()
	click_player.stream = click_sound
	click_player.volume_db = click_volume_db
	add_child(click_player)
	hover_player = AudioStreamPlayer.new()
	hover_player.stream = hover_sound
	hover_player.volume_db = hover_volume_db
	add_child(hover_player)

	back_player = AudioStreamPlayer.new()
	back_player.stream = back_sound
	back_player.volume_db = back_volume_db
	add_child(back_player)


## Congela todos los reproductores que estan sonando (excepto los del menu y el grupo de excepciones).
## Se recorre todo el arbol porque algunos (como la musica del jefe) usan PROCESS_MODE_ALWAYS
## y no se detienen solos con get_tree().paused.
func _pause_audio() -> void:
	_paused_audio.clear()
	if not pause_game_audio:
		return
	for n in get_tree().root.find_children("*", "", true, false):
		if n == click_player or n == hover_player or n == back_player:
			continue
		if not (n is AudioStreamPlayer or n is AudioStreamPlayer2D or n is AudioStreamPlayer3D):
			continue
		if n.is_in_group(keep_playing_group):
			continue
		if n.playing and not n.stream_paused:
			n.stream_paused = true
			_paused_audio.append(n)


func _resume_audio() -> void:
	for n in _paused_audio:
		if is_instance_valid(n):
			n.stream_paused = false
	_paused_audio.clear()


func _play_click() -> void:
	if click_sound != null:
		click_player.play()


func _play_back() -> void:
	if back_sound != null:
		back_player.play()
	else:
		_play_click()


func _play_hover() -> void:
	if hover_sound != null:
		hover_player.play()


# ============================================================ CONSTRUCCIÓN

func _build_ui() -> void:
	root = Control.new()
	root.theme = _make_theme()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = dim_color
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if background_texture != null:
		var bg := TextureRect.new()
		bg.texture = background_texture
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(bg)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 30)
	center.add_child(column)

	var title := Label.new()
	title.text = pause_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", title_font_size)
	title.add_theme_color_override("font_color", title_color)
	if title_font != null:
		title.add_theme_font_override("font", title_font)
	column.add_child(title)

	var holder := Control.new()
	holder.custom_minimum_size = Vector2(560, 300)
	column.add_child(holder)

	_build_main_page(holder)
	_build_settings_page(holder)
	_build_confirm_panel()


func _build_confirm_panel() -> void:
	# Panel propio en lugar de ConfirmationDialog (evita el brillo del entorno).
	# Se agrega al final de root para que quede por encima de todo.
	confirm_overlay = ColorRect.new()
	confirm_overlay.color = confirm_dim_color
	confirm_overlay.visible = false
	confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(confirm_overlay)
	confirm_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var confirm_center := CenterContainer.new()
	confirm_overlay.add_child(confirm_center)
	confirm_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = confirm_bg_color
	panel_style.border_color = confirm_border_color
	panel_style.set_border_width_all(confirm_border_width)
	panel_style.set_corner_radius_all(button_corner_radius)
	panel_style.set_content_margin_all(confirm_padding)
	panel.add_theme_stylebox_override("panel", panel_style)
	confirm_center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	panel.add_child(box)

	var confirm_title := Label.new()
	confirm_title.text = text_save_title
	confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_title.add_theme_font_size_override("font_size", font_size + 6)
	box.add_child(confirm_title)

	confirm_label = Label.new()
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(confirm_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	confirm_yes = _make_button(text_save_yes, _on_exit_confirmed, row, confirm_button_size)
	_make_button(text_save_no, _close_confirm, row, confirm_button_size)
	_register_fx_group(row.get_children())


func _make_page(parent: Control, page_name: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", button_spacing)
	page.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages[page_name] = page
	return page


func _make_button(text: String, callback: Callable, parent: Control, size: Vector2 = Vector2.ZERO) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = button_size if size == Vector2.ZERO else size
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Los botones que dicen "Volver" usan su propio sonido; los demas, el click normal.
	b.pressed.connect(_play_back if text == text_back else _play_click)
	b.pressed.connect(callback)
	# Efecto hover (escala, contorno, color de texto). El mouse toma el foco,
	# así que el sonido de hover sale del foco.
	_fx_setup(b)
	b.focus_entered.connect(_play_hover)
	parent.add_child(b)
	return b


# ============================================================ EFECTO HOVER

func _fx_setup(b: Button) -> void:
	var idx: int = _fx_counter
	_fx_counter += 1
	b.set_meta("fx_group", [b])
	b.resized.connect(func(): b.pivot_offset = b.size * 0.5)

	# Variación automática (ancho, inclinación y volteo), con semilla fija
	if button_variation_width > 0.0:
		var k: float = 1.0 + _fx_rng.randf_range(-button_variation_width, button_variation_width)
		b.custom_minimum_size.x = roundf(b.custom_minimum_size.x * k)
	if button_variation_tilt > 0.0:
		b.rotation_degrees = _fx_rng.randf_range(-button_variation_tilt, button_variation_tilt)
	var flip: bool = button_variation_flip and _fx_rng.randf() < 0.5

	# Capas de imagen: fondo normal + contorno de hover, ambas DETRÁS del texto
	if not _fx_normal_texs.is_empty():
		var v: int = idx % _fx_normal_texs.size()
		for state in ["normal", "hover", "focus", "pressed", "disabled"]:
			b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var base := _fx_layer(_fx_normal_texs[v], 0.0, flip)
		b.add_child(base)
		b.set_meta("fx_base", base)
		var animated: bool = not _fx_hover_frames.is_empty()
		if animated or _fx_hover_texs[v] != null:
			var start_frame: int = idx % _fx_hover_frames.size() if animated else 0
			var first_tex: Texture2D = _fx_hover_frames[start_frame] if animated else _fx_hover_texs[v]
			var ov := _fx_layer(first_tex, button_hover_outline_grow, flip)
			ov.modulate.a = 0.0
			b.add_child(ov)
			b.set_meta("fx_overlay", ov)
			b.set_meta("fx_frame", start_frame)

	b.mouse_entered.connect(func():
		if not b.disabled:
			b.grab_focus())
	b.focus_entered.connect(_fx_changed.bind(b))
	b.focus_exited.connect(_fx_changed.bind(b))


func _fx_layer(tex: Texture2D, grow: float, flip: bool) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.flip_h = flip
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.offset_left = -grow
	r.offset_top = -grow
	r.offset_right = grow
	r.offset_bottom = grow
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.show_behind_parent = true
	return r


## Agrupa botones: cuando uno se selecciona, los demás del grupo se achican.
func _register_fx_group(nodes: Array) -> void:
	var group: Array = []
	for n in nodes:
		if n is Button:
			group.append(n)
	for btn in group:
		btn.set_meta("fx_group", group)


func _fx_changed(b: Button) -> void:
	# Diferido: al mover el foco se emiten "salió" y "entró" en el mismo frame
	_fx_apply.call_deferred(b.get_meta("fx_group"))


func _fx_apply(group: Array) -> void:
	var active: Button = null
	for g in group:
		if is_instance_valid(g) and (g as Button).has_focus():
			active = g
			break
	for g in group:
		if not is_instance_valid(g):
			continue
		var btn: Button = g
		var target: float = 1.0
		var p: float = 0.0
		if btn == active:
			target = button_hover_scale
			p = 1.0
		elif active != null and group.size() > 1:
			target = button_other_scale
		btn.z_index = 1 if btn == active else 0
		_fx_tween(btn, target, p)
		if btn == active:
			_fx_anim_start(btn)
		else:
			_fx_anim_stop(btn)


func _fx_tween(b: Button, scale_to: float, p_to: float, step: Callable = Callable()) -> void:
	if b.has_meta("fx_tween"):
		var old: Tween = b.get_meta("fx_tween")
		if old != null and old.is_valid():
			old.kill()
	var target_scale: Vector2 = Vector2.ONE * scale_to
	var p_from: float = b.get_meta("fx_p") if b.has_meta("fx_p") else 0.0
	var st: Callable = step if step.is_valid() else _fx_step
	if button_fx_time <= 0.0:
		b.scale = target_scale
		st.call(p_to, b)
		return
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", target_scale, button_fx_time)
	tw.tween_method(st.bind(b), p_from, p_to, button_fx_time)
	b.set_meta("fx_tween", tw)


## Reproduce los cuadros del contorno en bucle mientras el botón está seleccionado.
func _fx_anim_start(b: Button) -> void:
	var n: int = _fx_hover_frames.size()
	if n < 2 or not b.has_meta("fx_overlay"):
		return
	if b.has_meta("fx_anim"):
		var running: Tween = b.get_meta("fx_anim")
		if running != null and running.is_valid() and running.is_running():
			return
	var from: int = b.get_meta("fx_frame") if b.has_meta("fx_frame") else 0
	var tw := create_tween().set_loops()
	tw.tween_method(_fx_set_frame.bind(b), float(from), float(from + n), float(n) / _fx_hover_fps)
	b.set_meta("fx_anim", tw)


## Se detiene en el cuadro actual (el contorno se desvanece con ese cuadro).
func _fx_anim_stop(b: Button) -> void:
	if b.has_meta("fx_anim"):
		var tw: Tween = b.get_meta("fx_anim")
		if tw != null and tw.is_valid():
			tw.kill()
		b.remove_meta("fx_anim")


func _fx_set_frame(v: float, b: Button) -> void:
	if not is_instance_valid(b) or _fx_hover_frames.is_empty():
		return
	var i: int = int(v) % _fx_hover_frames.size()
	var ov: TextureRect = b.get_meta("fx_overlay")
	if ov.texture != _fx_hover_frames[i]:
		ov.texture = _fx_hover_frames[i]
	b.set_meta("fx_frame", i)


## p = 0 (reposo) a 1 (seleccionado): fundido del contorno y color del texto.
func _fx_step(p: float, b: Button) -> void:
	if not is_instance_valid(b):
		return
	b.set_meta("fx_p", p)
	if not b.has_meta("fx_color0"):
		b.set_meta("fx_color0", b.get_theme_color("font_color"))
		b.set_meta("fx_outline0", b.get_theme_constant("outline_size"))
	var c: Color = (b.get_meta("fx_color0") as Color).lerp(button_hover_text_color, p)
	for key in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(key, c)
	var o: int = int(roundf(lerpf(float(b.get_meta("fx_outline0")), float(button_hover_text_outline), p)))
	b.add_theme_constant_override("outline_size", o)
	if b.has_meta("fx_overlay"):
		(b.get_meta("fx_overlay") as Control).modulate.a = p
	if b.has_meta("fx_base") and not button_hover_overlay:
		(b.get_meta("fx_base") as Control).modulate.a = 1.0 - p


func _build_main_page(holder: Control) -> void:
	var p := _make_page(holder, "main")
	_make_button(text_resume, _resume, p)
	_make_button(text_settings, func(): _show_page("settings"), p)
	_make_button(text_to_menu, func(): _ask_exit("menu"), p)
	_make_button(text_quit, func(): _ask_exit("quit"), p)
	_register_fx_group(p.get_children())


func _build_settings_page(holder: Control) -> void:
	var p := _make_page(holder, "settings")

	var heading := Label.new()
	heading.text = text_settings_title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", font_size + 6)
	p.add_child(heading)

	var vol_label := Label.new()
	vol_label.text = text_volume
	vol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(vol_label)

	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.custom_minimum_size = Vector2(320, 24)
	volume_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volume_slider.value_changed.connect(func(v: float):
		SaveManager.settings["master_volume"] = v
		SaveManager.apply_settings())
	p.add_child(volume_slider)

	fullscreen_check = CheckButton.new()
	fullscreen_check.text = text_fullscreen
	fullscreen_check.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fullscreen_check.toggled.connect(func(on: bool):
		SaveManager.settings["fullscreen"] = on
		SaveManager.apply_settings())
	p.add_child(fullscreen_check)

	_make_button(text_back, func():
		SaveManager.save_settings()
		_show_page("main"), p)


# =============================================================== NAVEGACIÓN

func _show_page(page_name: String) -> void:
	for key in pages.keys():
		pages[key].visible = (key == page_name)
	if page_name == "settings":
		volume_slider.set_value_no_signal(SaveManager.settings["master_volume"])
		fullscreen_check.set_pressed_no_signal(SaveManager.settings["fullscreen"])
	for c in pages[page_name].find_children("*", "BaseButton", true, false):
		if not c.disabled and c.is_visible_in_tree():
			c.grab_focus()
			break


func _open() -> void:
	is_open = true
	visible = true
	confirm_overlay.visible = false
	_pause_audio()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_show_page("main")


func _resume() -> void:
	is_open = false
	visible = false
	confirm_overlay.visible = false
	get_tree().paused = false
	_resume_audio()


# ============================================================ SALIR / GUARDAR

func _ask_exit(action: String) -> void:
	pending_exit = action
	if SaveManager.session_has_checkpoint:
		confirm_label.text = text_save_message
	else:
		confirm_label.text = text_save_message_none
	confirm_overlay.visible = true
	confirm_yes.grab_focus()


func _close_confirm() -> void:
	confirm_overlay.visible = false
	_show_page("main")


func _on_exit_confirmed() -> void:
	confirm_overlay.visible = false
	SaveManager.save_progress()
	if pending_exit == "menu":
		is_open = false
		visible = false
		get_tree().paused = false
		_resume_audio()
		SaveManager.end_session()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if ResourceLoader.exists(main_menu_scene):
			get_tree().change_scene_to_file(main_menu_scene)
		else:
			push_error("PauseMenu: no existe la escena del menú principal: " + main_menu_scene)
	else:
		get_tree().quit()
