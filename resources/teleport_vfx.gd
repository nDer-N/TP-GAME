extends Node2D

@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var light: PointLight2D = $PointLight2D

## Llama a esta función al instanciar el efecto.
## direction: 1.0 para "aparecer" (expandir), -1.0 para "desaparecer" (colapsar).
func setup(direction: float = 1.0) -> void:
	# Configurar la velocidad radial según la dirección
	var mat := particles.process_material as ParticleProcessMaterial
	if mat:
		if direction > 0:
			# Aparecer: velocidad hacia afuera
			mat.initial_velocity_min = 100.0
			mat.initial_velocity_max = 200.0
		else:
			# Desaparecer: velocidad hacia adentro (negativa)
			mat.initial_velocity_min = -150.0
			mat.initial_velocity_max = -100.0

	# Asegurar que las partículas se reinicien y emitan
	particles.restart()
	particles.emitting = true

	# Si tienes luz, puedes animarla
	if light:
		var tween := create_tween()
		tween.tween_property(light, "energy", 0.0, 0.4)
