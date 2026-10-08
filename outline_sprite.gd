extends AnimatedSprite2D

## AnimatedSprite2D al que este outline debe seguir.
@export var target: AnimatedSprite2D


func _process(_delta: float) -> void:
	if target == null or target.sprite_frames == null:
		return
	# Sincronizar todo lo visual con el sprite principal
	sprite_frames = target.sprite_frames
	animation = target.animation
	frame = target.frame
	flip_h = target.flip_h
	# La posición se hereda del padre (Player), no hace falta copiarla
