# A3 第 1、2 組：燃燒的車、火桶的火焰 4 格循環（設計圖）
# 輸出 car_f0..3.txt（120x44）、barrel_f0..3.txt（22x34）與預覽 PNG
import sys, subprocess, re, math, random
sys.path.insert(0, "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/art/tools")
from pix import Grid

ROOT = "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/"
OUTDIR = sys.argv[1]


def load(p):
    t = subprocess.run(["magick", p, "txt:-"], capture_output=True, text=True).stdout
    w, h = map(int, re.match(r"# ImageMagick pixel enumeration: (\d+),(\d+)", t).groups())
    g = [[None] * w for _ in range(h)]
    for l in t.splitlines()[1:]:
        m = re.match(r"(\d+),(\d+):.*#([0-9A-F]{8})", l)
        x, y, c = int(m[1]), int(m[2]), m[3]
        g[y][x] = None if c.endswith("00") else "#" + c[:6]
    return w, h, g


def flame(grid, cols, base_y, f, pal, seed, under=None):
    """cols: {x: 原本的高度}；pal: (外圍紅, 中間橘, 核心黃)。每格的高度像波浪一樣起伏。"""
    red, ora, yel = pal
    xs = sorted(cols)
    cx = (xs[0] + xs[-1]) / 2
    half = max((xs[-1] - xs[0]) / 2, 1)
    rnd = random.Random(seed * 10 + f)
    tops = {}
    for x in xs:
        wave = math.sin(x * 0.8 + f * math.pi / 2 + seed) * 0.5 + math.sin(x * 0.37 - f * math.pi / 2) * 0.3
        h = max(1, round(cols[x] * (0.82 + 0.22 * wave)))
        tops[x] = base_y - h + 1
    for x in xs:
        h = base_y - tops[x] + 1
        for y in range(tops[x], base_y + 1):
            from_top = y - tops[x]
            # 左右邊緣（隔壁欄在這一列沒有火）＝紅色外圈，跟原圖一樣
            edge = tops.get(x - 1, base_y + 1) > y or tops.get(x + 1, base_y + 1) > y
            core = abs(x - cx) / half < 0.35 and y > base_y - h * 0.4 and not edge
            c = yel if core else (red if edge or from_top < 2 else ora)
            grid.put(x, y, c)
    # 斷開的火星：1～2 顆，在火焰上方
    for _ in range(rnd.choice([1, 2])):
        x = rnd.choice(xs[1:-1])
        y = tops[x] - rnd.choice([2, 3, 4])
        if y >= 0 and (under is None or under(x, y) is None):
            grid.put(x, y, rnd.choice([red, ora]))
    return tops


# ---- 燃燒的車 ----
w, h, car = load(ROOT + "assets/sprites/props/burnt_car.png")
FL = {"#D8502A", "#FF9A3C", "#FFD27A"}
CAR_PAL = ("#D8502A", "#FF9A3C", "#FFD27A")


def car_under(x, y):
    """火焰底下原本的顏色：引擎蓋上的火是透明；車窗裡的火往右找第一個不是火的像素"""
    if x < 30:
        return None
    for xx in range(x + 1, w):
        c = car[y][xx]
        if c not in FL:
            return c
    return None


base = Grid(w, h)
hood, cabin = {}, {}
for y in range(h):
    for x in range(w):
        c = car[y][x]
        if c in FL:
            base.put(x, y, car_under(x, y))
            (hood if x < 30 else cabin).setdefault(x, [y, y])
            d = hood if x < 30 else cabin
            d[x][0] = min(d[x][0], y)
            d[x][1] = max(d[x][1], y)
        else:
            base.put(x, y, c)
HOOD_BASE = max(v[1] for v in hood.values())
CABIN_BASE = max(v[1] for v in cabin.values())
hood_h = {x: HOOD_BASE - v[0] + 1 for x, v in hood.items()}
cabin_h = {x: CABIN_BASE - v[0] + 1 for x, v in cabin.items()}

for f in range(4):
    g = Grid(w, h)
    g.g = [row[:] for row in base.g]
    flame(g, hood_h, HOOD_BASE, f, CAR_PAL, 1)
    flame(g, cabin_h, CABIN_BASE, f, CAR_PAL, 2, under=lambda x, y: None)
    g.save_txt(f"{OUTDIR}/car_f{f}.txt", outline=False)

# ---- 火桶 ----
bw, bh, barrel = load(ROOT + "assets/sprites/layers/ruins_mid_firebarrel.png")
RIM = 12  # 桶口那一列
BAR_PAL = ("#C84818", "#F08030", "#F0C060")
BAR_DEEP = "#E86020"
bcols = {}
for y in range(RIM):
    for x in range(bw):
        if barrel[y][x] is not None and barrel[y][x] != "#16181C":
            bcols.setdefault(x, RIM)
            bcols[x] = min(bcols[x], y)
bheights = {x: RIM - top for x, top in bcols.items()}
for f in range(4):
    g = Grid(bw, bh)
    for y in range(RIM, bh):
        for x in range(bw):
            g.put(x, y, barrel[y][x])
    tops = flame(g, bheights, RIM - 1, f, BAR_PAL, 3)
    # 中間加一層深橘，讓 5 種顏色都用到、和原圖的層次一樣
    for x, top in tops.items():
        y = top + 1
        if g.get(x, y) == "#F08030":
            g.put(x, y, BAR_DEEP)
    g.no_outline = set()
    # 只替火焰加外框（桶身原本就有外框）
    px = g.outlined()
    for y in range(RIM, bh):
        for x in range(bw):
            px[y][x] = barrel[y][x]
    g.g = px
    g.save_txt(f"{OUTDIR}/barrel_f{f}.txt", outline=False)
print("hood", HOOD_BASE, sorted(hood_h.items())[:3], "cabin", CABIN_BASE, "barrel cols", sorted(bheights.items()))
