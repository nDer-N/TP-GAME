extends Node

@export var animated_sprite: AnimatedSprite2D

@export var animation_map: Dictionary = {
	0: "idle",
	1: "walk",
	2: "run",
	3: "jump",
	4: "fall",
	5: "landing",
	6: "recharging"
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

@export var aim_sequence: Dictionary = {
	"start": "TPAimStart",
	"loop": "TPAimLoop",
	"shoot": "TPShoot",
}

enum VisualState { IDLE, WALK, RUN, JUMP, FALL, LANDING, RECHARGING}
enum SequencePhase { NONE, START, LOOP, STOP }
enum AimPhase { NONE, START, LOOP, SHOOT }

var _current_state: VisualState = VisualState.IDLE
var _current_anim: String = ""
var _hold_timer: float = 0.0
var _locked: bool = false

# --- Combo de slash ---
var _combo_phase: SequencePhase = SequencePhase.NONE
var _combo_data: Dictionary = {}
var _combo_loop_index: int = 0
var _combo_timer: float = 0.0

# --- Apuntado del TP ---
var _aim_phase: AimPhase = AimPhase.NONE
var _aim_visible: bool = false


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

func is_movement_locked() -> bool:
	return _combo_phase == SequencePhase.START or _combo_phase == SequencePhase.LOOP
func set_state(new_state: VisualState) -> void:
	if _locked:
		return
	if new_state == _current_state:
		return
	_set_state(new_state)
	
func unlock() -> void:
	_locked = false
	_hold_timer = 0.0

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

	# Si ya hay una secuencia activa, actualizamos la dirección y avanzamos.
	# Esto permite combos con direcciones distintas:
	#   SIDESLASHStart → UPSLASHLoop_A → DOWNSLASHLoop_B → DOWNSLASHStop_B
	if _combo_phase == SequencePhase.START or _combo_phase == SequencePhase.LOOP:
		_combo_data = data
		advance_slash_sequence()
		return

	# Secuencia nueva
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

func start_aim_sequence() -> void:
	if _aim_phase != AimPhase.NONE:
		return
	var start_anim: String = aim_sequence.get("start", "")
	if start_anim == "":
		return
	_aim_phase = AimPhase.START
	_aim_visible = true
	_locked = true
	_play_animation(start_anim)

func end_aim_sequence() -> void:
	if _aim_phase != AimPhase.START and _aim_phase != AimPhase.LOOP:
		return
	_aim_phase = AimPhase.SHOOT
	_aim_visible = true
	var shoot_anim: String = aim_sequence.get("shoot", "")
	if shoot_anim == "":
		_end_aim()
		return
	_play_animation(shoot_anim)

func cancel_aim_sequence() -> void:
	if _aim_phase == AimPhase.NONE:
		return
	_end_aim()

func get_current_aim_anim() -> String:
	match _aim_phase:
		AimPhase.START: return aim_sequence.get("start", "")
		AimPhase.LOOP:  return aim_sequence.get("loop", "")
		AimPhase.SHOOT: return aim_sequence.get("shoot", "")
	return ""
	
func show_aim() -> void:
	if _aim_phase == AimPhase.NONE:
		return
	_aim_visible = true
	_locked = true   # ← volver a bloquear para que set_state(IDLE) no pise
	var anim := get_current_aim_anim()
	if anim != "":
		_play_animation(anim)

func hide_aim() -> void:
	if not _aim_visible:
		return
	_aim_visible = false
	_locked = false 

func is_aiming() -> bool:
	return _aim_phase != AimPhase.NONE

func is_playing_scripted() -> bool:
	return is_in_sequence() or is_aiming()

func is_aim_visible() -> bool:
	return _aim_visible

func _end_aim() -> void:
	_aim_phase = AimPhase.NONE
	_aim_visible = false
	_locked = false
	_set_state(VisualState.IDLE)
	
func is_in_sequence() -> bool:
	return _combo_phase != SequencePhase.NONE


# ---------- FASES ----------

func _on_animation_finished() -> void:
	# --- Aim ---
	if _aim_phase != AimPhase.NONE:
		# Si el aim no se está mostrando, no avanzar la fase
		if not _aim_visible:
			return
		match _aim_phase:
			AimPhase.START:
				_aim_phase = AimPhase.LOOP
				var loop_anim: String = aim_sequence.get("loop", "")
				if loop_anim == "":
					_end_aim()
					return
				_play_animation(loop_anim)
			AimPhase.LOOP:
				pass
			AimPhase.SHOOT:
				_end_aim()
		return

	# --- Slash (lo que ya tenías) ---
	match _combo_phase:
		SequencePhase.START:
			_combo_loop_index = 1
			_combo_timer = combo_window
			pass
		SequencePhase.LOOP:
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
	if _combo_phase == SequencePhase.NONE and _aim_phase == AimPhase.NONE:
		return
	_combo_phase = SequencePhase.NONE
	_combo_data = {}
	_combo_loop_index = 0
	_combo_timer = 0.0
	_aim_phase = AimPhase.NONE
	_aim_visible = false
	_locked = false
	_set_state(VisualState.IDLE)
