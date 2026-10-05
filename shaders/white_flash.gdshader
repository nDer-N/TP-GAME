shader_type canvas_item;

// 0 = color original, 1 = blanco puro
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Mezclar el color original con el blanco según flash_amount.
	// El alpha se mantiene, así que la silueta no cambia.
	tex.rgb = mix(tex.rgb, flash_color.rgb, flash_amount);
	COLOR = tex * COLOR;  // respeta el modulate del nodo (por si lo usas)
}