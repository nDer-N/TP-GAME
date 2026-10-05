extends Node

@export var animated_sprite: AnimatedSprite2D

@export var animation_map: Dictionary = {
	0: "idle",
	1: "walk",
	2: "run",
	3: "jump",
	4: "fall"
}

@export var min_hold_time: float = 0.0

## Tiempo que tiene el jugador para presionar de nuevo antes de pasar al Stop.
@export var combo_window: float = 0.7

## Secuencias de slash: start (uno), loops (alternan), stops (indexados por loop).
@export var slash_sequences: Dictionary = {
	"up": {
		"start": "UPSLASHStart",
		"loops": ["UPSLASHLoop_A", "UPSLASHLoop_B"],
		"stops": ["UPSLASHStop_A", "UPSLASHStop_B"],
	},
	"side": {
		"start": "SIDESLASHStart",
		"loops": ["SIDESLASHLoop_A", "SIDESLASHLoop_B"],
		"stops": ["SIDESLASHStop_A", "SIDESLASHStop_B"],
	},
	"down": {
		"start": "DOWNSLASHStart",
		"loops": ["DOWNSLASHLoop_A", "DOWNSLASHLoop_B"],
		"stops": ["DOWNSLASHStop_A", "DOWNSLASHStop_B"],
	},
}

enum VisualState { IDLE, WALK, RUN, JUMP, FALL}
enum SequencePhase { NONE, START, LOOP, STOP }

var _current_state: VisualState = VisualState.IDLE
var _current_anim: String = ""
var _hold_timer: float = 0.0
var _locked: bool = false

# --- Combo de slash ---
var _combo_phase: SequencePhase = SequencePhase.NONE
var _combo_data: Dictionary = {}
var _combo_loop_index: int = 0
var _combo_timer: float = 0.0


func _ready() -> void:
	if animated_sprite == null:
		push_warning("AnimationController: animated_sprite no asignado.")
		return
	animated_sprite.animation_finished.connect(_on_animation_finished)
	_set_state(VisualState.IDLE)



		
func _process(delta: float) -> void:
	if _hold_timer > 0.0:
		_hold_timer -= delta
		if _hold_timer <= 0.0:
			_locked = false

	# --- Combo: solo cuenta en START y LOOP ---
	if _combo_phase == SequencePhase.START or _combo_phase == SequencePhase.LOOP:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_enter_stop()


# ---------- ESTADOS NORMALES ----------

func set_state(new_state: VisualState) -> void:
	if _locked:
		return
	if new_state == _current_state:
		return
	_set_state(new_state)


func force_state(new_state: VisualState, lock_time: float = 0.0) -> void:
	_set_state(new_state)
	if lock_time > 0.0:
		_locked = true
		_hold_timer = lock_time


func _set_state(new_state: VisualState) -> void:
	_current_state = new_state
	var anim_name: String = animation_map.get(int(new_state), "")
	if anim_name == "":
		return
	if anim_name == _current_anim and animated_sprite.is_playing():
		return
	_current_anim = anim_name
	animated_sprite.play(anim_name)


func get_state() -> VisualState:
	return _current_state

func is_locked() -> bool:
	return _locked


# ---------- COMBO DE SLASH ----------

## Empieza una secuencia nueva. direction_key = "up" / "side" / "down".
func start_slash_sequence(direction_key: String) -> void:
	var data: Dictionary = slash_sequences.get(direction_key, {})
	if data.is_empty():
		push_warning("AnimationController: no hay secuencia para '", direction_key, "'")
		return

	# Si ya estamos en una secuencia, tratamos este input como avance.
	if _combo_phase == SequencePhase.START or _combo_phase == SequencePhase.LOOP:
		advance_slash_sequence()
		return

	_combo_data = data
	_combo_phase = SequencePhase.START
	_combo_loop_index = 0
	_combo_timer = combo_window
	_locked = true
	_play_animation(data["start"])


## Avanza el combo al siguiente loop. Lo llama el jugador al presionar de nuevo.
func advance_slash_sequence() -> void:
	print("[AC] advance. phase=", _combo_phase, " loop_idx=", _combo_loop_index)
	if _combo_phase != SequencePhase.START and _combo_phase != SequencePhase.LOOP:
		print("[AC]   → no está en START/LOOP, abort")
		return

	var loops: Array = _combo_data.get("loops", [])
	print("[AC]   → loops=", loops)
	if loops.is_empty():
		print("[AC]   → loops vacío, end")
		_end_sequence()
		return

	if _combo_phase == SequencePhase.START:
		_combo_phase = SequencePhase.LOOP
		_combo_loop_index = 0
	else:
		_combo_loop_index = 1 - _combo_loop_index

	print("[AC]   → nuevo idx=", _combo_loop_index)
	_combo_timer = combo_window
	_play_animation(loops[_combo_loop_index])


func is_in_sequence() -> bool:
	return _combo_phase != SequencePhase.NONE


# ---------- FASES ----------

func _on_animation_finished() -> void:
	print("[AC] animation_finished. phase=", _combo_phase)
	match _combo_phase:
		SequencePhase.START:
			# NO auto-transicionar. Esperamos input o que expire el timer.
			_combo_timer = combo_window
			pass

		SequencePhase.LOOP:
			# Tampoco. Quedate en la última pose esperando input o timeout.
			pass

		SequencePhase.STOP:
			_end_sequence()


func _enter_stop() -> void:
	var stops: Array = _combo_data.get("stops", [])
	if stops.is_empty():
		_end_sequence()
		return
	_combo_phase = SequencePhase.STOP
	_play_animation(stops[_combo_loop_index % stops.size()])


func _play_animation(anim_name: String) -> void:
	print("[AC] play_animation: ", anim_name)
	if animated_sprite == null:
		print("[AC]   → animated_sprite null")
		return
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		print("[AC]   → ANIMACIÓN NO EXISTE en SpriteFrames: ", anim_name)
		return
	_current_anim = anim_name
	animated_sprite.play(anim_name)
	print("[AC]   → play OK")


func _end_sequence() -> void:
	_combo_phase = SequencePhase.NONE
	_combo_data = {}
	_combo_loop_index = 0
	_combo_timer = 0.0
	_locked = false
	_set_state(VisualState.IDLE)
	
func cancel_sequence() -> void:
	if _combo_phase == SequencePhase.NONE:
		return
	_combo_phase = SequencePhase.NONE
	_combo_data = {}
	_combo_loop_index = 0
	_combo_timer = 0.0
	_locked = false
	_set_state(VisualState.IDLE)
