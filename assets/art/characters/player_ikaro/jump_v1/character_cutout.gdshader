shader_type canvas_item;
render_mode unshaded;
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	if (pixel.a < 0.47) {
		discard;
	}
	COLOR = vec4(pixel.rgb, 1.0) * sprite_tint;
}
