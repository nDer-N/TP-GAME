extends Area2D

@export_multiline var texto: String = "WASD para moverte"
@export_multiline var paginas: Array[String] = []   # NUEVO: si hay 2+ se activan las flechas
@export var una_sola_vez: bool = true
@export var ancho_panel: float = 420.0
@export var padding: float = 20.0
@export var escala_panel: float = 1.5
@export var flicker: bool = true
@export var tecla_repetir: Key = KEY_E
@export var texto_hint: String = "[E] Ver tutorial"
@export var hint_offset: Vector2 = Vector2(0, -80)

@onready var panel: Node2D = $Panel
@onready var fondo: ColorRect = $Panel/Fondo
@onready var label: Label = $Panel/Label
@onready var linea: ColorRect = $Panel/Linea

var canvas: CanvasLayer
var dim: ColorRect
var hint: Label
var abierto := false
var ya_mostrado := false
var jugador_dentro := false
var abierto_ms := 0
var tween: Tween
var flicker_tween: Tween

# NUEVO
var lista_paginas: Array[String] = []
var pagina_actual := 0
var flecha_izq: Label
var flecha_der: Label
var indicador: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# NUEVO: si no hay páginas, usa el texto simple como única página
	if paginas.is_empty():
		lista_paginas = [texto]
	else:
		lista_paginas = paginas.duplicate()

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
	_crear_flechas()   # NUEVO
	_acomodar()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

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

# NUEVO
func _nuevo_label_ui(tam: int) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", label.get_theme_font("font"))
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", Color("aaffff"))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(l)
	return l

# NUEVO
func _crear_flechas() -> void:
	flecha_izq = _nuevo_label_ui(34)
	flecha_izq.text = "<"
	flecha_der = _nuevo_label_ui(34)
	flecha_der.text = ">"
	indicador = _nuevo_label_ui(20)
	_mostrar_pagina(0)

# NUEVO
func _es_multipagina() -> bool:
	return lista_paginas.size() > 1

# NUEVO
func _mostrar_pagina(i: int) -> void:
	pagina_actual = clampi(i, 0, lista_paginas.size() - 1)
	label.text = lista_paginas[pagina_actual]
	var multi := _es_multipagina()
	flecha_izq.visible = multi and pagina_actual > 0
	flecha_der.visible = multi and pagina_actual < lista_paginas.size() - 1
	indicador.visible = multi
	indicador.text = "%d/%d" % [pagina_actual + 1, lista_paginas.size()]

# NUEVO
func _cambiar_pagina(dir: int) -> void:
	var nueva := pagina_actual + dir
	if nueva < 0 or nueva >= lista_paginas.size():
		return
	_mostrar_pagina(nueva)

func _acomodar() -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var ancho_texto := ancho_panel - padding * 2.0
	label.size = Vector2(ancho_texto, 0)

	# NUEVO: medimos TODAS las páginas y usamos la más alta
	var alto_texto := 0.0
	for i in lista_paginas.size():
		label.text = lista_paginas[i]
		label.size = Vector2(ancho_texto, 0)
		await get_tree().process_frame
		alto_texto = maxf(alto_texto, maxf(label.size.y, label.get_minimum_size().y))

	var extra := 26.0 if _es_multipagina() else 0.0   # espacio para el "1/3"
	var alto := maxf(alto_texto + padding * 2.0 + extra, 100.0)

	fondo.size = Vector2(ancho_panel, alto)
	fondo.position = -fondo.size / 2.0
	linea.size = Vector2(ancho_panel, 2)
	linea.position = fondo.position
	label.size = Vector2(ancho_texto, alto - padding * 2.0 - extra)
	label.position = fondo.position + Vector2(padding, padding)

	# NUEVO: posición de flechas e indicador
	var centro_y := fondo.position.y + (alto - extra) / 2.0
	flecha_izq.size = Vector2(padding, 40)
	flecha_izq.position = Vector2(fondo.position.x, centro_y - 20)
	flecha_der.size = Vector2(padding, 40)
	flecha_der.position = Vector2(fondo.position.x + ancho_panel - padding, centro_y - 20)
	indicador.size = Vector2(ancho_panel, 24)
	indicador.position = Vector2(fondo.position.x, fondo.position.y + alto - 28)

	_mostrar_pagina(0)
	hint.position = hint_offset - hint.size / 2.0

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
		# NUEVO: flechas cambian de página (solo si hay más de una)
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

# NUEVO: devuelve -1, 1 o 0
func _dir_pagina(event: InputEvent) -> int:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_LEFT:
			return -1
		if event.physical_keycode == KEY_RIGHT:
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

	_mostrar_pagina(0)   # NUEVO: siempre empieza en la primera página

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
