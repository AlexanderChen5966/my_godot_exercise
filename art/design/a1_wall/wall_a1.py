# A1-7 牆前（空房間、一道暖光照在牆上、極簡）：互動牆面（灰泥，取代灰色色塊，英文字仍用 Label 疊上）；
# 中景：空門框、一張倒下的椅子；地面：落滿灰泥粉塵的水泥地；近景：灰泥碎塊、一截炭筆；前景：牆角的暗邊
import random, sys
sys.path.insert(0, sys.argv[1])
from pix import Grid
R = random.Random(71)

# ── 互動牆面 150×135（螢幕 300×270，對應原本的色塊 -150..150、-330..-60）
P0, P1, P2, PD, PL = "#6A6558", "#767064", "#5E594E", "#46423A", "#8A8474"
w = Grid(150, 135)
w.rect(0, 0, 149, 134, P1)
for _ in range(1600):                                               # 灰泥的斑駁
    x, y = R.randrange(150), R.randrange(135)
    w.put(x, y, R.choice((P0, P2, P1, PL)))
for (cx, cy, rx, ry) in ((22, 22, 16, 10), (126, 108, 18, 13), (132, 20, 10, 7)):   # 剝落露出的磚（一排排、交錯）
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            d = ((x - cx) / (rx + 0.5)) ** 2 + ((y - cy) / (ry + 0.5)) ** 2 + R.random() * 0.25
            if d <= 1:
                row = (y - cy + ry) // 4
                joint = (y % 4 == 0) or ((x + (row % 2) * 5) % 10 == 0)
                w.put(x, y, "#3E2A20" if joint else R.choice(("#6A4434", "#5E3C2E", "#724A38")))
            elif d <= 1.25:
                w.put(x, y, PD)                                     # 剝落邊緣的陰影
for (x0, y0, n) in ((60, 0, 40), (100, 134, -50), (10, 80, 30)):    # 裂縫
    xx = x0
    for i in range(abs(n)):
        y = y0 + (i if n > 0 else -i)
        w.put(xx, y, PD)
        if R.random() < 0.35:
            xx += R.choice((-1, 1))
for (x, y) in ((112, 70), (116, 64), (120, 72), (108, 76)):         # 手印（之前按在牆上的痕跡）
    w.rect(x, y, x + 2, y + 6, "#5A4E44")
w.rect(104, 74, 116, 84, "#5A4E44")
import math
for x in range(0, 150):                                             # 四周不規則（像從牆上的燈光裡浮出來，不是方塊）
    t = int(5 + 4 * math.sin(x / 9) + R.randint(0, 2))
    b = int(5 + 4 * math.sin(x / 7 + 2) + R.randint(0, 2))
    for y in range(0, t):
        w.put(x, y, None)
    for y in range(134 - b, 135):
        w.put(x, y, None)
for y in range(0, 135):
    l = int(4 + 3 * math.sin(y / 8) + R.randint(0, 2))
    r = int(4 + 3 * math.sin(y / 6 + 1) + R.randint(0, 2))
    for x in range(0, l):
        w.put(x, y, None)
    for x in range(149 - r, 150):
        w.put(x, y, None)
w.save_txt("wall_plaster.txt", outline=False)

# ── 中景：空門框 70×180、倒下的椅子 36×30
M0, M1, M2, RIM = "#16130F", "#1F1A15", "#29221B", "#5A4630"
d = Grid(70, 180)
d.rect(0, 0, 69, 179, M1)
d.rect(12, 16, 57, 179, None)                                       # 門洞
d.vline(11, 16, 179, RIM); d.hline(11, 58, 15, RIM)
d.rect(58, 16, 62, 179, M0)                                         # 門框內側的陰影
d.save_txt("wall_mid_doorway.txt", outline=False)
c = Grid(36, 30)
c.rect(2, 18, 30, 21, M2); c.hline(2, 30, 18, RIM)                  # 座面（側倒）
c.rect(26, 2, 29, 17, M1)                                           # 椅背朝上
for (x0, y0, x1, y1) in ((4, 22, 0, 29), (28, 22, 34, 29)):
    c.line(x0, y0, x1, y1, M1)
c.save_txt("wall_mid_chair.txt", outline=False)

# ── 地面 128×64：水泥地＋灰泥粉塵（靠牆的地方比較多）
g = Grid(128, 64)
g.rect(0, 0, 127, 63, "#2C2A26")
g.rect(0, 0, 127, 3, "#3A3732"); g.hline(0, 127, 4, "#1E1C19")
for _ in range(500):
    x, y = R.randrange(128), R.randrange(5, 64)
    p = 1.0 - y / 64
    g.put(x, y, "#4A4740" if R.random() < p * 0.6 else R.choice(("#33302B", "#26241F")))
for cx in (40, 100):
    xx = cx
    for y in range(5, 64):
        g.put(xx, y, "#1A1815")
        if R.random() < 0.3:
            xx += R.choice((-1, 1))
g.save_txt("wall_ground.txt", outline=False)

# ── 近景：灰泥碎塊 32×9、一截炭筆 16×5
n = Grid(32, 9)
for (cx, cy, rx, ry) in ((6, 6, 5, 2), (16, 5, 4, 3), (26, 7, 4, 1)):
    n.ellipse(cx, cy, rx, ry, P0); n.hline(cx - rx + 1, cx + rx - 1, cy - ry, PL)
n.save_txt("wall_near_plaster.txt")
k = Grid(16, 5)
k.rect(1, 2, 12, 3, "#1A1816"); k.hline(1, 12, 2, "#2E2B28"); k.put(13, 2, "#0E0D0C")
for (x, y) in ((14, 4), (15, 3)):
    k.put(x, y, "#3A3632")
k.save_txt("wall_near_charcoal.txt")

# ── 前景：牆角的暗邊 70×384
F1, FR = "#0E0C0A", "#3A2C1E"
f = Grid(70, 384)
import math
for y in range(384):
    r = 50 + int(8 * math.sin(y / 60)) + (6 if y > 300 else 0)
    f.hline(0, r, y, F1); f.put(r, y, FR)
f.save_txt("wall_front_edge.txt", outline=False)
print("ok")
