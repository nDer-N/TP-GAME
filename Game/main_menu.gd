extends Control
## Menú principal.
## Selecciona el nodo MainMenu y edita todo desde el Inspector:
## fondo, título, fuentes, imágenes de botones, textos y sonidos.

# ============================================================ INSPECTOR
@export_group("Juego")
@export_file("*.tscn") var game_scene: String = "res://tutorial.tscn"
@export_file("*.tscn") var intro_scene: String = "res://intro_cinematic.tscn"
@export var game_title: String = "NOMBRE DE MI JUEGO"
@export_multiline var credits_text: String = "Desarrollo\nTu nombre aquí\n\nArte\nNombre del artista\n\nMúsica y sonido\nNombre del compositor\n\nHecho con Godot Engine\n\n¡Gracias por jugar!"

@export_group("Fondo")
## Escena de fondo con parallax (splash.tscn). Si existe, sustituye al color
## y a la textura de abajo. Déjala vacía para usar el fondo clásico.
@export_file("*.tscn") var splash_scene: String = "res://splash.tscn"
@export var background_color: Color = Color(0.05, 0.04, 0.09)
## Tu imagen de fondo (opcional). Se dibuja encima del color.
@export var background_texture: Texture2D
@export var background_stretch: TextureRect.StretchMode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

@export_group("Título")
## Si pones una imagen (logo), se muestra en lugar del texto.
@export var title_logo: Texture2D
## Tamaño del logo. (0, 0) = tamaño original de la imagen.
@export var title_logo_size: Vector2 = Vector2.ZERO
@export var title_font: Font
@export var title_font_size: int = 64
@export var title_color: Color = Color.WHITE
@export var title_spacing: int = 40

@export_group("Fuente general")
## Fuente para todos los textos (ajustes, créditos, etc.)
@export var font: Font
@export var font_size: int = 24
@export var font_color: Color = Color.WHITE

@export_group("Texto - Contorno y sombra")
## Marco alrededor de las letras. 0 = sin marco.
@export var text_outline_size: int = 6
@export var text_outline_color: Color = Color(0, 0, 0, 1)
## Marco más grueso solo para el título.
@export var title_outline_size: int = 12
## Sombra debajo del texto (solo en etiquetas; los botones no la soportan).
@export var text_shadow_enabled: bool = true
@export var text_shadow_color: Color = Color(0, 0, 0, 0.6)
@export var text_shadow_offset: Vector2 = Vector2(2, 3)

@export_group("Botones - Aspecto")
@export var button_font: Font
@export var button_font_size: int = 24
@export var button_size: Vector2 = Vector2(320, 48)
@export var slot_button_size: Vector2 = Vector2(560, 84)
@export var button_spacing: int = 12
@export var button_font_color: Color = Color.WHITE
@export var button_hover_font_color: Color = Color(1, 0.9, 0.5)
@export var button_pressed_font_color: Color = Color(0.8, 0.8, 0.8)
@export var button_disabled_font_color: Color = Color(0.5, 0.5, 0.5)

@export_group("Botones - Imágenes")
## Si dejas una imagen vacía se usa el color plano de abajo.
@export var button_normal_texture: Texture2D
@export var button_hover_texture: Texture2D
@export var button_pressed_texture: Texture2D
@export var button_disabled_texture: Texture2D

@export_group("Botones - Colores (sin imagen)")
@export var button_normal_color: Color = Color(0.12, 0.12, 0.2, 0.85)
@export var button_hover_color: Color = Color(0.25, 0.25, 0.4, 0.95)
@export var button_pressed_color: Color = Color(0.08, 0.08, 0.15, 1.0)
@export var button_disabled_color: Color = Color(0.1, 0.1, 0.1, 0.5)
@export var button_corner_radius: int = 8

@export_group("Partidas guardadas")
## Icono del bote de basura. Si lo dejas vacío se usa uno incluido.
@export var delete_icon: Texture2D
## Icono para cambiar el nombre. Si lo dejas vacío se usa uno incluido.
@export var rename_icon: Texture2D
@export var icon_button_size: Vector2 = Vector2(84, 84)
@export var name_max_length: int = 24
## Color de brillo de las tarjetas de partida (borde, número y resplandor).
@export var slot_accent_color: Color = Color(1.0, 0.78, 0.35)
@export var text_slot_empty: String = "Espacio vacío"
@export var text_slot_empty_new: String = "Toca para empezar una aventura"
@export var text_slot_empty_load: String = "Sin partida guardada"

@export_group("Textos de los botones")
@export var text_continue: String = "Continuar"
@export var text_new_game: String = "Nuevo juego"
@export var text_load: String = "Cargar"
@export var text_settings: String = "Ajustes"
@export var text_credits: String = "Créditos"
@export var text_quit: String = "Salir"
@export var text_back: String = "Volver"

@export_group("Textos de las pantallas")
@export var text_slots_new_title: String = "Nuevo juego — elige un espacio"
@export var text_slots_load_title: String = "Cargar partida"
@export var text_settings_title: String = "Ajustes"
@export var text_credits_title: String = "Créditos"
@export var text_volume: String = "Volumen general"
@export var text_fullscreen: String = "Pantalla completa"

@export_group("Textos de ventanas")
@export var text_overwrite_title: String = "Sobrescribir"
@export var text_overwrite_message: String = "Este espacio ya tiene una partida.\n¿Borrarla y empezar una nueva?"
@export var text_overwrite_yes: String = "Sí, sobrescribir"
@export var text_overwrite_no: String = "Cancelar"
@export var text_default_slot_name: String = "Partida"
@export var text_name_new_title: String = "Nombre de tu partida"
@export var text_name_rename_title: String = "Cambiar nombre"
@export var text_name_placeholder: String = "Escribe un nombre"
@export var text_name_ok: String = "Aceptar"
@export var text_cancel: String = "Cancelar"
@export var text_delete_title: String = "Eliminar partida"
## Usa {name} para mostrar el nombre de la partida.
@export var text_delete_message: String = "¿Seguro que quieres eliminar «{name}»?\nEsta acción no se puede deshacer."
@export var text_delete_yes: String = "Sí"
@export var text_delete_no: String = "No"
@export var text_rename_tooltip: String = "Cambiar nombre"
@export var text_delete_tooltip: String = "Eliminar partida"

@export_group("Sonido")
## Arrastra aquí tu canción (.mp3, .ogg o .wav). Vacío = sin música.
@export var menu_music: AudioStream
@export_range(-40.0, 6.0) var music_volume_db: float = -6.0
@export var music_fade_in: float = 1.5
## Fundido de salida al empezar o cargar una partida.
@export var music_fade_out: float = 0.8
## Repite la canción mientras estés en el menú.
@export var music_loop: bool = true
@export var music_bus: String = "Master"
@export var click_sound: AudioStream
@export var hover_sound: AudioStream

@export_group("Pantalla de carga")
@export var text_loading: String = "CARGANDO"
## Usa {name} para mostrar el nombre de la partida.
@export var text_loading_slot: String = "Partida: {name}"
@export var loading_font: Font
@export var loading_font_size: int = 56
@export var loading_sub_font_size: int = 22
@export var loading_font_color: Color = Color.WHITE
## Color de brillo: línea, barra, brasas y bordes.
@export var loading_accent_color: Color = Color(0, 1, 1)
## Oscurece el menú de fondo (0 = nada, 1 = negro total).
@export_range(0.0, 1.0) var loading_dim: float = 0.6
## Alto de las barras de cine (0 = sin barras).
@export var loading_cinema_bars: float = 90.0
@export var loading_bar_width: float = 420.0
@export var loading_embers: bool = true
@export var loading_fade_time: float = 0.6
## Tiempo mínimo que se ve la pantalla (para que alcance a lucirse).
@export var loading_min_time: float = 1.6

# ============================================================== INTERNO
const TRASH_SVG := "<svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><polyline points='3 6 5 6 21 6'/><path d='M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6'/><path d='M10 11v6M14 11v6'/><path d='M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2'/></svg>"
const PENCIL_SVG := "<svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M12 20h9'/><path d='M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z'/></svg>"

var _music_tween: Tween
var _leaving: bool = false
var pages: Dictionary = {}
var slots_mode: String = "new"
var slots_title: Label
var slot_buttons: Array[Button] = []
var rename_buttons: Array[Button] = []
var delete_buttons: Array[Button] = []
var slot_rows: Array[Control] = []
var slot_contents: Array[Control] = []
var slot_nums: Array[Label] = []
var slot_names: Array[Label] = []
var slot_infos: Array[Label] = []
var continue_btn: Button
var confirm: ConfirmationDialog
var delete_confirm: ConfirmationDialog
var name_dialog: ConfirmationDialog
var name_edit: LineEdit
var name_action: String = "new"     # "new" o "rename"
var pending_slot: int = -1
var music_player: AudioStreamPlayer
var click_player: AudioStreamPlayer
var hover_player: AudioStreamPlayer
var delete_tex: Texture2D
var rename_tex: Texture2D
var loading_layer: CanvasLayer
var _current_slot: int = -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Por si venimos del juego: sin partida activa, sin pausa y con ratón visible
	SaveManager.end_session()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	delete_tex = delete_icon if delete_icon != null else _svg_icon(TRASH_SVG)
	rename_tex = rename_icon if rename_icon != null else _svg_icon(PENCIL_SVG)
	_build_theme()
	_build_audio()
	_build_ui()
	_show_page("main")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not pages["main"].visible:
		_show_page("main")
		get_viewport().set_input_as_handled()


func _svg_icon(svg: String) -> Texture2D:
	var img := Image.new()
	var err: int = img.load_svg_from_string(svg, 2.0)
	if err != OK:
		return null
	return ImageTexture.create_from_image(img)


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


func _build_theme() -> void:
	# Si tú le asignas un Theme al nodo, se respeta y no se crea este.
	if theme != null:
		return
	var t := Theme.new()
	if font != null:
		t.default_font = font
	t.default_font_size = font_size
	t.set_color("font_color", "Label", font_color)

	# Marco negro en todos los textos
	for type_name in ["Label", "Button", "CheckButton"]:
		t.set_constant("outline_size", type_name, text_outline_size)
		t.set_color("font_outline_color", type_name, text_outline_color)

	# Sombra (solo Label)
	if text_shadow_enabled:
		t.set_color("font_shadow_color", "Label", text_shadow_color)
		t.set_constant("shadow_offset_x", "Label", int(text_shadow_offset.x))
		t.set_constant("shadow_offset_y", "Label", int(text_shadow_offset.y))
		t.set_constant("shadow_outline_size", "Label", text_outline_size)

	if button_font != null:
		t.set_font("font", "Button", button_font)
	t.set_font_size("font_size", "Button", button_font_size)
	t.set_color("font_color", "Button", button_font_color)
	t.set_color("font_hover_color", "Button", button_hover_font_color)
	t.set_color("font_focus_color", "Button", button_hover_font_color)
	t.set_color("font_pressed_color", "Button", button_pressed_font_color)
	t.set_color("font_disabled_color", "Button", button_disabled_font_color)

	var hover_box := _make_box(button_hover_texture, button_hover_color)
	t.set_stylebox("normal", "Button", _make_box(button_normal_texture, button_normal_color))
	t.set_stylebox("hover", "Button", hover_box)
	t.set_stylebox("focus", "Button", hover_box)
	t.set_stylebox("pressed", "Button", _make_box(button_pressed_texture, button_pressed_color))
	t.set_stylebox("disabled", "Button", _make_box(button_disabled_texture, button_disabled_color))
	theme = t


# ================================================================ AUDIO

func _build_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = music_bus
	add_child(music_player)
	_music_start()

	click_player = AudioStreamPlayer.new()
	click_player.stream = click_sound
	add_child(click_player)

	hover_player = AudioStreamPlayer.new()
	hover_player.stream = hover_sound
	add_child(hover_player)


func _music_start() -> void:
	if menu_music == null:
		return
	# Duplicamos el stream para activar el loop sin modificar el recurso original.
	var stream := menu_music.duplicate() as AudioStream
	if music_loop:
		if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
			stream.loop = true
		elif stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music_player.stream = stream
	music_player.volume_db = -60.0
	music_player.play()
	_music_tween = create_tween()
	_music_tween.tween_property(music_player, "volume_db", music_volume_db, music_fade_in)


func _music_fade_out() -> void:
	if music_player == null or not music_player.playing:
		return
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(music_player, "volume_db", -60.0, music_fade_out)
	await _music_tween.finished


func _play_click() -> void:
	if click_sound != null:
		click_player.play()


func _play_hover() -> void:
	if hover_sound != null:
		hover_player.play()


# ============================================================ CONSTRUCCIÓN

func _build_background() -> void:
	# 1) Escena aparte con parallax (splash.tscn)
	if splash_scene != "" and ResourceLoader.exists(splash_scene):
		var packed := load(splash_scene) as PackedScene
		if packed != null:
			# Su raíz es un ParallaxBackground (CanvasLayer en la capa -100),
			# así que se dibuja detrás de todo el menú.
			add_child(packed.instantiate())
			return

	# 2) Respaldo: color + textura estática
	var bg_color := ColorRect.new()
	bg_color.color = background_color
	bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_color)

	if background_texture != null:
		var bg_tex := TextureRect.new()
		bg_tex.texture = background_texture
		bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_tex.stretch_mode = background_stretch
		bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg_tex)


func _build_ui() -> void:
	_build_background()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", title_spacing)
	center.add_child(root)

	root.add_child(_build_title())

	var holder := Control.new()
	holder.custom_minimum_size = Vector2(800, 440)
	root.add_child(holder)

	_build_main_page(holder)
	_build_slots_page(holder)
	_build_settings_page(holder)
	_build_credits_page(holder)
	_build_dialogs()


func _build_dialogs() -> void:
	# Sobrescribir una partida existente (al crear nuevo juego)
	confirm = ConfirmationDialog.new()
	confirm.title = text_overwrite_title
	confirm.dialog_text = text_overwrite_message
	confirm.ok_button_text = text_overwrite_yes
	confirm.cancel_button_text = text_overwrite_no
	confirm.confirmed.connect(func(): _ask_name_new(pending_slot))
	add_child(confirm)

	# Eliminar una partida
	delete_confirm = ConfirmationDialog.new()
	delete_confirm.title = text_delete_title
	delete_confirm.ok_button_text = text_delete_yes
	delete_confirm.cancel_button_text = text_delete_no
	delete_confirm.confirmed.connect(_on_delete_confirmed)
	add_child(delete_confirm)

	# Escribir / cambiar el nombre de una partida
	name_dialog = ConfirmationDialog.new()
	name_dialog.ok_button_text = text_name_ok
	name_dialog.cancel_button_text = text_cancel
	name_edit = LineEdit.new()
	name_edit.max_length = name_max_length
	name_edit.placeholder_text = text_name_placeholder
	name_edit.custom_minimum_size = Vector2(340, 0)
	name_edit.text_submitted.connect(func(_t: String):
		name_dialog.hide()
		_on_name_confirmed())
	name_dialog.add_child(name_edit)
	name_dialog.confirmed.connect(_on_name_confirmed)
	add_child(name_dialog)


func _build_title() -> Control:
	if title_logo != null:
		var logo := TextureRect.new()
		logo.texture = title_logo
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if title_logo_size == Vector2.ZERO:
			logo.custom_minimum_size = title_logo.get_size()
		else:
			logo.custom_minimum_size = title_logo_size
		logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		return logo

	var title := Label.new()
	title.text = game_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", title_font_size)
	title.add_theme_color_override("font_color", title_color)
	title.add_theme_constant_override("outline_size", title_outline_size)
	title.add_theme_color_override("font_outline_color", text_outline_color)
	if title_font != null:
		title.add_theme_font_override("font", title_font)
	return title


func _make_page(parent: Control, page_name: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", button_spacing)
	page.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(page)
	pages[page_name] = page
	return page


func _make_button(text: String, callback: Callable, parent: Control, size: Vector2 = Vector2.ZERO) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = button_size if size == Vector2.ZERO else size
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_play_click)
	b.pressed.connect(callback)
	b.mouse_entered.connect(_play_hover)
	b.focus_entered.connect(_play_hover)
	parent.add_child(b)
	return b


func _make_icon_button(icon: Texture2D, fallback_text: String, tip: String, callback: Callable, parent: Control) -> Button:
	var b := _make_button("", callback, parent, icon_button_size)
	b.tooltip_text = tip
	if icon != null:
		b.icon = icon
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		b.text = fallback_text
	return b


func _make_heading(text: String, parent: Control) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size + 6)
	parent.add_child(l)
	return l


func _build_main_page(holder: Control) -> void:
	var p := _make_page(holder, "main")
	continue_btn = _make_button(text_continue, _on_continue, p)
	_make_button(text_new_game, func(): _open_slots("new"), p)
	_make_button(text_load, func(): _open_slots("load"), p)
	_make_button(text_settings, func(): _show_page("settings"), p)
	_make_button(text_credits, func(): _show_page("credits"), p)
	_make_button(text_quit, func(): get_tree().quit(), p)


func _card_box(bg: Color, border: Color, border_w: int, left_w: int, glow: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(button_corner_radius + 4)
	sb.border_width_left = left_w
	sb.border_width_top = border_w
	sb.border_width_right = border_w
	sb.border_width_bottom = border_w
	sb.border_color = border
	sb.set_content_margin_all(10)
	if glow > 0:
		sb.shadow_color = Color(border.r, border.g, border.b, 0.35)
		sb.shadow_size = glow
	return sb


func _apply_card_styles(b: Button, accent: Color) -> void:
	var soft := Color(accent.r, accent.g, accent.b, 0.35)
	var hover := _card_box(Color(0.13, 0.10, 0.20, 0.96), accent, 2, 6, 14)
	b.add_theme_stylebox_override("normal", _card_box(Color(0.06, 0.05, 0.11, 0.90), soft, 1, 5, 0))
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("pressed", _card_box(Color(0.04, 0.03, 0.08, 1.0), accent, 2, 6, 0))
	b.add_theme_stylebox_override("disabled", _card_box(Color(0.05, 0.05, 0.07, 0.6), Color(1, 1, 1, 0.10), 1, 5, 0))


## Contenido de una tarjeta de partida: número grande, línea divisoria,
## nombre y una línea pequeña con la fecha y las horas de juego.
func _build_slot_card(card: Button) -> void:
	var accent: Color = slot_accent_color

	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 8)
	card.add_child(m)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(h)

	var num := Label.new()
	num.custom_minimum_size = Vector2(56, 0)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.add_theme_font_size_override("font_size", font_size + 16)
	num.add_theme_color_override("font_color", accent)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(num)

	var divider := ColorRect.new()
	divider.color = Color(accent.r, accent.g, accent.b, 0.30)
	divider.custom_minimum_size = Vector2(2, 0)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(divider)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)

	var name_l := Label.new()
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.clip_text = true
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_l.add_theme_font_size_override("font_size", font_size + 2)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name_l)

	var info_l := Label.new()
	info_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_l.clip_text = true
	info_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_l.add_theme_font_size_override("font_size", maxi(font_size - 6, 12))
	info_l.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
	info_l.add_theme_constant_override("outline_size", 3)
	info_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(info_l)

	# El nombre se ilumina al pasar el ratón o enfocar la tarjeta
	var light := func(): name_l.add_theme_color_override("font_color", button_hover_font_color)
	var dim := func(): name_l.add_theme_color_override("font_color", font_color)
	card.mouse_entered.connect(light)
	card.focus_entered.connect(light)
	card.mouse_exited.connect(dim)
	card.focus_exited.connect(dim)

	slot_contents.append(m)
	slot_nums.append(num)
	slot_names.append(name_l)
	slot_infos.append(info_l)


func _build_slots_page(holder: Control) -> void:
	var p := _make_page(holder, "slots")
	slots_title = _make_heading("", p)
	for i in range(1, SaveManager.SLOT_COUNT + 1):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		p.add_child(row)
		slot_rows.append(row)

		var sb := _make_button("", _on_slot_pressed.bind(i), row, slot_button_size)
		_build_slot_card(sb)
		_apply_card_styles(sb, slot_accent_color)
		var rb := _make_icon_button(rename_tex, "✎", text_rename_tooltip, _on_rename_pressed.bind(i), row)
		var db := _make_icon_button(delete_tex, "X", text_delete_tooltip, _on_delete_pressed.bind(i), row)
		_apply_card_styles(rb, slot_accent_color)
		_apply_card_styles(db, Color(0.95, 0.30, 0.30))
		slot_buttons.append(sb)
		rename_buttons.append(rb)
		delete_buttons.append(db)
	_make_button(text_back, func(): _show_page("main"), p)


func _build_settings_page(holder: Control) -> void:
	var p := _make_page(holder, "settings")
	_make_heading(text_settings_title, p)

	var vol_label := Label.new()
	vol_label.text = text_volume
	vol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(vol_label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = SaveManager.settings["master_volume"]
	slider.custom_minimum_size = Vector2(320, 24)
	slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(v: float):
		SaveManager.settings["master_volume"] = v
		SaveManager.apply_settings())
	p.add_child(slider)

	var fs := CheckButton.new()
	fs.text = text_fullscreen
	fs.button_pressed = SaveManager.settings["fullscreen"]
	fs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fs.toggled.connect(func(on: bool):
		SaveManager.settings["fullscreen"] = on
		SaveManager.apply_settings())
	p.add_child(fs)

	_make_button(text_back, func():
		SaveManager.save_settings()
		_show_page("main"), p)


func _build_credits_page(holder: Control) -> void:
	var p := _make_page(holder, "credits")
	_make_heading(text_credits_title, p)

	# Los créditos van dentro de un área con scroll para que, aunque el
	# texto sea largo, el botón Volver siempre quede visible abajo.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(560, 200)
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.add_child(scroll)

	var txt := Label.new()
	txt.text = credits_text
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.custom_minimum_size = Vector2(540, 0)
	scroll.add_child(txt)

	_make_button(text_back, func(): _show_page("main"), p)


# =============================================================== NAVEGACIÓN

func _show_page(page_name: String) -> void:
	for key in pages.keys():
		pages[key].visible = (key == page_name)

	if page_name == "main":
		continue_btn.disabled = SaveManager.get_last_slot() == -1
		if continue_btn.disabled:
			pages["main"].get_child(1).grab_focus()
		else:
			continue_btn.grab_focus()
	else:
		for c in pages[page_name].find_children("*", "BaseButton", true, false):
			if not c.disabled and c.is_visible_in_tree():
				c.grab_focus()
				break


func _open_slots(mode: String) -> void:
	slots_mode = mode
	slots_title.text = text_slots_new_title if mode == "new" else text_slots_load_title
	for i in slot_buttons.size():
		var slot: int = i + 1
		var has: bool = SaveManager.has_save(slot)
		slot_nums[i].text = "%02d" % slot
		if has:
			# El resumen trae el nombre en la primera línea y los datos en la segunda
			var parts: PackedStringArray = SaveManager.get_slot_summary(slot).split("\n", true, 1)
			slot_names[i].text = parts[0]
			slot_infos[i].text = parts[1] if parts.size() > 1 else ""
		else:
			slot_names[i].text = text_slot_empty
			slot_infos[i].text = text_slot_empty_new if mode == "new" else text_slot_empty_load
		slot_buttons[i].disabled = (mode == "load" and not has)
		slot_contents[i].modulate.a = 0.4 if (mode == "load" and not has) else 1.0
		# Renombrar y eliminar solo aparecen en "Cargar" y si hay partida
		rename_buttons[i].visible = (mode == "load" and has)
		delete_buttons[i].visible = (mode == "load" and has)

		# Entrada escalonada de cada fila
		slot_rows[i].modulate.a = 0.0
		create_tween().tween_property(slot_rows[i], "modulate:a", 1.0, 0.35).set_delay(0.07 * i)
	_show_page("slots")


# ================================================================= ACCIONES

func _on_continue() -> void:
	var slot: int = SaveManager.get_last_slot()
	if slot != -1:
		_load_slot(slot)


func _on_slot_pressed(slot: int) -> void:
	if slots_mode == "load":
		_load_slot(slot)
	else:
		pending_slot = slot
		if SaveManager.has_save(slot):
			confirm.popup_centered()
		else:
			_ask_name_new(slot)


# ---- Nombre de la partida (nueva o renombrar)

func _ask_name_new(slot: int) -> void:
	pending_slot = slot
	name_action = "new"
	name_dialog.title = text_name_new_title
	name_edit.text = "%s %d" % [text_default_slot_name, slot]
	_popup_name_dialog()


func _on_rename_pressed(slot: int) -> void:
	pending_slot = slot
	name_action = "rename"
	name_dialog.title = text_name_rename_title
	name_edit.text = SaveManager.get_slot_name(slot)
	_popup_name_dialog()


func _popup_name_dialog() -> void:
	name_dialog.popup_centered(Vector2i(420, 120))
	name_edit.grab_focus()
	name_edit.select_all()


func _on_name_confirmed() -> void:
	var n: String = name_edit.text.strip_edges()
	if n == "":
		n = "%s %d" % [text_default_slot_name, pending_slot]
	if name_action == "new":
		_start_new_game(pending_slot, n)
	else:
		SaveManager.rename_slot(pending_slot, n)
		_open_slots(slots_mode)


# ---- Eliminar partida

func _on_delete_pressed(slot: int) -> void:
	pending_slot = slot
	delete_confirm.dialog_text = text_delete_message.replace("{name}", SaveManager.get_slot_name(slot))
	delete_confirm.popup_centered()


func _on_delete_confirmed() -> void:
	SaveManager.delete_slot(pending_slot)
	_open_slots(slots_mode)


# ---- Empezar / cargar

func _start_new_game(slot: int, save_name: String) -> void:
	if _leaving:
		return
	_current_slot = slot
	SaveManager.new_game(slot, save_name)
	_go_to_game(true)   # true = pasar por la cinemática


func _load_slot(slot: int) -> void:
	if _leaving:
		return
	_current_slot = slot
	if SaveManager.load_game(slot):
		_go_to_game()


# ============================================================ PANTALLA DE CARGA

func _grad_tex(colors: PackedColorArray, offsets: PackedFloat32Array, radial: bool, w: int, h: int) -> Texture2D:
	var g := Gradient.new()
	g.offsets = offsets
	g.colors = colors
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = w
	t.height = h
	if radial:
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
	else:
		t.fill_from = Vector2(0, 0)
		t.fill_to = Vector2(1, 0)
	return t


func _show_loading() -> void:
	if loading_layer != null:
		return
	var vp: Vector2 = get_viewport_rect().size
	var accent: Color = loading_accent_color
	var clear := Color(accent.r, accent.g, accent.b, 0.0)

	loading_layer = CanvasLayer.new()
	loading_layer.layer = 100
	add_child(loading_layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP  # bloquea clics al menú
	loading_layer.add_child(root)

	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# ---------- Oscurecer + viñeta
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, loading_dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.modulate.a = 0.0
	root.add_child(dim)
	tw.tween_property(dim, "modulate:a", 1.0, loading_fade_time)

	var vig := TextureRect.new()
	vig.texture = _grad_tex(
		PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.9)]),
		PackedFloat32Array([0.4, 1.0]), true, 256, 256)
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.modulate.a = 0.0
	root.add_child(vig)
	tw.tween_property(vig, "modulate:a", 1.0, loading_fade_time)

	# ---------- Brasas flotantes
	if loading_embers:
		var p := CPUParticles2D.new()
		p.texture = _grad_tex(
			PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)]),
			PackedFloat32Array([0.0, 1.0]), true, 16, 16)
		var ramp := Gradient.new()
		ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.75, 1.0])
		ramp.colors = PackedColorArray([clear, accent, accent, clear])
		p.color_ramp = ramp
		p.amount = 70
		p.lifetime = 6.0
		p.preprocess = 4.0
		p.position = Vector2(vp.x * 0.5, vp.y + 10)
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(vp.x * 0.5, 5)
		p.direction = Vector2(0, -1)
		p.spread = 18.0
		p.gravity = Vector2.ZERO
		p.initial_velocity_min = 40.0
		p.initial_velocity_max = 130.0
		p.scale_amount_min = 0.3
		p.scale_amount_max = 0.9
		root.add_child(p)

	# ---------- Barras de cine
	if loading_cinema_bars > 0.0:
		var h: float = loading_cinema_bars

		var top := ColorRect.new()
		top.color = Color.BLACK
		top.set_anchors_preset(Control.PRESET_TOP_WIDE)
		top.offset_top = -h
		top.offset_bottom = 0.0
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(top)
		var top_line := ColorRect.new()
		top_line.color = accent
		top_line.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		top_line.offset_top = -2.0
		top_line.offset_bottom = 0.0
		top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(top_line)
		tw.tween_property(top, "offset_top", 0.0, loading_fade_time)
		tw.tween_property(top, "offset_bottom", h, loading_fade_time)

		var bottom := ColorRect.new()
		bottom.color = Color.BLACK
		bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		bottom.offset_top = 0.0
		bottom.offset_bottom = h
		bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(bottom)
		var bottom_line := ColorRect.new()
		bottom_line.color = accent
		bottom_line.set_anchors_preset(Control.PRESET_TOP_WIDE)
		bottom_line.offset_top = 0.0
		bottom_line.offset_bottom = 2.0
		bottom_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bottom.add_child(bottom_line)
		tw.tween_property(bottom, "offset_top", -h, loading_fade_time)
		tw.tween_property(bottom, "offset_bottom", 0.0, loading_fade_time)

	# ---------- Contenido central
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.modulate.a = 0.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(box)
	tw.tween_property(box, "modulate:a", 1.0, loading_fade_time).set_delay(0.15)

	# Título con letras que se abren
	var fv := FontVariation.new()
	if loading_font != null:
		fv.base_font = loading_font
	elif font != null:
		fv.base_font = font
	else:
		fv.base_font = ThemeDB.fallback_font
	fv.spacing_glyph = 36

	var title := Label.new()
	title.text = text_loading
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", fv)
	title.add_theme_font_size_override("font_size", loading_font_size)
	title.add_theme_color_override("font_color", loading_font_color)
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color(accent.r, accent.g, accent.b, 0.35))
	box.add_child(title)
	tw.tween_property(fv, "spacing_glyph", 12, loading_fade_time * 2.0)

	# Brillo pulsante del título
	var pulse := create_tween().set_loops()
	pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(title, "self_modulate", Color(1.0, 0.9, 0.7, 0.8), 0.9)
	pulse.tween_property(title, "self_modulate", Color(1, 1, 1, 1), 0.9)

	# Línea ornamental
	var line := TextureRect.new()
	line.texture = _grad_tex(
		PackedColorArray([clear, accent, clear]),
		PackedFloat32Array([0.0, 0.5, 1.0]), false, 512, 4)
	line.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	line.stretch_mode = TextureRect.STRETCH_SCALE
	line.custom_minimum_size = Vector2(loading_bar_width + 120.0, 3)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(line)

	# Nombre de la partida
	if _current_slot != -1:
		var sub := Label.new()
		sub.text = text_loading_slot.replace("{name}", SaveManager.get_slot_name(_current_slot))
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_theme_font_size_override("font_size", loading_sub_font_size)
		sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
		if loading_font != null:
			sub.add_theme_font_override("font", loading_font)
		box.add_child(sub)

	# Barra con destello que recorre
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(loading_bar_width, 6)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.clip_contents = true
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(bar)

	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.12)
	track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(track)

	var glint_w: float = loading_bar_width * 0.4
	var glint := TextureRect.new()
	glint.texture = _grad_tex(
		PackedColorArray([clear, accent, clear]),
		PackedFloat32Array([0.0, 0.5, 1.0]), false, 128, 6)
	glint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glint.stretch_mode = TextureRect.STRETCH_SCALE
	glint.size = Vector2(glint_w, 6)
	glint.position = Vector2(-glint_w, 0)
	glint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(glint)

	var sweep := create_tween().set_loops()
	sweep.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sweep.tween_property(glint, "position:x", loading_bar_width, 1.1)
	sweep.tween_callback(func(): glint.position.x = -glint_w)


# ============================================================ CAMBIO DE ESCENA

func _go_to_game(play_intro: bool = false) -> void:
	if _leaving:
		return
	_leaving = true
	var t0: int = Time.get_ticks_msec()
	_show_loading()
	var target: String = game_scene
	var saved_scene: String = str(SaveManager.pending_load_data.get("scene", ""))

	if play_intro and intro_scene != "" and ResourceLoader.exists(intro_scene):
		target = intro_scene
	elif saved_scene != "" and ResourceLoader.exists(saved_scene):
		target = saved_scene

	await _music_fade_out()
	var elapsed: float = (Time.get_ticks_msec() - t0) / 1000.0
	if elapsed < loading_min_time:
		await get_tree().create_timer(loading_min_time - elapsed).timeout
	get_tree().change_scene_to_file(target)
