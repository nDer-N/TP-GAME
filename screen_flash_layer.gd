extends CanvasLayer

@onready var flash_rect: ColorRect = $ScreenFlash

var _tween: Tween = null


## Dispara un flash blanco. `intensity` = alpha inicial (0..1).
## `duration` = cuánto tarda en desvanecerse a 0.
func flash(intensity: float = 1.0, duration: float = 0.2) -> void:
	if flash_rect == null:
		return
	# Matar el tween anterior si había uno en curso
	if _tween and _tween.is_valid():
		_tween.kill()
	
	flash_rect.color = Color(1, 1, 1, intensity)
	_tween = create_tween()
	_tween.tween_property(flash_rect, "color:a", 0.0, duration)
