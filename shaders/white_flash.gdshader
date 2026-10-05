shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float outline_amount : hint_range(0.0, 100.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(1.0, 0.6, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 100.0) = 1.5;

void fragment() {
	// Un pixel en coordenadas UV (funciona con cualquier tamaño de frame/escala)
	vec2 pixel = fwidth(UV);

	vec4 tex = texture(TEXTURE, UV);

	// --- Outline (8 vecinos) ---
	float neighbor_alpha = 0.0;
	neighbor_alpha += texture(TEXTURE, UV + vec2(-outline_width, 0.0) * pixel).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2( outline_width, 0.0) * pixel).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2(0.0, -outline_width) * pixel).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2(0.0,  outline_width) * pixel).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2(-outline_width, -outline_width) * pixel).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2( outline_width, -outline_width) * pixel).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2(-outline_width,  outline_width) * pixel).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2( outline_width,  outline_width) * pixel).a;
	neighbor_alpha = clamp(neighbor_alpha, 0.0, 1.0);

	// Máscara: pixel transparente + algún vecino opaco → dibujar outline
	float outline_mask = (1.0 - tex.a) * step(0.01, neighbor_alpha) * outline_amount;

	// --- Flash ---
	vec3 flash_rgb = mix(tex.rgb, flash_color.rgb, flash_amount);

	// --- Componer ---
	vec3 final_rgb = mix(flash_rgb, outline_color.rgb, outline_mask);
	float final_a = max(tex.a, outline_mask);

	COLOR = vec4(final_rgb, final_a) * COLOR;
}