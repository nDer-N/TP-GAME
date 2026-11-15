shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float outline_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(1.0, 0.6, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 800.0) = 1.5;

void fragment() {
	// Sampleamos la textura cruda solo para el alpha del outline
	vec4 tex_raw = texture(TEXTURE, UV);
	vec2 texel = 1.0 / vec2(textureSize(TEXTURE, 0));

	// --- Outline (8 vecinos) ---
	float neighbor_alpha = 0.0;
	neighbor_alpha += texture(TEXTURE, UV + vec2(-outline_width, 0.0) * texel).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2( outline_width, 0.0) * texel).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2(0.0, -outline_width) * texel).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2(0.0,  outline_width) * texel).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2(-outline_width, -outline_width) * texel).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2( outline_width, -outline_width) * texel).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2(-outline_width,  outline_width) * texel).a;
	neighbor_alpha += texture(TEXTURE, UV + vec2( outline_width,  outline_width) * texel).a;
	neighbor_alpha = clamp(neighbor_alpha, 0.0, 1.0);

	float outline_mask = (1.0 - tex_raw.a) * step(0.01, neighbor_alpha) * outline_amount;

	// Usamos COLOR.rgb (que ya tiene la textura y el modulate aplicado)
	vec3 flash_rgb = mix(COLOR.rgb, flash_color.rgb, flash_amount);
	vec3 final_rgb = mix(flash_rgb, outline_color.rgb, outline_mask);
	float final_a = max(COLOR.a, outline_mask);

	// Asignamos directamente, SIN multiplicar por COLOR de nuevo
	COLOR = vec4(final_rgb, final_a);
}