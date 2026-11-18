extends Node
## Música de gameplay: lista de canciones que van rotando.
## Se silencia durante el combate con el jefe y se reanuda al terminar.

@export_group("Lista de canciones")
## Arrastra aquí tus canciones (.mp3, .ogg o .wav).
@export var songs: Array[AudioStream] = []
## true = orden aleatorio. false = en el orden de la lista.
@export var shuffle: bool = false
@export var play_on_start: bool = true
## Segundos de silencio entre una canción y la siguiente.
@export var pause_between_songs: float = 1.5

@export_group("Volumen")
@export_range(-40.0, 6.0) var volume_db: float = -8.0
@export var bus: String = "Master"
## Segundos de fundido al empezar cada canción.
@export var fade_in: float = 1.5
## Segundos de fundido al entrar en combate.
@export var battle_fade_out: float = 1.0

var _player: AudioStreamPlayer
var _tween: Tween
var _order: Array[int] = []
var _last_index: int = -1
var _in_battle: bool = false
var _song_active: bool = false


func _ready() -> void:
	# Que siga sonando aunque el juego esté en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("gameplay_music")
	_player = AudioStreamPlayer.new()
	_player.bus = bus
	_player.finished.connect(_on_song_finished)
	add_child(_player)
	if play_on_start and not songs.is_empty():
		_play_next()


# ============================================================ LISTA

func _build_order() -> void:
	_order.clear()
	for i in songs.size():
		if songs[i] != null:
			_order.append(i)
	if shuffle:
		_order.shuffle()
		# Evita que la primera de la nueva ronda sea la que acaba de sonar
		if _order.size() > 1 and _order[0] == _last_index:
			var tmp: int = _order[0]
			_order[0] = _order[_order.size() - 1]
			_order[_order.size() - 1] = tmp


func _play_next() -> void:
	if _order.is_empty():
		_build_order()
	if _order.is_empty():
		return
	_last_index = _order.pop_front()

	# Duplicamos para quitar el loop (si no, la canción nunca "termina")
	var stream := songs[_last_index].duplicate() as AudioStream
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = false
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED

	_player.stream = stream
	_player.stream_paused = false
	_player.volume_db = -60.0
	_player.play()
	_song_active = true
	_fade_to(volume_db, fade_in)


func _on_song_finished() -> void:
	_song_active = false
	if _in_battle:
		return
	if pause_between_songs > 0.0:
		await get_tree().create_timer(pause_between_songs).timeout
	# Si mientras esperábamos empezó un combate, o ya arrancó otra, no hacer nada
	if _in_battle or _song_active:
		return
	_play_next()


func _fade_to(target_db: float, time: float) -> Tween:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_player, "volume_db", target_db, time)
	return _tween


# ====================================================== LLAMADAS DEL JEFE

## Llamar cuando empieza la batalla con el jefe.
func start_battle() -> void:
	if _in_battle:
		return
	_in_battle = true
	var t := _fade_to(-60.0, battle_fade_out)
	await t.finished
	# Solo pausar si el combate sigue activo
	if _in_battle:
		_player.stream_paused = true


## Llamar cuando termina la batalla (el jefe muere).
func end_battle() -> void:
	if not _in_battle:
		return
	_in_battle = false
	if _song_active:
		# Continúa la canción justo donde se quedó
		_player.stream_paused = false
		_fade_to(volume_db, fade_in)
	else:
		_play_next()


## Salta a la siguiente canción (por si quieres un botón o tecla).
func skip_song() -> void:
	if _in_battle:
		return
	_player.stop()
	_song_active = false
	_play_next()
