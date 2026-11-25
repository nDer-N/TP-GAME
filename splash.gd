extends ParallaxBackground
## Fondo con parallax que sigue al cursor.
## Raíz de splash.tscn (nodo ParallaxBackground). Las capas se crean solas:
## solo asigna las texturas en el Inspector, de la más lejana a la más cercana.

@export_group("Capas")
## De atrás hacia adelante (ej: bg, mlay2, mlay1, train, char).
@export var layer_textures: Array[Texture2D] = []
## Profundidad de cada capa, en el mismo orden. 0 = quieta, 1 = se mueve al máximo.
## Si faltan valores, se reparten automáticamente de 0 a 1.
@export var layer_depths: Array[float] = []

@export_group("Movimiento")
## Desplazamiento máximo (en píxeles) de una capa con profundidad 1.
@export var max_offset: Vector2 = Vector2(40, 24)
## Qué tan rápido alcanza al cursor (más alto = más pegado).
@export_range(0.5, 30.0, 0.5) var smoothing: float = 6.0
## false = las capas se mueven en dirección opuesta al cursor (efecto clásico).
@export var invert: bool = false

var _sprites: Array[Sprite2D] = []
var _depths: Array[float] = []
var _current := Vector2.ZERO


func _ready() -> void:
	_build_layers()
	_fit_layers()
	get_viewport().size_changed.connect(_fit_layers)


func _build_layers() -> void:
	var n := layer_textures.size()
	for i in n:
		var tex := layer_textures[i]
		if tex == null:
			continue
		var depth: float
		if i < layer_depths.size():
			depth = layer_depths[i]
		else:
			depth = float(i) / float(max(n - 1, 1))
		var pl := ParallaxLayer.new()
		pl.motion_scale = Vector2(depth, depth)
		add_child(pl)
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = true
		pl.add_child(sp)
		_sprites.append(sp)
		_depths.append(depth)


## Ajusta cada imagen para cubrir la pantalla (con margen extra para que
## no se vean bordes cuando la capa se desplaza).
func _fit_layers() -> void:
	var vp := get_viewport().get_visible_rect().size
	for i in _sprites.size():
		var sp := _sprites[i]
		var tex_size := sp.texture.get_size()
		var margin := max_offset.abs() * absf(_depths[i])
		var target := vp + margin * 2.0
		var s := maxf(target.x / tex_size.x, target.y / tex_size.y)
		sp.scale = Vector2(s, s)
		sp.position = vp * 0.5


func _process(delta: float) -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	var mouse := get_viewport().get_mouse_position()
	var norm := ((mouse / vp) - Vector2(0.5, 0.5)) * 2.0
	norm = norm.clamp(Vector2(-1, -1), Vector2(1, 1))
	_current = _current.lerp(norm, 1.0 - exp(-smoothing * delta))
	var dir := 1.0 if invert else -1.0
	scroll_offset = _current * max_offset * dir
