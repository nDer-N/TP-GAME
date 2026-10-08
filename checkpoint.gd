extends Area2D

@export var sprite: Sprite2D
@export var inactive_color: Color = Color(0.5, 0.5, 0.5, 1.0)
@export var active_color: Color = Color(1.0, 0.9, 0.3, 1.0)
@export var activation_vfx_scene: PackedScene

var _activated: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sprite:
		sprite.modulate = inactive_color


func _on_body_entered(body: Node2D) -> void:
	if _activated:
		return
	if not body.has_method("set_checkpoint"):
		return
	_activated = true
	body.set_checkpoint(global_position)

	if sprite:
		sprite.modulate = active_color
		var tw := create_tween()
		tw.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.1)
		tw.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)

	if activation_vfx_scene:
		var vfx := activation_vfx_scene.instantiate()
		get_tree().current_scene.add_child(vfx)
		vfx.global_position = global_position
