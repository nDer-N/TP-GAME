extends Control

@export var full_texture: Texture2D
@export var empty_texture: Texture2D
@export var icon_size: Vector2 = Vector2(32, 32)
@export var icon_spacing: float = 4.0

var icons: Array[TextureRect] = []


func setup(max_hits: int) -> void:
	for child in get_children():
		child.queue_free()
	icons.clear()
	
	for i in max_hits:
		var icon = TextureRect.new()
		icon.texture = full_texture
		icon.size = icon_size
		icon.position = Vector2((icon_size.x + icon_spacing) * i, 0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(icon)
		icons.append(icon)


func update_hits(current_hits: int) -> void:
	for i in icons.size():
		if i < current_hits:
			icons[i].texture = empty_texture
		else:
			icons[i].texture = full_texture
