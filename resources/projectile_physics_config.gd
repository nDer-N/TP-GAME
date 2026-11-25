class_name ProjectilePhysicsConfig
extends Resource

@export var base_speed: float = 400.0
@export var gravity: float = 900.0
@export var bounce_decay: float = 0.7
@export var max_bounces: int = 30
@export var trajectory_steps: int = 150
@export var trajectory_step_time: float = 0.05

@export_group("Rebote en techo")
## Velocidad mínima tras rebotar en un tile del grupo TECHO. Evita que el
## proyectil se quede quieto encima. 0 = solo la pérdida normal de energía.
@export var ceiling_min_bounce_speed: float = 250.0
## Cuántos píxeles se separa de la superficie tras rebotar, para no quedar pegado.
@export var ceiling_push_out: float = 2.0


## Rebote en un tile de TECHO. Lo usan el proyectil real y la línea de
## trayectoria, así la predicción coincide con lo que pasa en el juego.
func ceiling_bounce(incoming: Vector2, normal: Vector2) -> Vector2:
	var bounced: Vector2 = incoming.bounce(normal) * bounce_decay
	if ceiling_min_bounce_speed > 0.0 and bounced.length() < ceiling_min_bounce_speed:
		var dir: Vector2 = bounced.normalized() if bounced.length() > 0.001 else normal
		bounced = dir * ceiling_min_bounce_speed
	return bounced
