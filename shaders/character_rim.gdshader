shader_type canvas_item;
render_mode unshaded;

uniform vec4 key_color : source_color = vec4(0.30, 1.0, 0.96, 1.0);
uniform vec4 bounce_color : source_color = vec4(1.0, 0.24, 0.60, 0.84);
uniform float outline_width = 4.2;
uniform float inner_strength = 0.68;
uniform float outer_strength = 1.0;
uniform float rim_brightness = 1.0;
uniform float flip_sign = 1.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * outline_width;
	float left_a = texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
	float right_a = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	float up_a = texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	float down_a = texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	float upper_left_a = texture(TEXTURE, UV - px).a;
	float lower_right_a = texture(TEXTURE, UV + px).a;
	float neighbor_max = max(max(left_a, right_a), max(max(up_a, down_a), max(upper_left_a, lower_right_a)));
	float neighbor_min = min(min(left_a, right_a), min(min(up_a, down_a), min(upper_left_a, lower_right_a)));
	float outer_rim = max(0.0, neighbor_max - source.a) * outer_strength;
	float inner_rim = source.a * (1.0 - neighbor_min) * inner_strength;
	float light_side = smoothstep(-0.28, 0.32, (UV.x - 0.5) * flip_sign);
	float upper_boost = mix(1.12, 0.88, smoothstep(0.12, 0.92, UV.y));
	vec3 rim_rgb = mix(key_color.rgb, bounce_color.rgb, light_side);
	float rim_alpha = clamp((outer_rim + inner_rim) * upper_boost, 0.0, 1.0);
	float color_alpha = mix(key_color.a, bounce_color.a, light_side);
	float tuned_brightness = clamp(rim_brightness, 0.0, 1.5);
	float color_gain = mix(0.65, 1.25, tuned_brightness / 1.5);
	COLOR = vec4(rim_rgb * color_gain, clamp(rim_alpha * color_alpha * tuned_brightness, 0.0, 1.0) * COLOR.a);
}
