extends Node

## Cuántos frames de pausa pedir (a 60 fps, 4 frames = ~66 ms).
## Usamos frames en vez de segundos porque es más consistente entre juegos.
var _pending_frames: int = 0
var _is_active: bool = false


func _ready() -> void:
	# Este autoload siempre procesa, incluso en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if _pending_frames > 0:
		_pending_frames -= 1
		if _pending_frames <= 0 and _is_active:
			_end_hit_stop()


## Pedir hit stop en segundos.
## Ejemplo: HitStop.request(0.08) → pausa 80ms
func request(duration: float, ignore_time_scale: bool = true) -> void:
	# Cuántos frames de proceso corresponden a esa duración
	# Engine.physics_ticks_per_second es típicamente 60
	var fps := Engine.physics_ticks_per_second
	if fps <= 0:
		fps = 60
	var frames := int(round(duration * fps))
	request_frames(frames, ignore_time_scale)


## Pedir hit stop en frames de física.
func request_frames(frames: int, _ignore_time_scale: bool = true) -> void:
	if frames <= 0:
		return
	# Si ya hay uno activo, tomar el mayor (no acumular indefinidamente)
	_pending_frames = max(_pending_frames, frames)
	if not _is_active:
		_start_hit_stop()


func _start_hit_stop() -> void:
	_is_active = true
	get_tree().paused = true


func _end_hit_stop() -> void:
	_is_active = false
	get_tree().paused = false
