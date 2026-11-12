extends Control
## Menú principal.
## Selecciona el nodo MainMenu y edita todo desde el Inspector:
## fondo, título, fuentes, imágenes de botones, textos y sonidos.

# ============================================================ INSPECTOR
@export_group("Juego")
@export_file("*.tscn") var game_scene: String = "res://tutorial.tscn"
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

@export_group("Botones - Aspecto")
@export var button_font: Font
@export var button_font_size: int = 24
@export var button_size: Vector2 = Vector2(320, 48)
@export var slot_button_size: Vector2 = Vector2(460, 64)
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
@export var icon_button_size: Vector2 = Vector2(64, 64)
@export var name_max_length: int = 24

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
@export var menu_music: AudioStream
@export var click_sound: AudioStream
@export var hover_sound: AudioStream

# ============================================================== INTERNO
const TRASH_SVG := "<svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><polyline points='3 6 5 6 21 6'/><path d='M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6'/><path d='M10 11v6M14 11v6'/><path d='M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2'/></svg>"
const PENCIL_SVG := "<svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M12 20h9'/><path d='M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z'/></svg>"

var pages: Dictionary = {}
var slots_mode: String = "new"
var slots_title: Label
var slot_buttons: Array[Button] = []
var rename_buttons: Array[Button] = []
var delete_buttons: Array[Button] = []
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
	music_player.stream = menu_music
	add_child(music_player)
	if menu_music != null:
		music_player.play()

	click_player = AudioStreamPlayer.new()
	click_player.stream = click_sound
	add_child(click_player)

	hover_player = AudioStreamPlayer.new()
	hover_player.stream = hover_sound
	add_child(hover_player)


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
	holder.custom_minimum_size = Vector2(640, 420)
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


func _build_slots_page(holder: Control) -> void:
	var p := _make_page(holder, "slots")
	slots_title = _make_heading("", p)
	for i in range(1, SaveManager.SLOT_COUNT + 1):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		p.add_child(row)

		var sb := _make_button("", _on_slot_pressed.bind(i), row, slot_button_size)
		sb.clip_text = true
		var rb := _make_icon_button(rename_tex, "✎", text_rename_tooltip, _on_rename_pressed.bind(i), row)
		var db := _make_icon_button(delete_tex, "X", text_delete_tooltip, _on_delete_pressed.bind(i), row)
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
		slot_buttons[i].text = SaveManager.get_slot_summary(slot)
		slot_buttons[i].disabled = (mode == "load" and not has)
		# Renombrar y eliminar solo aparecen en "Cargar" y si hay partida
		rename_buttons[i].visible = (mode == "load" and has)
		delete_buttons[i].visible = (mode == "load" and has)
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
	SaveManager.new_game(slot, save_name)
	_go_to_game()


func _load_slot(slot: int) -> void:
	if SaveManager.load_game(slot):
		_go_to_game()


func _go_to_game() -> void:
	var target: String = game_scene
	var saved_scene: String = str(SaveManager.pending_load_data.get("scene", ""))
	if saved_scene != "" and ResourceLoader.exists(saved_scene):
		target = saved_scene
	get_tree().change_scene_to_file(target)
