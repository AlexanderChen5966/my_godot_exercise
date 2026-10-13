// A2-3 光束：從上方斜射下來的光（疊加混色、不受燈光影響）。
// 掛在 ColorRect 上：UV.y＝0 是光源那一端，用 rotation 調整角度；寬度從 top_width 漸變到 bottom_width（佔 rect 寬度的比例）。
shader_type canvas_item;
render_mode blend_add, unshaded;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 beam_color : source_color = vec4(1.0, 0.9, 0.7, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.25;
uniform float top_width : hint_range(0.0, 1.0) = 0.35;
uniform float bottom_width : hint_range(0.0, 1.0) = 0.9;
uniform float edge_soft : hint_range(0.0, 0.5) = 0.3;
uniform float start_fade : hint_range(0.0, 1.0) = 0.2;
uniform float length_fade : hint_range(0.0, 1.0) = 0.5;
uniform float shimmer : hint_range(0.0, 1.0) = 0.6;
uniform vec2 rect_size = vec2(300.0, 500.0);
uniform float pixel_size = 4.0;

void fragment() {
	vec2 uv = floor(UV * rect_size / pixel_size) * pixel_size / rect_size;
	float half_w = mix(top_width, bottom_width, uv.y) * 0.5;
	float d = abs(uv.x - 0.5);
	float side = 1.0 - smoothstep(half_w - edge_soft * half_w * 2.0, half_w, d);
	float along = smoothstep(0.0, start_fade, uv.y) * (1.0 - smoothstep(1.0 - length_fade, 1.0, uv.y));
	// 沿著光束方向的條紋，緩慢變化
	float streak = texture(noise_tex, vec2((uv.x - 0.5) / max(half_w, 0.01) * 0.6 + TIME * 0.01, uv.y * 0.05)).r;
	float a = side * along * intensity * mix(1.0, 0.4 + streak * 1.2, shimmer);
	a = floor(a * 16.0) / 16.0;
	COLOR = vec4(beam_color.rgb * a, a);
}
