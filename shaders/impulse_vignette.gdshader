// 衝動機制的紅色暈影：畫面四周泛紅，強度越高紅色越往中間擴散。由 scripts/impulse_fx.gd 設定參數。
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.55, 0.0, 0.02, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;  // 0 = 沒有感覺，1 = 最強
uniform float max_alpha : hint_range(0.0, 1.0) = 0.6;  // 最強時四周的不透明度
uniform float pulse : hint_range(0.0, 1.0) = 0.0;      // 心跳時短暫變紅

void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.5, 1.0);               // 3:2 畫面，橫向拉長，暈影是橢圓
	float d = length(p);
	float inner = mix(0.62, 0.22, intensity);           // 越強，紅色從越靠中間開始
	float edge = smoothstep(inner, 0.95, d);
	float alpha = edge * intensity * max_alpha * (1.0 + pulse * 0.35);
	COLOR = vec4(tint.rgb, clamp(alpha, 0.0, 1.0));
}
