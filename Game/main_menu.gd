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

@export_group("Fondo - Luz del cursor")
## Oscurece el fondo y deja una zona iluminada alrededor del cursor.
@export var cursor_light_enabled: bool = true
## Qué tan oscuro queda el fondo lejos del cursor (0 = nada, 1 = negro total).
@export_range(0.0, 1.0) var light_dark_amount: float = 0.6
## Oscuridad que queda justo bajo el cursor (0 = totalmente iluminado).
@export_range(0.0, 1.0) var light_center_dark: float = 0.05
## Radio de la zona iluminada, en píxeles.
@export var light_radius: float = 420.0
## Color de la oscuridad (un azul muy oscuro combina mejor que negro puro).
@export var light_dark_color: Color = Color(0.02, 0.02, 0.07)
## Qué tan rápido sigue la luz al cursor (más alto = más pegada al mouse).
@export var light_follow_speed: float = 12.0

@export_group("Disposición del menú")
## true = logo y botones a la derecha (la ilustración queda a la izquierda).
@export var menu_on_right: bool = true
## Fracción del ancho de pantalla que ocupa la columna del menú (0.2 - 1.0).
@export_range(0.2, 1.0) var menu_area_width: float = 0.45
## Al entrar a un submenú (partidas, ajustes, créditos) la columna se ensancha
## hacia la ilustración para que todo quepa. Fracción del ancho de pantalla.
@export_range(0.3, 1.0) var submenu_area_width: float = 0.7
## Al entrar a un submenú el logo se encoge a esta fracción de su tamaño.
@export_range(0.2, 1.0) var submenu_logo_scale: float = 0.45
## Duración de la animación al cambiar de pantalla (0 = instantáneo).
@export var submenu_anim_time: float = 0.35

@export_group("Título")
## Si pones una imagen (logo), se muestra en lugar del texto.
@export var title_logo: Texture2D
## Tamaño del logo. (0, 0) = tamaño original de la imagen.
@export var title_logo_size: Vector2 = Vector2.ZERO
## Recorta automáticamente el espacio transparente alrededor del logo, para que
## el tamaño de arriba sea el del dibujo real y no el de la imagen completa.
@export var title_logo_trim: bool = true
@export var title_font: Font
@export var title_font_size: int = 64
@export var title_color: Color = Color.WHITE
## Separación entre el logo y los botones.
@export var title_spacing: int = 8

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

@export_group("Partidas guardadas - Imágenes")
## Imagen de fondo de cada tarjeta de partida (proporción 20:3, por ejemplo 1120x168).
## Vacío = se usa el estilo de siempre (panel oscuro con borde de color).
@export var slot_normal_texture: Texture2D
## Imagen de la tarjeta al seleccionarla; se funde encima de la normal. Opcional.
@export var slot_hover_texture: Texture2D
## Fondo de los botones de editar y borrar (cuadrado). Vacío = estilo de siempre.
@export var slot_icon_normal_texture: Texture2D
## Fondo de esos mismos botones al seleccionarlos. Opcional.
@export var slot_icon_hover_texture: Texture2D
## Cuánto crece la tarjeta al seleccionarla (1.0 = nada).
@export_range(1.0, 1.2) var slot_hover_scale: float = 1.03
## Color del texto y de los iconos al seleccionar (solo si hay imagen de hover).
## Con una imagen de hover clara, el negro se lee mejor.
@export var slot_hover_text_color: Color = Color.BLACK

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
## Sonido SOLO para los botones que dicen "Volver" (text_back). Vacío = usa el click normal.
@export var back_sound: AudioStream
## Volumen de cada efecto en decibeles (0 = original, negativo = más bajo, -6 ≈ la mitad).
@export_range(-60.0, 6.0, 0.5, "suffix:dB") var click_volume_db: float = 0.0
@export_range(-60.0, 6.0, 0.5, "suffix:dB") var hover_volume_db: float = 0.0
@export_range(-60.0, 6.0, 0.5, "suffix:dB") var back_volume_db: float = 0.0

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

const LIGHT_SHADER := """
shader_type canvas_item;

uniform vec2 light_pos = vec2(0.0);
uniform vec2 rect_size = vec2(1920.0, 1080.0);
uniform float radius = 420.0;
uniform float dark_alpha = 0.6;
uniform float center_alpha = 0.05;
uniform vec4 dark_color : source_color = vec4(0.02, 0.02, 0.07, 1.0);

void fragment() {
	float d = distance(UV * rect_size, light_pos);
	float t = smoothstep(0.0, radius, d);
	t = t * t * (3.0 - 2.0 * t);
	COLOR = vec4(dark_color.rgb, mix(center_alpha, dark_alpha, t));
}
"""

const HOLDER_SIZE := Vector2(800, 440)

var _fx_normal_texs: Array[Texture2D] = []
var _fx_hover_texs: Array[Texture2D] = []
var _fx_hover_frames: Array[Texture2D] = []
var _fx_hover_fps: float = 8.0
var _fx_counter: int = 0
var _fx_rng := RandomNumberGenerator.new()
var _menu_column: Control
var _logo_node: Control
var _holder: Control
var _logo_full_size: Vector2 = Vector2.ZERO
var _layout_tween: Tween
var _layout_started: bool = false
var _light_overlay: ColorRect
var _light_mat: ShaderMaterial
var _light_pos: Vector2 = Vector2.ZERO
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
var back_player: AudioStreamPlayer
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
	_fx_rng.seed = button_variation_seed
	_build_theme()
	_build_audio()
	_build_ui()
	_show_page("main")


func _process(delta: float) -> void:
	if _light_mat == null:
		return
	# La luz sigue al cursor con un pequeño suavizado
	var target: Vector2 = _light_overlay.get_local_mouse_position()
	_light_pos = _light_pos.lerp(target, 1.0 - exp(-light_follow_speed * delta))
	_light_mat.set_shader_parameter("light_pos", _light_pos)
	_light_mat.set_shader_parameter("rect_size", _light_overlay.size)


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

	var n_tex: Texture2D = _prep_button_tex(button_normal_texture)
	var h_tex: Texture2D = _prep_button_tex(button_hover_texture)
	var p_tex: Texture2D = _prep_button_tex(button_pressed_texture)
	var d_tex: Texture2D = _prep_button_tex(button_disabled_texture)

	var normal_box: StyleBox = _make_box(n_tex, button_normal_color)
	var hover_box: StyleBox
	if button_hover_overlay and n_tex != null and h_tex != null:
		# El contorno de hover va como capa aparte (con fundido); el estilo
		# de fondo se queda con la imagen normal.
		hover_box = normal_box
	else:
		hover_box = _make_box(h_tex, button_hover_color)
	var pressed_box: StyleBox = normal_box if (p_tex == null and n_tex != null) else _make_box(p_tex, button_pressed_color)
	var disabled_box: StyleBox = normal_box if (d_tex == null and n_tex != null) else _make_box(d_tex, button_disabled_color)

	# Imágenes por variante para los botones con efecto (la 0 es la principal)
	_fx_normal_texs.clear()
	_fx_hover_texs.clear()
	if n_tex != null:
		_fx_normal_texs.append(n_tex)
		_fx_hover_texs.append(h_tex)
		for i in button_normal_variants.size():
			var vn: Texture2D = _prep_button_tex(button_normal_variants[i])
			if vn == null:
				continue
			var vh: Texture2D = h_tex
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

	t.set_stylebox("normal", "Button", normal_box)
	t.set_stylebox("hover", "Button", hover_box)
	t.set_stylebox("focus", "Button", hover_box)
	t.set_stylebox("pressed", "Button", pressed_box)
	t.set_stylebox("disabled", "Button", disabled_box)
	theme = t


# ================================================================ AUDIO

func _build_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = music_bus
	add_child(music_player)
	_music_start()

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


func _play_back() -> void:
	if back_sound != null:
		back_player.play()
	else:
		_play_click()


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


## Capa oscura con un "agujero" de luz que sigue al cursor. Se dibuja encima
## del fondo (splash) pero detrás del menú.
func _build_light_overlay() -> void:
	if not cursor_light_enabled:
		return
	var shader := Shader.new()
	shader.code = LIGHT_SHADER
	_light_mat = ShaderMaterial.new()
	_light_mat.shader = shader
	_light_mat.set_shader_parameter("radius", light_radius)
	_light_mat.set_shader_parameter("dark_alpha", light_dark_amount)
	_light_mat.set_shader_parameter("center_alpha", light_center_dark)
	_light_mat.set_shader_parameter("dark_color", light_dark_color)

	_light_overlay = ColorRect.new()
	_light_overlay.color = Color.WHITE
	_light_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_light_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_light_overlay.material = _light_mat
	add_child(_light_overlay)
	_light_pos = _light_overlay.get_local_mouse_position()


## Coloca la columna del menú (logo + botones) a la derecha o a la izquierda.
func _place_menu_column(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w: float = clampf(menu_area_width, 0.2, 1.0)
	if menu_on_right:
		c.anchor_left = 1.0 - w
		c.anchor_right = 1.0
	else:
		c.anchor_left = 0.0
		c.anchor_right = w
	c.offset_left = 0.0
	c.offset_right = 0.0
	c.offset_top = 0.0
	c.offset_bottom = 0.0


func _build_ui() -> void:
	_build_background()
	_build_light_overlay()

	var center := CenterContainer.new()
	_place_menu_column(center)
	add_child(center)
	_menu_column = center

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", title_spacing)
	center.add_child(root)

	_logo_node = _build_title()
	_logo_full_size = _logo_node.custom_minimum_size
	root.add_child(_logo_node)

	var holder := Control.new()
	holder.custom_minimum_size = HOLDER_SIZE
	root.add_child(holder)
	_holder = holder

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


func _build_title() -> Control:
	if title_logo != null:
		var tex: Texture2D = _trim_texture(title_logo) if title_logo_trim else title_logo
		var src: Vector2 = tex.get_size()
		var logo := TextureRect.new()
		logo.texture = tex
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# title_logo_size es una caja máxima: el logo se ajusta a ella sin deformarse
		var f: float
		if title_logo_size == Vector2.ZERO:
			f = minf(1.0, 700.0 / src.x)
		else:
			f = minf(title_logo_size.x / src.x, title_logo_size.y / src.y)
		logo.custom_minimum_size = (src * f).round()
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
	# Los botones que dicen "Volver" usan su propio sonido; los demas, el click normal.
	b.pressed.connect(_play_back if text == text_back else _play_click)
	b.pressed.connect(callback)
	if size == Vector2.ZERO:
		# Botones normales del menú: llevan efecto hover. Al pasar el mouse
		# toman el foco, así que el sonido de hover sale del foco.
		_fx_setup(b)
	else:
		b.mouse_entered.connect(_play_hover)
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
	var c: Color = button_font_color.lerp(button_hover_text_color, p)
	for key in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(key, c)
	var o: int = int(roundf(lerpf(float(text_outline_size), float(button_hover_text_outline), p)))
	b.add_theme_constant_override("outline_size", o)
	if b.has_meta("fx_overlay"):
		(b.get_meta("fx_overlay") as Control).modulate.a = p
	if b.has_meta("fx_base") and not button_hover_overlay:
		(b.get_meta("fx_base") as Control).modulate.a = 1.0 - p


# ===================================================== TARJETAS CON IMAGEN

## Convierte un botón (tarjeta o icono) en uno con imágenes: fondo normal y,
## opcionalmente, un contorno de hover que se funde encima. Las imágenes quedan
## detrás del contenido. labels = [número, nombre, datos] para las tarjetas.
func _image_card_setup(b: Button, n_tex: Texture2D, h_tex: Texture2D, labels: Array) -> void:
	for state in ["normal", "hover", "focus", "pressed", "disabled"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.resized.connect(func(): b.pivot_offset = b.size * 0.5)

	var base := _fx_layer(n_tex, 0.0, false)
	b.add_child(base)
	b.set_meta("fx_base", base)
	if h_tex != null:
		var ov := _fx_layer(h_tex, button_hover_outline_grow, false)
		ov.modulate.a = 0.0
		b.add_child(ov)
		b.set_meta("fx_overlay", ov)
	b.set_meta("card_labels", labels)
	b.set_meta("card_recolor", h_tex != null)

	# El mouse toma el foco (como en el menú principal); el sonido sale del foco
	if b.mouse_entered.is_connected(_play_hover):
		b.mouse_entered.disconnect(_play_hover)
	b.mouse_entered.connect(func():
		if not b.disabled:
			b.grab_focus())
	b.focus_entered.connect(_card_changed.bind(b))
	b.focus_exited.connect(_card_changed.bind(b))


func _card_changed(b: Button) -> void:
	_card_apply.call_deferred(b)


func _card_apply(b: Button) -> void:
	if not is_instance_valid(b):
		return
	var active: bool = b.has_focus() and not b.disabled
	b.z_index = 1 if active else 0
	_fx_tween(b, slot_hover_scale if active else 1.0, 1.0 if active else 0.0, _card_step)


## p = 0 (reposo) a 1 (seleccionada): fundido del contorno y color del texto.
func _card_step(p: float, b: Button) -> void:
	if not is_instance_valid(b):
		return
	b.set_meta("fx_p", p)
	if b.has_meta("fx_overlay"):
		(b.get_meta("fx_overlay") as Control).modulate.a = p
	if not b.get_meta("card_recolor", false):
		return
	var hc: Color = slot_hover_text_color

	# Iconos de los botones de editar / borrar
	var ic: Color = Color.WHITE.lerp(hc, p)
	for key in ["icon_normal_color", "icon_hover_color", "icon_focus_color", "icon_pressed_color", "icon_hover_pressed_color"]:
		b.add_theme_color_override(key, ic)

	# Textos de la tarjeta
	var labels: Array = b.get_meta("card_labels", [])
	if labels.size() != 3:
		return
	var o_main: int = int(roundf(lerpf(float(text_outline_size), float(button_hover_text_outline), p)))
	var o_info: int = int(roundf(lerpf(3.0, float(button_hover_text_outline), p)))
	var shadow: Color = text_shadow_color
	shadow.a = text_shadow_color.a * (1.0 - p)
	var colors: Array[Color] = [
		slot_accent_color.lerp(hc, p),
		font_color.lerp(hc, p),
		Color(1, 1, 1, 0.72).lerp(Color(hc.r, hc.g, hc.b, 0.85), p),
	]
	var outlines: Array[int] = [o_main, o_main, o_info]
	for i in 3:
		var l: Label = labels[i]
		l.add_theme_color_override("font_color", colors[i])
		l.add_theme_constant_override("outline_size", outlines[i])
		l.add_theme_color_override("font_shadow_color", shadow)


func _card_disabled_look(b: Button) -> void:
	if b.has_meta("fx_base"):
		(b.get_meta("fx_base") as Control).modulate = Color(1, 1, 1, 0.45) if b.disabled else Color.WHITE


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
	p.alignment = BoxContainer.ALIGNMENT_BEGIN
	continue_btn = _make_button(text_continue, _on_continue, p)
	_make_button(text_new_game, func(): _open_slots("new"), p)
	_make_button(text_load, func(): _open_slots("load"), p)
	_make_button(text_settings, func(): _show_page("settings"), p)
	_make_button(text_credits, func(): _show_page("credits"), p)
	_make_button(text_quit, func(): get_tree().quit(), p)
	_register_fx_group(p.get_children())


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
	if slot_normal_texture == null:
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
	# Imágenes opcionales; si no hay, las tarjetas conservan su estilo de siempre
	var card_n: Texture2D = _prep_button_tex(slot_normal_texture)
	var card_h: Texture2D = _prep_button_tex(slot_hover_texture)
	var icon_n: Texture2D = _prep_button_tex(slot_icon_normal_texture)
	var icon_h: Texture2D = _prep_button_tex(slot_icon_hover_texture)
	for i in range(1, SaveManager.SLOT_COUNT + 1):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		p.add_child(row)
		slot_rows.append(row)

		var sb := _make_button("", _on_slot_pressed.bind(i), row, slot_button_size)
		_build_slot_card(sb)
		if card_n != null:
			_image_card_setup(sb, card_n, card_h, [slot_nums[-1], slot_names[-1], slot_infos[-1]])
		else:
			_apply_card_styles(sb, slot_accent_color)
		var rb := _make_icon_button(rename_tex, "✎", text_rename_tooltip, _on_rename_pressed.bind(i), row)
		var db := _make_icon_button(delete_tex, "X", text_delete_tooltip, _on_delete_pressed.bind(i), row)
		if icon_n != null:
			_image_card_setup(rb, icon_n, icon_h, [])
			_image_card_setup(db, icon_n, icon_h, [])
		else:
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


# ================================================================= LAYOUT

## Borde de la columna que se mueve: el izquierdo si el menú está a la derecha,
## el derecho si está a la izquierda.
func _column_edge(submenu: bool) -> float:
	var w: float = clampf(submenu_area_width if submenu else menu_area_width, 0.2, 1.0)
	return (1.0 - w) if menu_on_right else w


func _set_column_edge(v: float) -> void:
	if menu_on_right:
		_menu_column.anchor_left = v
	else:
		_menu_column.anchor_right = v
	_menu_column.offset_left = 0.0
	_menu_column.offset_right = 0.0


## Ajusta logo, columna y alto del contenedor según la pantalla mostrada:
## en el menú principal todo va grande; en un submenú el logo se encoge y la
## columna se ensancha hacia la izquierda para que el contenido quepa completo.
func _update_layout(page_name: String, animate: bool) -> void:
	if _menu_column == null or _holder == null or not pages.has(page_name):
		return
	var sub: bool = page_name != "main"
	var page_min: Vector2 = (pages[page_name] as Control).get_combined_minimum_size()

	var logo_target: Vector2 = _logo_full_size
	if sub and _logo_node is TextureRect:
		logo_target = (_logo_full_size * clampf(submenu_logo_scale, 0.2, 1.0)).round()

	var holder_h: float = page_min.y
	if sub:
		var available: float = get_viewport_rect().size.y - logo_target.y - title_spacing - 24.0
		holder_h = maxf(page_min.y, minf(HOLDER_SIZE.y, available))
	var holder_target := Vector2(HOLDER_SIZE.x, holder_h)
	var edge_target: float = _column_edge(sub)

	if _layout_tween != null and _layout_tween.is_valid():
		_layout_tween.kill()

	if not animate or submenu_anim_time <= 0.0:
		if _logo_node is TextureRect:
			_logo_node.custom_minimum_size = logo_target
		_holder.custom_minimum_size = holder_target
		_set_column_edge(edge_target)
		return

	var edge_now: float = _menu_column.anchor_left if menu_on_right else _menu_column.anchor_right
	_layout_tween = create_tween().set_parallel(true)
	_layout_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _logo_node is TextureRect:
		_layout_tween.tween_property(_logo_node, "custom_minimum_size", logo_target, submenu_anim_time)
	_layout_tween.tween_property(_holder, "custom_minimum_size", holder_target, submenu_anim_time)
	_layout_tween.tween_method(_set_column_edge, edge_now, edge_target, submenu_anim_time)


# =============================================================== NAVEGACIÓN

func _show_page(page_name: String) -> void:
	for key in pages.keys():
		pages[key].visible = (key == page_name)
	_update_layout(page_name, _layout_started)
	_layout_started = true

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
		_card_disabled_look(slot_buttons[i])
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
