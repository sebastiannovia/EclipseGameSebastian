shader_type canvas_item;
render_mode unshaded;

varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec4 artwork = texture(TEXTURE, UV);
	// Remove only the generated sheet's faint background halo; preserve its RGB.
	if (artwork.a < 0.47) {
		discard;
	}
	COLOR = vec4(artwork.rgb, 1.0) * sprite_tint;
}
