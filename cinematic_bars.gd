extends CanvasLayer
## Barras cinemáticas (arriba y abajo de la pantalla) para momentos de impacto.
##
## Se usa como Autoload con el nombre "CinematicBars":
##   CinematicBars.play()        # se quedan la duración por defecto
##   CinematicBars.play(0.5)     # se quedan 0.5 s (+ un pequeño extra) y se van solas
##   CinematicBars.stop()        # las quita ya
##
## Funcionan durante el hitstop (time_scale casi en 0 o juego en pausa) porque
## cuentan el tiempo real, no el tiempo del juego.

@export_group("Capa")
## Capa de dibujo. Tiene que ser MENOR que la capa de tu UI para que las barras
## queden por debajo de ella (y MAYOR que 0 para quedar encima del mundo).
@export var bars_layer: int = 1

@export_group("Aspecto")
@export var bar_color: Color = Color.BLACK
## Alto de cada barra como fracción del alto de la pantalla (0.12 = 12 %).
@export_range(0.0, 0.5) var bar_height_ratio: float = 0.12

@export_group("Tiempos")
## Segundos que tardan en entrar.
@export var slide_in_time: float = 0.10
## Segundos que tardan en salir.
@export var slide_out_time: float = 0.35
## Cuánto se quedan si llamas play() sin duración.
@export var default_duration: float = 0.5
## Tiempo extra que se quedan después de la duración, para que no se vayan
## justo en el instante en que termina el hitstop.
@export var extra_hold: float = 0.15

var _top: ColorRect
var _bottom: ColorRect
var _amount: float = 0.0       # 0 = escondidas, 1 = completamente abajo/arriba
var _target: float = 0.0
var _time_left: float = 0.0
var _last_usec: int = 0


func _ready() -> void:
	layer = bars_layer
	process_mode = Node.PROCESS_MODE_ALWAYS   # que sigan animándose con el juego en pausa
	visible = false

	_top = _make_bar()
	_top.anchor_top = 0.0
	_top.anchor_bottom = 0.0
	add_child(_top)

	_bottom = _make_bar()
	_bottom.anchor_top = 1.0
	_bottom.anchor_bottom = 1.0
	add_child(_bottom)

	_apply()


func _make_bar() -> ColorRect:
	var r := ColorRect.new()
	r.color = bar_color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.anchor_left = 0.0
	r.anchor_right = 1.0
	r.offset_left = 0.0
	r.offset_right = 0.0
	return r


## Muestra las barras. duration = cuánto se quedan antes de empezar a salir
## (normalmente la duración del hitstop). Si ya están visibles, extiende el tiempo.
func play(duration: float = -1.0) -> void:
	var d: float = default_duration if duration < 0.0 else duration
	_time_left = maxf(_time_left, d + extra_hold)
	_target = 1.0
	_last_usec = Time.get_ticks_usec()
	visible = true


## Las quita de inmediato (con su animación de salida).
func stop() -> void:
	_time_left = 0.0
	_target = 0.0


func _process(_delta: float) -> void:
	# Tiempo REAL: no depende de Engine.time_scale ni de la pausa.
	var now: int = Time.get_ticks_usec()
	var dt: float = minf(float(now - _last_usec) / 1000000.0, 0.1)
	_last_usec = now
	if not visible:
		return

	if _target > 0.5:
		_time_left -= dt
		if _time_left <= 0.0:
			_target = 0.0

	var duration: float = slide_in_time if _target > 0.5 else slide_out_time
	_amount = move_toward(_amount, _target, dt / maxf(duration, 0.001))
	_apply()

	if _amount <= 0.0 and _target <= 0.0:
		visible = false


func _apply() -> void:
	var screen_h: float = get_viewport().get_visible_rect().size.y
	var h: float = screen_h * bar_height_ratio * smoothstep(0.0, 1.0, _amount)
	_top.offset_top = 0.0
	_top.offset_bottom = h
	_bottom.offset_top = -h
	_bottom.offset_bottom = 0.0
