
shader_type canvas_item;
render_mode unshaded;

uniform float blur_radius : hint_range(0.0, 8.0, 0.05) = 7.0;

float gaussian_weight(int offset) {
	int distance = abs(offset);
	if (distance == 0) {
		return 6.0;
	}
	if (distance == 1) {
		return 4.0;
	}
	return 1.0;
}

void fragment() {
	vec2 texel_step = TEXTURE_PIXEL_SIZE * blur_radius;
	vec4 result = vec4(0.0);
	float weight_sum = 0.0;

	// 5x5 separable Gaussian weights: [1, 4, 6, 4, 1] per axis.
	for (int y = -2; y <= 2; y++) {
		float wy = gaussian_weight(y);
		for (int x = -2; x <= 2; x++) {
			float weight = wy * gaussian_weight(x);
			vec2 offset = vec2(float(x), float(y)) * texel_step;
			result += texture(TEXTURE, UV + offset) * weight;
			weight_sum += weight;
		}
	}

	COLOR = result / weight_sum;
}
