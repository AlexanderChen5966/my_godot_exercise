# 從像素圖自動產生 2D 法線貼圖（A2）：normal_map.py 輸入.png 輸出.png [凸度]
# 高度 = 離透明邊緣的距離（最多 3 格）＋一點亮度；法線由左右、上下的高度差算出（OpenGL 慣例，綠色朝上）。
import sys, subprocess, math
src, dst = sys.argv[1], sys.argv[2]
k = float(sys.argv[3]) if len(sys.argv) > 3 else 1.6
txt = subprocess.run(["magick", src, "txt:-"], capture_output=True, text=True).stdout.splitlines()
w, h = map(int, txt[0].split(":")[1].split(",")[:2])
a = [[0] * w for _ in range(h)]
lum = [[0.0] * w for _ in range(h)]
for line in txt[1:]:
    xy, rest = line.split(":", 1)
    x, y = map(int, xy.split(","))
    vals = rest.split("(")[1].split(")")[0].split(",")
    r, g, b = (float(v) for v in vals[:3])
    al = float(vals[3]) if len(vals) > 3 else 255.0
    if al > 1:   # srgba(…, 0.5) 或 (…, 128) 兩種寫法
        al = al / 255.0 if al > 1.0 else al
    a[y][x] = 1 if al > 0.5 else 0
    lum[y][x] = (0.3 * r + 0.59 * g + 0.11 * b) / 255.0
dist = [[0] * w for _ in range(h)]                       # 離透明的距離（曼哈頓，最多 3）
for y in range(h):
    for x in range(w):
        if not a[y][x]:
            continue
        d = 3
        for r_ in range(1, 4):
            hit = False
            for dx in range(-r_, r_ + 1):
                dy = r_ - abs(dx)
                for sy in (dy, -dy):
                    xx, yy = x + dx, y + sy
                    if not (0 <= xx < w and 0 <= yy < h) or not a[yy][xx]:
                        hit = True
            if hit:
                d = r_
                break
        dist[y][x] = d
def H(x, y):
    if not (0 <= x < w and 0 <= y < h) or not a[y][x]:
        return 0.0
    return dist[y][x] / 3.0 + 0.25 * lum[y][x]
out = ["# ImageMagick pixel enumeration: %d,%d,255,srgba" % (w, h)]
for y in range(h):
    for x in range(w):
        if not a[y][x]:
            out.append("%d,%d: (128,128,255,0)" % (x, y))
            continue
        nx = (H(x - 1, y) - H(x + 1, y)) * k
        ny = (H(x, y + 1) - H(x, y - 1)) * k     # 往上變低（上緣）→ 法線朝上（綠色 > 128）
        nz = 1.0
        l = math.sqrt(nx * nx + ny * ny + nz * nz)
        c = [int(round((v / l * 0.5 + 0.5) * 255)) for v in (nx, ny, nz)]
        out.append("%d,%d: (%d,%d,%d,255)" % (x, y, *c))
open("/tmp/_normal.txt", "w").write("\n".join(out) + "\n")
subprocess.run(["magick", "/tmp/_normal.txt", "PNG32:" + dst], check=True)
print("ok", w, h)
