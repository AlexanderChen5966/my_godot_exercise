# 由 PNG 的不透明像素算出 LightOccluder2D 用的多邊形（凸包，以圖片中心為原點、單位是貼圖像素）
# 用法：occluder_poly.py 圖檔.png [只取下面幾成，例如 0.5] [span]
# 加 span：改成逐列（每 8 列）取最左、最右的不透明像素連成外框，適合歪斜的柱子、燈桿（凸包會變成大三角形）
# 輸出 JSON：[[x, y], ...]，可直接轉成 PackedVector2Array（Sprite2D 預設 centered，放在 Sprite 底下就對齊）
import json, re, subprocess, sys

path = sys.argv[1]
bottom_ratio = float(sys.argv[2]) if len(sys.argv) > 2 else 1.0
txt = subprocess.run(["magick", path, "txt:-"], capture_output=True, text=True).stdout
w, h = map(int, re.match(r"# ImageMagick pixel enumeration: (\d+),(\d+)", txt).groups())
span = "span" in sys.argv[3:]
rows = {}
pts = set()
for line in txt.splitlines()[1:]:
    m = re.match(r"(\d+),(\d+): \(([^)]*)\)", line)
    if not m:
        continue
    x, y = int(m.group(1)), int(m.group(2))
    a = float(m.group(3).split(",")[-1])
    if a < 128 or y < h * (1 - bottom_ratio):
        continue
    lo, hi = rows.get(y, (x, x))
    rows[y] = (min(lo, x), max(hi, x + 1))
    for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
        pts.add((x + dx, y + dy))


if span:
    ys = sorted(rows)
    pick = ys[::8] + ([ys[-1]] if ys[-1] not in ys[::8] else [])
    right = [(rows[y][1], y) for y in pick]
    left = [(rows[y][0], y) for y in reversed(pick)]
    right[0] = (right[0][0], ys[0]); left[-1] = (left[-1][0], ys[0])
    right[-1] = (right[-1][0], ys[-1] + 1); left[0] = (left[0][0], ys[-1] + 1)
    poly = right + left
    # 去掉幾乎在同一直線上的點（誤差 1 像素內），點數少一點比較好讀也比較快
    def off_line(a, q, b):  # q 到 a–b 連線的距離
        dx, dy = b[0] - a[0], b[1] - a[1]
        return abs(dx * (q[1] - a[1]) - dy * (q[0] - a[0])) / max((dx * dx + dy * dy) ** 0.5, 1e-6)
    changed = True
    while changed and len(poly) > 4:
        changed = False
        for i in range(len(poly)):
            if off_line(poly[i - 1], poly[i], poly[(i + 1) % len(poly)]) < 1.0:
                del poly[i]
                changed = True
                break
    print(json.dumps([[x - w / 2, y - h / 2] for x, y in poly]))
    sys.exit()


def cross(o, a, b):
    return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])


p = sorted(pts)
lower, upper = [], []
for q in p:
    while len(lower) >= 2 and cross(lower[-2], lower[-1], q) <= 0:
        lower.pop()
    lower.append(q)
for q in reversed(p):
    while len(upper) >= 2 and cross(upper[-2], upper[-1], q) <= 0:
        upper.pop()
    upper.append(q)
hull = lower[:-1] + upper[:-1]
print(json.dumps([[x - w / 2, y - h / 2] for x, y in hull]))
