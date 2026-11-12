extends Node

enum VisualState { 
	IDLE, CHASE, 
	SHOOT_CHARGE, SHOOT_FIRE, 
	JUMP_WINDUP, JUMP_AIR, JUMP_LAND, 
	DASH_WINDUP, DASH_MOVE, 
	SHOCKWAVE_WINDUP, SHOCKWAVE_BLAST, 
	HURT, DEATH, WEEP,
	CATCH_TP, BREAK_TP
}

@export var animated_sprite: AnimatedSprite2D

var is_phase_2: bool = false

@export var animation_map: Dictionary = {
	VisualState.IDLE: {"p1": "idle", "p2": "idle_p2"},
	VisualState.CHASE: {"p1": "chase", "p2": "chase_p2"},
	VisualState.SHOOT_CHARGE: {"p1": "shoot_charge", "p2": "shoot_charge_p2"},
	VisualState.SHOOT_FIRE: {"p1": "shoot_fire", "p2": "shoot_fire_p2"},
	VisualState.JUMP_WINDUP: {"p1": "jump_windup", "p2": "jump_windup_p2"},
	VisualState.JUMP_AIR: {"p1": "jump_air", "p2": "jump_air_p2"},
	VisualState.JUMP_LAND: {"p1": "jump_land", "p2": "jump_land_p2"},
	VisualState.DASH_WINDUP: {"p1": "", "p2": "dash_windup_p2"},
	VisualState.DASH_MOVE: {"p1": "", "p2": "dash_move_p2"},
	VisualState.SHOCKWAVE_WINDUP: {"p1": "shockwave_windup", "p2": "shockwave_windup_p2"},
	VisualState.SHOCKWAVE_BLAST: {"p1": "shockwave_blast", "p2": "shockwave_blast_p2"},
	VisualState.HURT: {"p1": "hurt", "p2": "hurt_p2"},
	VisualState.DEATH: {"p1": "death", "p2": "death_p2"},
	VisualState.WEEP: {"p1": "weep", "p2": "weep_p2"}
}

var _current_state: VisualState = VisualState.IDLE
var _current_anim: String = ""
var _locked: bool = false
var _hold_timer: float = 0.0

func _ready() -> void:
	if not animation_map.has(VisualState.CATCH_TP):
		animation_map[VisualState.CATCH_TP] = {"p1": "catch_tp", "p2": "catch_tp"}
	if not animation_map.has(VisualState.BREAK_TP):
		animation_map[VisualState.BREAK_TP] = {"p1": "break_tp", "p2": "break_tp"}
	if animated_sprite == null:
		push_warning("BossAnimationController: animated_sprite no asignado.")
		return
	_set_state(VisualState.IDLE)

func _process(delta: float) -> void:
	if _hold_timer > 0.0:
		_hold_timer -= delta
		if _hold_timer <= 0.0:
			_locked = false

func set_state(new_state: VisualState) -> void:
	if _locked: return
	if new_state == _current_state: return
	_set_state(new_state)

func force_state(new_state: VisualState, lock_time: float = 0.0) -> void:
	_set_state(new_state)
	if lock_time > 0.0:
		_locked = true
		_hold_timer = lock_time

func unlock() -> void:
	_locked = false
	_hold_timer = 0.0

## Reproduce la animación de disparo direccional (up, side, down).
func play_shoot_fire(direction: Vector2) -> void:
	var angle_deg = rad_to_deg(direction.angle())
	var dir_key = "side"
	
	if angle_deg >= -135.0 and angle_deg <= -45.0:
		dir_key = "up"
	elif angle_deg >= 45.0 and angle_deg <= 135.0:
		dir_key = "down"
	else:
		dir_key = "side"
		animated_sprite.flip_h = direction.x < 0.0 # Voltear si dispara a la izquierda
		
	if dir_key != "side":
		animated_sprite.flip_h = false # Resetear flip para up/down

	var anim_name = "shoot_fire_" + dir_key
	if is_phase_2:
		anim_name += "_p2"
		
	_current_state = VisualState.SHOOT_FIRE
	_current_anim = anim_name
	animated_sprite.play(anim_name)

## Espera a que la animación actual termine (calculando su duración).
func play_and_wait(new_state: VisualState, fallback_time: float = 0.6) -> void:
	var anim_dict: Dictionary = animation_map.get(new_state, {})
	if anim_dict.is_empty(): return
	
	var anim_name: String = anim_dict.get("p2" if is_phase_2 else "p1", "")
	if anim_name == "": return
	
	# Si la animación aún no existe (no la has dibujado), espera un rato y sigue.
	if animated_sprite.sprite_frames == null or not animated_sprite.sprite_frames.has_animation(anim_name):
		push_warning("BossAnimationController: falta la animacion '%s' (espero %.1f s)" % [anim_name, fallback_time])
		await get_tree().create_timer(fallback_time, false).timeout
		return
	
	if anim_name == _current_anim and animated_sprite.animation == anim_name:
		animated_sprite.frame = 0 
		
	force_state(new_state)
	
	var frames := animated_sprite.sprite_frames.get_frame_count(anim_name)
	var speed := animated_sprite.sprite_frames.get_animation_speed(anim_name)
	await get_tree().create_timer(frames / speed, false).timeout

func _set_state(new_state: VisualState) -> void:
	_current_state = new_state
	var anim_dict: Dictionary = animation_map.get(new_state, {})
	if anim_dict.is_empty(): return
	
	var anim_name: String = anim_dict.get("p2" if is_phase_2 else "p1", "")
	if anim_name == "": return
	if anim_name == _current_anim and animated_sprite.is_playing(): return
	
	_current_anim = anim_name
	animated_sprite.play(anim_name)
