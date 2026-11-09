extends Node

@export var animated_sprite: AnimatedSprite2D

@export var animation_map: Dictionary = {
	0: "idle",      # VisualState.IDLE
	1: "alerted",   # VisualState.ALERTED
	2: "charge",    # VisualState.CHARGING
	3: "dash",      # VisualState.DASHING
	4: "stunned",   # VisualState.STUNNED
	5: "death",     # VisualState.DEATH
	6: "hurt"       # VisualState.HURT (NUEVO)
}

enum VisualState { IDLE, ALERTED, CHARGING, DASHING, STUNNED, DEATH, HURT }

var _current_state: VisualState = VisualState.IDLE
var _current_anim: String = ""
var _locked: bool = false
var _hold_timer: float = 0.0


func _ready() -> void:
	if animated_sprite == null:
		push_warning("DasherAnimationController: animated_sprite no asignado.")
		return
	_set_state(VisualState.IDLE)


func _process(delta: float) -> void:
	if _hold_timer > 0.0:
		_hold_timer -= delta
		if _hold_timer <= 0.0:
			_locked = false


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

func unlock() -> void:
	_locked = false
	_hold_timer = 0.0

func play_death_and_wait() -> void:
	force_state(VisualState.DEATH, 999.0)
	await animated_sprite.animation_finished
