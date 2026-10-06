shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float outline_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(1.0, 0.6, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 8.0) = 2.0;

uniform vec2 frame_size = vec2(32.0, 32.0);

void fragment() {
	// COLOR ya contiene texture * modulate
	// Sampleamos la textura cruda solo para chequear el alpha de los vecinos
	vec4 tex_raw = texture(TEXTURE, UV);
	vec2 texel = 1.0 / frame_size;

	// --- Outline: alpha máximo de los 8 vecinos ---
	float neighbor_alpha = 0.0;
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(-outline_width, 0.0) * texel).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2( outline_width, 0.0) * texel).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(0.0, -outline_width) * texel).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(0.0,  outline_width) * texel).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(-outline_width, -outline_width) * texel).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2( outline_width, -outline_width) * texel).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(-outline_width,  outline_width) * texel).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2( outline_width,  outline_width) * texel).a);

	// Máscara de outline: pixel transparente + algún vecino opaco
	float outline_mask = (1.0 - tex_raw.a) * step(0.01, neighbor_alpha) * outline_amount;

	// Flash: mezclar el COLOR actual con el color del flash
	// (COLOR ya tiene texture * modulate, así que respeta el modulate del nodo)
	vec3 flash_rgb = mix(COLOR.rgb, flash_color.rgb, flash_amount);

	// Componer outline encima
	vec3 final_rgb = mix(flash_rgb, outline_color.rgb, outline_mask);
	float final_a = max(COLOR.a, outline_mask);

	COLOR = vec4(final_rgb, final_a);
}