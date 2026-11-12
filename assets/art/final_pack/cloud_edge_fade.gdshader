shader_type canvas_item;

void fragment() {
	vec4 pixel = texture(TEXTURE, UV) * COLOR;
	float edge_fade = smoothstep(0.0, 0.035, UV.x) * smoothstep(0.0, 0.035, 1.0 - UV.x);
	pixel.a *= edge_fade;
	COLOR = pixel;
}
