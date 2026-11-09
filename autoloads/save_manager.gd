extends Node
## Autoload: debe llamarse "SaveManager"
## (Proyecto > Configuración del Proyecto > Autoload).

const SLOT_COUNT := 3
const SETTINGS_PATH := "user://settings.cfg"

var current_slot: int = -1
## Datos del guardado cargado (por si tu juego quiere leerlos).
var pending_load_data: Dictionary = {}

# ---- Estado de la partida en curso (se rellena al entrar al juego) ----
var in_game: bool = false
var playtime: float = 0.0
var session_has_checkpoint: bool = false
var session_checkpoint_pos: Vector2 = Vector2.ZERO
## Claves (rutas de nodo) de los checkpoints ya activados.
var session_activated: Array = []

var settings := {
	"master_volume": 1.0,
	"fullscreen": false,
}


func _ready() -> void:
	load_settings()
	apply_settings()


func _process(delta: float) -> void:
	# Este nodo se pausa junto con el juego, así que la pausa no cuenta.
	if in_game:
		playtime += delta


# ------------------------------------------------------------ PARTIDA ACTUAL

func _begin_session(data: Dictionary) -> void:
	playtime = float(data.get("playtime", 0.0))
	session_has_checkpoint = bool(data.get("has_checkpoint", false))
	session_checkpoint_pos = Vector2(
		float(data.get("checkpoint_x", 0.0)),
		float(data.get("checkpoint_y", 0.0)))
	session_activated = []
	for k in data.get("activated_checkpoints", []):
		session_activated.append(str(k))
	in_game = true


func end_session() -> void:
	in_game = false


## Lo llaman los checkpoints cuando el jugador los activa.
func register_checkpoint(key: String, pos: Vector2) -> void:
	session_has_checkpoint = true
	session_checkpoint_pos = pos
	if not session_activated.has(key):
		session_activated.append(key)
	print("CHECKPOINT REGISTRADO: ", key, " ", pos)


## Guarda el progreso (último checkpoint + tiempo) en la ranura en uso.
func save_progress() -> void:
	if current_slot < 1:
		print("NO SE GUARDA: current_slot es ", current_slot)
		return
	var data: Dictionary = read_slot(current_slot)
	data["playtime"] = playtime
	data["has_checkpoint"] = session_has_checkpoint
	data["checkpoint_x"] = session_checkpoint_pos.x
	data["checkpoint_y"] = session_checkpoint_pos.y
	data["activated_checkpoints"] = session_activated
	var scene: Node = get_tree().current_scene
	if scene != null and scene.scene_file_path != "":
		data["scene"] = scene.scene_file_path
	print("GUARDANDO slot ", current_slot, " checkpoint: ", session_has_checkpoint, " ", session_checkpoint_pos)
	save_game(current_slot, data)


# ---------------------------------------------------------------- GUARDADOS

func _slot_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))


func any_save() -> bool:
	for i in range(1, SLOT_COUNT + 1):
		if has_save(i):
			return true
	return false


func _write_slot(slot: int, data: Dictionary) -> void:
	var f := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if f == null:
		push_error("No se pudo escribir el slot %d" % slot)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


## Guarda la partida. Si "data" no trae nombre, se conserva el que ya tenía.
func save_game(slot: int, data: Dictionary) -> void:
	if not data.has("name"):
		data["name"] = get_slot_name(slot)
	data["timestamp"] = Time.get_unix_time_from_system()
	data["version"] = 1
	_write_slot(slot, data)
	current_slot = slot


func read_slot(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var f := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}


func delete_slot(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(_slot_path(slot))


## Cambia el nombre de una partida sin alterar su fecha de guardado.
func rename_slot(slot: int, new_name: String) -> void:
	var d: Dictionary = read_slot(slot)
	if d.is_empty():
		return
	var clean: String = new_name.strip_edges()
	if clean == "":
		clean = "Partida %d" % slot
	d["name"] = clean
	_write_slot(slot, d)


func get_slot_name(slot: int) -> String:
	var d: Dictionary = read_slot(slot)
	var n: String = str(d.get("name", ""))
	if n == "":
		return "Partida %d" % slot
	return n


## Devuelve el slot guardado más recientemente (o -1 si no hay ninguno).
func get_last_slot() -> int:
	var best: int = -1
	var best_time: float = -1.0
	for i in range(1, SLOT_COUNT + 1):
		var d: Dictionary = read_slot(i)
		if d.is_empty():
			continue
		var t: float = d.get("timestamp", 0.0)
		if t > best_time:
			best_time = t
			best = i
	return best


## Crea una partida nueva en el slot (sobrescribe si había algo).
func new_game(slot: int, save_name: String = "") -> void:
	delete_slot(slot)
	var clean: String = save_name.strip_edges()
	if clean == "":
		clean = "Partida %d" % slot
	var data: Dictionary = {
		"name": clean,
		"playtime": 0.0,
		"has_checkpoint": false,
		"checkpoint_x": 0.0,
		"checkpoint_y": 0.0,
		"activated_checkpoints": [],
	}
	save_game(slot, data)
	pending_load_data = data
	current_slot = slot
	_begin_session(data)


func load_game(slot: int) -> bool:
	var data: Dictionary = read_slot(slot)
	if data.is_empty():
		return false
	pending_load_data = data
	current_slot = slot
	_begin_session(data)
	return true


## Texto de resumen para los botones de slot.
func get_slot_summary(slot: int) -> String:
	var d: Dictionary = read_slot(slot)
	if d.is_empty():
		return "Espacio %d  —  Vacío" % slot
	var date: String = Time.get_datetime_string_from_unix_time(int(d.get("timestamp", 0)), true)
	var secs: int = int(d.get("playtime", 0.0))
	var time_str: String = "%02d:%02d:%02d" % [secs / 3600, (secs % 3600) / 60, secs % 60]
	return "%s  —  %s  —  %s" % [get_slot_name(slot), date, time_str]


# ------------------------------------------------------------------ AJUSTES

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for key in settings.keys():
		settings[key] = cfg.get_value("settings", key, settings[key])


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in settings.keys():
		cfg.set_value("settings", key, settings[key])
	cfg.save(SETTINGS_PATH)


func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(settings["master_volume"]))
	if settings["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
