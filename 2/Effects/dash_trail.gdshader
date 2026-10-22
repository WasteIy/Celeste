shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	float a = textureLod(screen_texture, SCREEN_UV, 0.0).a;
	COLOR = vec4(tint.rgb, step(0.01, a) * tint.a);
}
