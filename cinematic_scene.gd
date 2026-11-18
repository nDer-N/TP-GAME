class_name CinematicScene
extends Resource
## Una escena de la cinemática: una imagen y su texto.

@export var image: Texture2D
@export_multiline var text: String = ""
## Letras por segundo solo para esta escena. 0 = usar la velocidad general.
@export var text_speed: float = 0.0
