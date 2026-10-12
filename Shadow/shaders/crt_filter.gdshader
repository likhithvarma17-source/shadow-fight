shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;
uniform vec2 virtual_resolution = vec2(800.0, 450.0);
uniform float curvature = 0.012;
uniform float chromatic_aberration = 0.55;
uniform float scanline_strength = 0.085;
uniform float mask_strength = 0.05;
uniform float noise_strength = 0.015;
uniform float vignette_strength = 0.18;
uniform float saturation = 1.08;
uniform float brightness = 1.08;

float random_noise(vec2 point) {
	return fract(sin(dot(point, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 centered = SCREEN_UV * 2.0 - 1.0;
	vec2 warped = centered * (1.0 + curvature * dot(centered, centered));
	vec2 uv = warped * 0.5 + 0.5;
	float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);

	vec2 pixel_uv = (floor(uv * virtual_resolution) + 0.5) / virtual_resolution;
	vec2 color_shift = vec2(SCREEN_PIXEL_SIZE.x * chromatic_aberration, 0.0);
	vec3 color;
	color.r = texture(screen_texture, pixel_uv + color_shift).r;
	color.g = texture(screen_texture, pixel_uv).g;
	color.b = texture(screen_texture, pixel_uv - color_shift).b;

	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(luma), color, saturation);
	float scanline = 1.0 - scanline_strength * (0.5 + 0.5 * sin(FRAGCOORD.y * 3.14159265));
	float triad = mod(floor(FRAGCOORD.x), 3.0);
	vec3 mask = vec3(1.0 - mask_strength);
	mask.r += mask_strength * step(triad, 0.5);
	mask.g += mask_strength * step(0.5, triad) * step(triad, 1.5);
	mask.b += mask_strength * step(1.5, triad);
	float grain = (random_noise(floor(FRAGCOORD.xy) + floor(TIME * 24.0)) - 0.5) * noise_strength;
	float flicker = 0.992 + 0.008 * sin(TIME * 47.0);
	vec2 edge = abs(centered);
	float vignette = clamp(1.0 - vignette_strength * pow(max(edge.x, edge.y), 2.15), 0.55, 1.0);
	color = (color * scanline * mask + grain) * vignette * flicker * brightness;

	COLOR = vec4(max(color, vec3(0.0)) * inside, 1.0);
}
