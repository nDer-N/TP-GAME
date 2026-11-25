extends GPUParticles2D

## Largo aproximado de cada chispa en pantalla, en píxeles.
@export var spark_length: float = 22.0
@export var spark_amount: int = 28

var _mat: ParticleProcessMaterial


func _ready() -> void:
	# --- Emisión: ráfaga única y corta ---
	amount = spark_amount
	lifetime = 0.4
	randomness = 0.5
	one_shot = true
	explosiveness = 1.0
	local_coords = false
	emitting = false

	# Escala calculada a partir del tamaño real de la textura
	var tex_h := 64.0
	if texture:
		tex_h = float(texture.get_height())
	var s_max := spark_length / tex_h
	var s_min := s_max * 0.5

	_mat = ParticleProcessMaterial.new()
	_mat.particle_flag_align_y = true
	_mat.direction = Vector3(0, -1, 0)          # se sobrescribe en fire()
	_mat.spread = 65.0
	_mat.initial_velocity_min = 300.0
	_mat.initial_velocity_max = 700.0
	_mat.damping_min = 300.0                    # frenan rápido: efecto "explosión"
	_mat.damping_max = 500.0
	_mat.gravity = Vector3(0, 500, 0)
	_mat.scale_min = s_min
	_mat.scale_max = s_max

	# Se encogen hasta desaparecer
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var curve_tex := CurveTexture.new()
	curve_tex.curve = curve
	_mat.scale_curve = curve_tex

	# Amarillo claro -> naranja -> transparente (sin blanco puro para no quemar la imagen)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 0.9, 0.5, 1.0),
		Color(1.0, 0.55, 0.1, 1.0),
		Color(1.0, 0.25, 0.0, 0.0),
	])
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	_mat.color_ramp = grad_tex

	process_material = _mat

	var canvas_mat := CanvasItemMaterial.new()
	canvas_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = canvas_mat

	finished.connect(queue_free)


## Dispara las chispas en `at`, saliendo en la dirección `normal`.
func fire(at: Vector2, normal: Vector2) -> void:
	global_position = at
	rotation = 0.0
	_mat.direction = Vector3(normal.x, normal.y, 0.0)
	restart()
	emitting = true
