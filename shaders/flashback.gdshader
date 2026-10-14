// A5 記憶閃回：原插畫加上褪色、跳動的雜訊、暗角（作者選 A）。
// 備案 B（舊底片）：saturation 0.12、tint_amount 0.2、grain 0.22、scanlines 0.35、chroma_px 2。
shader_type canvas_item;

uniform float saturation : hint_range(0.0, 1.0) = 0.35;      // 飽和度（1 = 原圖）
uniform vec4 tint : source_color = vec4(0.63, 0.47, 0.28, 1.0); // 褪色時偏向的暖色
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;
uniform float black_lift : hint_range(0.0, 0.3) = 0.06;      // 黑色提亮（褪色感）
uniform float white_cut : hint_range(0.7, 1.0) = 0.96;       // 白色壓低
uniform float grain : hint_range(0.0, 0.5) = 0.10;           // 雜訊強度
uniform float grain_fps = 24.0;                              // 雜訊每秒換幾次
uniform float vignette : hint_range(0.0, 1.0) = 0.55;        // 暗角（四角剩多少亮度的反向）
uniform float scanlines : hint_range(0.0, 1.0) = 0.0;        // 掃描線（B）
uniform float chroma_px = 0.0;                               // 紅色往右偏幾 px（B）

// 不用 sin 的雜湊（Dave Hoskins hash12）：sin 版在 Compatibility 渲染器的精度下會出現斜向的規則紋路
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	vec4 c = texture(TEXTURE, UV);
	if (chroma_px > 0.0) {
		c.r = max(c.r, texture(TEXTURE, UV - vec2(chroma_px * px.x, 0.0)).r);
	}
	float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(vec3(gray), c.rgb, saturation);
	col = mix(col, gray * tint.rgb * 1.6, tint_amount);
	col = mix(vec3(black_lift), vec3(white_cut), col);
	float t = mod(floor(TIME * grain_fps), 97.0);  // 數字保持小，精度才夠
	float n = hash(floor(FRAGCOORD.xy) + vec2(t * 37.0, t * 17.0)) - 0.5;
	col += n * grain;
	if (scanlines > 0.0) {
		col *= 1.0 - scanlines * step(2.0, mod(FRAGCOORD.y, 3.0));
	}
	vec2 d = UV - 0.5;
	float v = 1.0 - smoothstep(0.25, 0.85, length(d * vec2(1.15, 1.0))) * vignette;
	COLOR = vec4(col * v, c.a * COLOR.a);
}
