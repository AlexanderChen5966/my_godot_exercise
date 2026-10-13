# A3 第 2 組：停車場燈管 亮／熄 2 格（設計圖）
# 熄滅格：左邊燈管的兩種亮色換成右邊那根（本來就壞的）的顏色。輸出 lamp_f0.txt、lamp_f1.txt
# 用法：python3 lamp.py 輸出資料夾
import sys, subprocess, re
ROOT = "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/"
OUTDIR = sys.argv[1]
t = subprocess.run(["magick", ROOT + "assets/sprites/props/lamp.png", "txt:-"], capture_output=True, text=True).stdout
w, h = map(int, re.match(r"# ImageMagick pixel enumeration: (\d+),(\d+)", t).groups())
OFF = {"A9D8E6": "5F6E74", "E6FAFF": "7C8D93"}
for f in (0, 1):
    out = [f"# ImageMagick pixel enumeration: {w},{h},255,srgba"]
    for l in t.splitlines()[1:]:
        m = re.match(r"(\d+),(\d+):.*#([0-9A-F]{8})", l)
        x, y, c = int(m[1]), int(m[2]), m[3]
        if f == 1 and c[:6] in OFF:
            c = OFF[c[:6]] + "FF"
        r, g, b, a = (int(c[i:i + 2], 16) for i in (0, 2, 4, 6))
        out.append(f"{x},{y}: ({r},{g},{b},{a})  #{c}  srgba({r},{g},{b},{a / 255:.4f})")
    open(f"{OUTDIR}/lamp_f{f}.txt", "w").write("\n".join(out) + "\n")
