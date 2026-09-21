extends Area2D

## Daño de contacto (cuántos hits quita al jugador).
@export var damage: int = 1

## Fuerza del knockback al impactar.
@export var knockback_force: float = 450.0

## Componente vertical del knockback (para que salte un poco).
@export var knockback_up_force: float = 250.0

## Duración durante la cual el jugador queda empujado (si quieres controlarlo).
@export var knockback_duration: float = 0.25

## Tiempo de vida máximo por si nunca impacta.
@export var lifetime: float = 6.0

## Velocidad a la que viaja el proyectil (px/s).
@export var speed: float = 260.0

@onready var sprite: Sprite2D = $Sprite2D

var _direction: Vector2 = Vector2.ZERO
var _life_timer: float = 0.0
var _has_hit: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Llamado por la torreta al instanciar el proyectil.
func launch(from: Vector2, target: Vector2) -> void:
	global_position = from
	_direction = (target - from).normalized()

	# Rotar el sprite para que apunte en la dirección de disparo
	if sprite:
		sprite.rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	if _has_hit:
		return

	global_position += _direction * speed * delta

	_life_timer += delta
	if _life_timer >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _has_hit:
		return

	# Solo reacciona al jugador (que tiene take_hit)
	if not body.has_method("take_hit"):
		return

	_has_hit = true

	# Aplicar daño (1 hitpoint)
	body.take_hit()

	# Aplicar knockback al jugador
	_apply_knockback(body)

	queue_free()


func _apply_knockback(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return
	# Empujar en la dirección del proyectil + un poco hacia arriba
	body.velocity.x = _direction.x * knockback_force
	body.velocity.y = -knockback_up_force
