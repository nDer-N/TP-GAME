extends Area2D

@export_multiline var texto: String = "WASD para moverte"
## Animación del diagrama para el modo de una sola página (nombre dentro del SpriteFrames de $Panel/Diagrama).
@export var animacion: StringName = &""
@export_multiline var paginas: Array[String] = []   # si hay 2+ se activan las flechas
## Animación de cada página (mismo índice que "paginas"). Vacío = página sin diagrama.
@export var animaciones: Array[StringName] = []
@export var una_sola_vez: bool = true
@export var ancho_panel: float = 420.0
@export var padding: float = 20.0
@export var escala_panel: float = 1.5
@export var flicker: bool = true
@export var tecla_repetir: Key = KEY_E
@export var texto_hint: String = "[E] Ver tutorial"
@export var hint_offset: Vector2 = Vector2(0, -80)

@export_group("Diagrama")
## Alto máximo del diagrama dentro del panel (antes de aplicar escala_panel).
@export var alto_diagrama_max: float = 180.0
## Espacio entre el diagrama y el texto cuando una página tiene ambos.
@export var separacion_diagrama_texto: float = 12.0
## Ignora el margen transparente de los frames al calcular tamaño y posición.
@export var recortar_transparencia: bool = true

# teclas para cambiar de página (configurables desde el Inspector)
@export var tecla_pagina_izq: Key = KEY_A
@export var tecla_pagina_der: Key = KEY_D

@onready var panel: Node2D = $Panel
@onready var fondo: ColorRect = $Panel/Fondo
@onready var label: Label = $Panel/Label
@onready var linea: ColorRect = $Panel/Linea
@onready var diagrama: AnimatedSprite2D = $Panel/Diagrama

# Cache compartido entre todas las instancias: área visible de cada animación.
static var _cache_info: Dictionary = {}

var canvas: CanvasLayer
var dim: ColorRect
var hint: Label
var abierto := false
var ya_mostrado := false
var jugador_dentro := false
var abierto_ms := 0
var tween: Tween
var flicker_tween: Tween

var lista_paginas: Array[String] = []
var lista_animaciones: Array[StringName] = []
var pagina_actual := 0
var flecha_izq: Label
var flecha_der: Label
var indicador: Label

# layout medido en _acomodar()
var layout_listo := false
var alturas_texto: Array[float] = []
var info_paginas: Array[Dictionary] = []
var alto_contenido := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# el script calcula la posición asumiendo el sprite centrado
	diagrama.centered = true
	diagrama.offset = Vector2.ZERO

	_armar_paginas()

	canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	dim = ColorRect.new()
	dim.color = Color(0, 0.03, 0.08, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.modulate.a = 0.0
	dim.visible = false
	canvas.add_child(dim)

	panel.reparent(canvas, false)
	panel.modulate.a = 0.0
	panel.visible = false

	_crear_hint()
	_crear_flechas()
	_acomodar()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# Combina textos y animaciones en listas del mismo largo.
func _armar_paginas() -> void:
	lista_paginas.clear()
	lista_animaciones.clear()

	var n := maxi(paginas.size(), animaciones.size())
	if n == 0:
		# modo simple: un solo texto y (opcionalmente) una animación
		lista_paginas.append(texto)
		lista_animaciones.append(animacion)
		return

	for i in n:
		lista_paginas.append(paginas[i] if i < paginas.size() else "")
		lista_animaciones.append(animaciones[i] if i < animaciones.size() else &"")

func _crear_hint() -> void:
	hint = Label.new()
	hint.text = texto_hint
	hint.add_theme_font_override("font", label.get_theme_font("font"))
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("aaffff"))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.9, 1.0, 0.15)
	sb.border_color = Color(0.3, 1, 1, 0.9)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(8)
	hint.add_theme_stylebox_override("normal", sb)
	hint.visible = false
	add_child(hint)

func _nuevo_label_ui(tam: int) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", label.get_theme_font("font"))
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", Color("aaffff"))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(l)
	return l

func _crear_flechas() -> void:
	flecha_izq = _nuevo_label_ui(34)
	flecha_izq.text = "<"
	flecha_der = _nuevo_label_ui(34)
	flecha_der.text = ">"
	indicador = _nuevo_label_ui(20)
	_mostrar_pagina(0)

func _es_multipagina() -> bool:
	return lista_paginas.size() > 1

func _mostrar_pagina(i: int) -> void:
	pagina_actual = clampi(i, 0, lista_paginas.size() - 1)
	label.text = lista_paginas[pagina_actual]

	# reproduce la animación de esta página desde el principio
	var anim := lista_animaciones[pagina_actual]
	if diagrama.sprite_frames != null and diagrama.sprite_frames.has_animation(anim):
		diagrama.play(anim)
		diagrama.frame = 0
		diagrama.frame_progress = 0.0
	else:
		diagrama.stop()

	var multi := _es_multipagina()
	flecha_izq.visible = multi and pagina_actual > 0
	flecha_der.visible = multi and pagina_actual < lista_paginas.size() - 1
	indicador.visible = multi
	indicador.text = "%d/%d" % [pagina_actual + 1, lista_paginas.size()]
	_colocar_contenido()

func _cambiar_pagina(dir: int) -> void:
	var nueva := pagina_actual + dir
	if nueva < 0 or nueva >= lista_paginas.size():
		return
	_mostrar_pagina(nueva)

# Área visible (unión de todos los frames) y tamaño de frame de una animación.
func _info_animacion(anim: StringName) -> Dictionary:
	var frames := diagrama.sprite_frames
	var key := "%d|%s|%s" % [frames.get_instance_id(), anim, recortar_transparencia]
	if _cache_info.has(key):
		return _cache_info[key]

	var tam_frame := Vector2.ZERO
	var union := Rect2i()
	var hay_union := false

	for i in frames.get_frame_count(anim):
		var tex := frames.get_frame_texture(anim, i)
		if tex == null:
			continue
		if tam_frame == Vector2.ZERO:
			tam_frame = tex.get_size()
		if not recortar_transparencia:
			break
		var img := tex.get_image()
		if img == null:
			continue
		var r := img.get_used_rect()
		if r.size == Vector2i.ZERO:
			continue
		union = r if not hay_union else union.merge(r)
		hay_union = true

	var rect := Rect2(Vector2.ZERO, tam_frame)
	if recortar_transparencia and hay_union:
		rect = Rect2(union)

	var info := {"rect": rect, "frame": tam_frame}
	_cache_info[key] = info
	return info

# Mide cómo se verá el diagrama de una página: tamaño final, escala y área visible.
func _medir_diagrama(anim: StringName, ancho_max: float) -> Dictionary:
	var vacio := {"tam": Vector2.ZERO, "escala": 1.0, "rect": Rect2(), "frame": Vector2.ZERO}
	if anim == &"" or diagrama.sprite_frames == null:
		return vacio
	if not diagrama.sprite_frames.has_animation(anim):
		push_warning("HoloTutorial: no existe la animación '%s' en $Panel/Diagrama." % anim)
		return vacio

	var info := _info_animacion(anim)
	var rect: Rect2 = info["rect"]
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return vacio

	# cabe en el ancho útil y en alto_diagrama_max, sin agrandarse
	var s := minf(minf(ancho_max / rect.size.x, alto_diagrama_max / rect.size.y), 1.0)
	return {"tam": (rect.size * s).round(), "escala": s, "rect": rect, "frame": info["frame"]}

func _acomodar() -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ancho_texto := ancho_panel - padding * 2.0
	label.size = Vector2(ancho_texto, 0)

	alturas_texto.clear()
	info_paginas.clear()
	alto_contenido = 0.0

	# medimos TODAS las páginas (texto + diagrama) y usamos la más alta
	for i in lista_paginas.size():
		var h_texto := 0.0
		if lista_paginas[i] != "":
			label.text = lista_paginas[i]
			label.size = Vector2(ancho_texto, 0)
			await get_tree().process_frame
			h_texto = maxf(label.size.y, label.get_minimum_size().y)
		alturas_texto.append(h_texto)

		var info := _medir_diagrama(lista_animaciones[i], ancho_texto)
		info_paginas.append(info)
		var tam_d: Vector2 = info["tam"]

		var h := h_texto + tam_d.y
		if h_texto > 0.0 and tam_d.y > 0.0:
			h += separacion_diagrama_texto
		alto_contenido = maxf(alto_contenido, h)

	var extra := 26.0 if _es_multipagina() else 0.0   # espacio para el "1/3"
	var alto := maxf(alto_contenido + padding * 2.0 + extra, 100.0)

	fondo.size = Vector2(ancho_panel, alto)
	fondo.position = -fondo.size / 2.0
	linea.size = Vector2(ancho_panel, 2)
	linea.position = fondo.position

	# posición de flechas e indicador
	var centro_y := fondo.position.y + (alto - extra) / 2.0
	flecha_izq.size = Vector2(padding, 40)
	flecha_izq.position = Vector2(fondo.position.x, centro_y - 20)
	flecha_der.size = Vector2(padding, 40)
	flecha_der.position = Vector2(fondo.position.x + ancho_panel - padding, centro_y - 20)
	indicador.size = Vector2(ancho_panel, 24)
	indicador.position = Vector2(fondo.position.x, fondo.position.y + alto - 28)

	layout_listo = true
	_mostrar_pagina(0)
	hint.position = hint_offset - hint.size / 2.0

# Coloca diagrama (arriba) y texto (abajo) de la página actual, centrados en la zona de contenido.
func _colocar_contenido() -> void:
	if not layout_listo:
		return

	var ancho_texto := ancho_panel - padding * 2.0
	var h_texto: float = alturas_texto[pagina_actual]
	var info: Dictionary = info_paginas[pagina_actual]
	var tam_d: Vector2 = info["tam"]
	var sep := separacion_diagrama_texto if (h_texto > 0.0 and tam_d.y > 0.0) else 0.0
	var h_bloque := tam_d.y + sep + h_texto

	var y := fondo.position.y + padding + (alto_contenido - h_bloque) / 2.0

	diagrama.visible = tam_d.y > 0.0
	if diagrama.visible:
		var s: float = info["escala"]
		var rect: Rect2 = info["rect"]
		var tam_frame: Vector2 = info["frame"]
		# centramos el área VISIBLE del dibujo (no el frame completo) en su espacio
		var centro_destino := Vector2(0.0, y + tam_d.y / 2.0)
		diagrama.scale = Vector2(s, s)
		diagrama.position = centro_destino - (rect.get_center() - tam_frame / 2.0) * s
	y += tam_d.y + sep

	label.visible = h_texto > 0.0
	label.size = Vector2(ancho_texto, h_texto)
	label.position = Vector2(fondo.position.x + padding, y)

func _es_jugador(body: Node) -> bool:
	if body.is_in_group("player"):
		return true
	var padre := body.get_parent()
	return padre != null and padre.is_in_group("player")

func _on_body_entered(body: Node) -> void:
	if not _es_jugador(body):
		return
	jugador_dentro = true
	if una_sola_vez and ya_mostrado:
		hint.visible = not abierto
		return
	abrir.call_deferred()

func _on_body_exited(body: Node) -> void:
	if not _es_jugador(body):
		return
	jugador_dentro = false
	hint.visible = false

func _input(event: InputEvent) -> void:
	if abierto:
		if Time.get_ticks_msec() - abierto_ms < 400:
			return
		# las teclas de página cambian de página (solo si hay más de una)
		if _es_multipagina():
			var dir := _dir_pagina(event)
			if dir != 0:
				_cambiar_pagina(dir)
				get_viewport().set_input_as_handled()
				return
		if _es_movimiento(event):
			cerrar()
	elif jugador_dentro and ya_mostrado:
		if event is InputEventKey and event.pressed and not event.echo \
				and event.physical_keycode == tecla_repetir:
			abrir()

# devuelve -1, 1 o 0
func _dir_pagina(event: InputEvent) -> int:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == tecla_pagina_izq:
			return -1
		if event.physical_keycode == tecla_pagina_der:
			return 1
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_DPAD_LEFT:
			return -1
		if event.button_index == JOY_BUTTON_DPAD_RIGHT:
			return 1
	return 0

func _es_movimiento(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventJoypadMotion:
		return absf(event.axis_value) > 0.5
	return false

func abrir() -> void:
	if abierto:
		return
	abierto = true
	ya_mostrado = true
	hint.visible = false
	abierto_ms = Time.get_ticks_msec()
	get_tree().paused = true

	_mostrar_pagina(0)   # siempre empieza en la primera página

	panel.position = get_viewport().get_visible_rect().size / 2.0
	panel.visible = true
	dim.visible = true
	panel.scale = Vector2(escala_panel, 0.0)

	if tween: tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(dim, "modulate:a", 1.0, 0.25)
	tween.tween_property(panel, "modulate:a", 0.95, 0.25)
	tween.tween_property(panel, "scale", Vector2(escala_panel, escala_panel), 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if flicker:
		_iniciar_flicker()

func cerrar() -> void:
	if not abierto:
		return
	abierto = false
	get_tree().paused = false
	if flicker_tween: flicker_tween.kill()
	if tween: tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(dim, "modulate:a", 0.0, 0.25)
	tween.tween_property(panel, "modulate:a", 0.0, 0.25)
	tween.tween_property(panel, "scale", Vector2(escala_panel, 0.0), 0.25)
	tween.chain().tween_callback(func():
		panel.visible = false
		dim.visible = false)
	hint.visible = jugador_dentro

func _iniciar_flicker() -> void:
	if flicker_tween: flicker_tween.kill()
	flicker_tween = create_tween().set_loops()
	flicker_tween.tween_interval(0.3)
	flicker_tween.tween_property(panel, "modulate:a", 0.7, 0.08)
	flicker_tween.tween_property(panel, "modulate:a", 0.95, 0.12)
	flicker_tween.tween_interval(randf_range(0.5, 1.5))
