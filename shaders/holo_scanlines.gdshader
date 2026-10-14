shader_type canvas_item;

uniform vec4 color : source_color = vec4(0.2, 0.9, 1.0, 0.25);
uniform float linea_densidad = 80.0;
uniform float velocidad = 0.5;

void fragment() {
	float scan = sin((UV.y + TIME * velocidad) * linea_densidad) * 0.5 + 0.5;
	COLOR = vec4(color.rgb, color.a * (0.6 + scan * 0.4));
}