# 算出要補的像素：patch.py 設計.txt 匯出.png → draw_pixels 用的 JSON（設計圖在差異格的顏色）
import sys, subprocess, json
def load(lines):
    d = {}
    for l in lines:
        if l.startswith("#"):
            continue
        p = l.split()
        if len(p) < 3:
            continue
        c = p[2] + ("FF" if len(p[2]) == 7 else "")
        d[p[0].rstrip(":")] = "#00000000" if c.endswith("00") else c
    return d
a = load(open(sys.argv[1]).read().splitlines())
b = load(subprocess.run(["magick", sys.argv[2], "txt:-"], capture_output=True, text=True).stdout.splitlines())
print(json.dumps([{"x": int(k.split(",")[0]), "y": int(k.split(",")[1]), "color": v} for k, v in a.items() if b.get(k) != v]))
