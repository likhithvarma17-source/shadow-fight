shader_type canvas_item;

uniform float rewind_phase : hint_range(0.0, 1.0) = 0.0;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.75;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 cell = floor(UV * vec2(320.0, 180.0));
	float tick = floor(TIME * 32.0 + rewind_phase * 97.0);
	float grain = hash21(cell + vec2(tick, -tick));
	float line_id = floor(UV.y * 240.0);
	float line_noise = hash21(vec2(line_id, tick));
	float scan = smoothstep(0.76, 1.0, line_noise) * smoothstep(0.18, 0.0, abs(fract(UV.y * 240.0) - 0.5));
	float tear_center = hash21(vec2(floor(tick * 0.35), 19.0));
	float tear = smoothstep(0.018, 0.0, abs(UV.y - tear_center)) * hash21(vec2(line_id, tick + 11.0));
	float static_alpha = (0.025 + grain * 0.13 + scan * 0.28 + tear * 0.22) * noise_strength;
	vec3 signal_color = mix(vec3(0.68, 0.86, 0.89), vec3(0.94, 1.0, 1.0), grain);
	COLOR = vec4(signal_color, static_alpha);
}
