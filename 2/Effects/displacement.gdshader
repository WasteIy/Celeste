shader_type canvas_item;
render_mode unshaded;

const int MAX_BURSTS = 8;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D circle : filter_linear, repeat_disable;
uniform vec2 screen_size = vec2(320.0, 180.0);
uniform float strength = 12.0;
uniform int count = 0;
uniform vec4 bursts[MAX_BURSTS];

void fragment() {
	vec2 px = SCREEN_UV * screen_size;
	vec2 offset = vec2(0.0);
	for (int i = 0; i < MAX_BURSTS; i++) {
		if (i >= count) {
			break;
		}
		vec4 b = bursts[i];
		vec2 uv = (px - b.xy) / (2.0 * b.z) + 0.5;
		if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
			continue;
		}
		vec4 t = texture(circle, uv);
		offset += (t.rg * 2.0 - 1.0) * b.w;
	}
	vec2 uv = SCREEN_UV - offset * strength / screen_size;
	COLOR = textureLod(screen_texture, uv, 0.0);
}
