extends TileMapLayer

## Golpes de slash necesarios para romper una celda.
@export var hits_to_break: int = 2

## (Opcional) escena a instanciar al romper una celda (partículas, sonido, etc).
@export var break_effect_scene: PackedScene

# Vector2i -> int (golpes acumulados por celda)
var _hit_counts: Dictionary = {}


func _ready() -> void:
	add_to_group("breakable")


## Llamado por el SlashController cuando esta celda cae dentro del arco de ataque.
func hit_cell(cell: Vector2i) -> void:
	if get_cell_source_id(cell) == -1:
		return  # ya no hay tile ahí (o nunca la hubo)

	_hit_counts[cell] = _hit_counts.get(cell, 0) + 1

	if _hit_counts[cell] >= hits_to_break:
		_break_cell(cell)


func _break_cell(cell: Vector2i) -> void:
	var world_pos: Vector2 = to_global(map_to_local(cell))
	erase_cell(cell)
	_hit_counts.erase(cell)

	if break_effect_scene:
		var fx := break_effect_scene.instantiate()
		get_tree().current_scene.add_child(fx)
		fx.global_position = world_pos
