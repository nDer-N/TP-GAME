shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.05, 0.1, 0.25, 1.0);
uniform vec4 glow_color : source_color = vec4(0.4, 0.9, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float scale = 0.02;        // tamaño del patrón (más grande = rayos más pequeños)
uniform float speed = 0.6;         // velocidad de movimiento
uniform float line_width = 0.06;   // grosor de los rayos
uniform float glow_amount = 2.0;   // intensidad del brillo
uniform float flicker_speed = 12.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

float bolt(vec2 p, float t) {
	float n = fbm(p + vec2(t, -t * 0.7));
	float d = abs(n - 0.5);
	return 1.0 - smoothstep(0.0, line_width, d);
}

void fragment() {
	vec2 p = world_pos * scale;

	float b1 = bolt(p, TIME * speed);
	float b2 = bolt(p * 1.7 + 10.0, -TIME * speed * 1.3);
	float bolts = clamp(b1 + b2 * 0.7, 0.0, 1.0);

	float flicker = 0.75 + 0.25 * sin(TIME * flicker_speed + noise(p * 3.0) * 6.28);

	vec3 col = base_color.rgb;
	col += glow_color.rgb * bolts * glow_amount * flicker;
	col = mix(col, core_color.rgb, pow(bolts, 4.0) * flicker);

	COLOR = vec4(col, 1.0);
}