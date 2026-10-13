// A2-3 霧：中景與遊戲層之間緩慢流動的一層霧（兩層 noise 反向捲動），上下邊緣淡出。
// 掛在 FogLayer/Fog（ColorRect）上，rect_size 要填 ColorRect 的大小，pixel_size 讓霧也有像素感。
shader_type canvas_item;
// 受燈光影響：暗處幾乎看不見，被燈光照到的地方才浮現（跟灰塵一樣）

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 fog_color : source_color = vec4(0.75, 0.75, 0.8, 1.0);
uniform float density : hint_range(0.0, 1.0) = 0.25;
uniform vec2 speed = vec2(0.006, 0.0015);
uniform vec2 noise_scale = vec2(2.0, 1.0);
uniform float top_fade : hint_range(0.0, 1.0) = 0.45;
uniform float bottom_fade : hint_range(0.0, 1.0) = 0.15;
uniform vec2 rect_size = vec2(2304.0, 380.0);
uniform float pixel_size = 4.0;

void fragment() {
	vec2 uv = floor(UV * rect_size / pixel_size) * pixel_size / rect_size;
	float n1 = texture(noise_tex, uv * noise_scale + TIME * speed).r;
	float n2 = texture(noise_tex, uv * noise_scale * 1.7 + vec2(0.37, 0.61) - TIME * speed * 1.3).r;
	float n = smoothstep(0.25, 0.9, n1 * 0.6 + n2 * 0.4);
	float edge = smoothstep(0.0, top_fade, uv.y) * (1.0 - smoothstep(1.0 - bottom_fade, 1.0, uv.y));
	// 透明度分成幾階，避免平滑漸層破壞像素風
	float a = floor(n * edge * density * 24.0) / 24.0;
	COLOR = vec4(fog_color.rgb, a);
}
