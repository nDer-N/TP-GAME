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

@export_group("Botones - Colores (sin imagen)")
@export var button_normal_color: Color = Color(0.12, 0.12, 0.2, 0.85)
@export var button_hover_color: Color = Color(0.25, 0.25, 0.4, 0.95)
@export var button_pressed_color: Color = Color(0.08, 0.08, 0.15, 1.0)
@export var button_disabled_color: Color = Color(0.1, 0.1, 0.1, 0.5)
@export var button_corner_radius: int = 8

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

# ============================================================== INTERNO
var is_open: bool = false
var pages: Dictionary = {}
var root: Control
var confirm: ConfirmationDialog
var pending_exit: String = ""
var volume_slider: HSlider
var fullscreen_check: CheckButton
var click_player: AudioStreamPlayer
var hover_player: AudioStreamPlayer


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
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


func _make_theme() -> Theme:
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
	var hover_box := _make_box(button_hover_texture, button_hover_color)
	t.set_stylebox("normal", "Button", _make_box(button_normal_texture, button_normal_color))
	t.set_stylebox("hover", "Button", hover_box)
	t.set_stylebox("focus", "Button", hover_box)
	t.set_stylebox("pressed", "Button", _make_box(button_pressed_texture, button_pressed_color))
	t.set_stylebox("disabled", "Button", _make_box(button_disabled_texture, button_disabled_color))
	return t


# ================================================================ AUDIO

func _build_audio() -> void:
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

	confirm = ConfirmationDialog.new()
	confirm.title = text_save_title
	confirm.ok_button_text = text_save_yes
	confirm.cancel_button_text = text_save_no
	confirm.confirmed.connect(_on_exit_confirmed)
	root.add_child(confirm)


func _make_page(parent: Control, page_name: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", button_spacing)
	page.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages[page_name] = page
	return page


func _make_button(text: String, callback: Callable, parent: Control) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = button_size
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_play_click)
	b.pressed.connect(callback)
	b.mouse_entered.connect(_play_hover)
	b.focus_entered.connect(_play_hover)
	parent.add_child(b)
	return b


func _build_main_page(holder: Control) -> void:
	var p := _make_page(holder, "main")
	_make_button(text_resume, _resume, p)
	_make_button(text_settings, func(): _show_page("settings"), p)
	_make_button(text_to_menu, func(): _ask_exit("menu"), p)
	_make_button(text_quit, func(): _ask_exit("quit"), p)


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
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_show_page("main")


func _resume() -> void:
	is_open = false
	visible = false
	get_tree().paused = false


# ============================================================ SALIR / GUARDAR

func _ask_exit(action: String) -> void:
	pending_exit = action
	if SaveManager.session_has_checkpoint:
		confirm.dialog_text = text_save_message
	else:
		confirm.dialog_text = text_save_message_none
	confirm.popup_centered()


func _on_exit_confirmed() -> void:
	SaveManager.save_progress()
	if pending_exit == "menu":
		is_open = false
		visible = false
		get_tree().paused = false
		SaveManager.end_session()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if ResourceLoader.exists(main_menu_scene):
			get_tree().change_scene_to_file(main_menu_scene)
		else:
			push_error("PauseMenu: no existe la escena del menú principal: " + main_menu_scene)
	else:
		get_tree().quit()
