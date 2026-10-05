shader_type canvas_item;

uniform float outline_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Pintar de rojo puro todo el sprite
	COLOR = vec4(1.0, 0.0, 0.0, tex.a);
}