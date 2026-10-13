# A1-6 舊家（廢棄的公寓客廳、暖色木頭、昏暗）：中景破沙發、傾斜的書櫃、餐桌椅、壞掉的立燈、歪掛的全家福；
# 地面：踢腳板＋木地板；近景：散落的蠟筆、倒下的小熊、碎相框；前景：木門框、垂下的斷梁；選做：倒下的衣櫃（不能穿過）
import random, sys
sys.path.insert(0, sys.argv[1])
from pix import Grid
R = random.Random(61)
M0, M1, M2, MD, RIM = "#1A120E", "#241913", "#2E2118", "#120C09", "#6A4A28"

# ── 破沙發 110×44
s = Grid(110, 44)
s.rect(4, 14, 105, 34, M1); s.hline(4, 105, 14, RIM)                 # 椅背
s.rect(0, 24, 12, 38, M2); s.rect(97, 24, 109, 38, M2)              # 扶手
s.rect(10, 28, 99, 38, M2); s.hline(10, 99, 28, "#3A2A1E")           # 坐墊
for x in (40, 70):
    s.vline(x, 28, 38, MD)
s.rect(50, 18, 62, 24, MD); s.put(56, 25, "#5A4A3A")                 # 破洞露出的彈簧
s.rect(4, 39, 8, 43, MD); s.rect(101, 39, 105, 43, MD)               # 椅腳
s.save_txt("home_mid_sofa.txt", outline=False)

# ── 傾斜的書櫃 64×116（往右靠著牆）
b = Grid(64, 116)
for y in range(0, 116):
    x0 = 4 + (115 - y) * 12 // 115
    b.hline(x0, x0 + 42, y, M1); b.put(x0, y, RIM); b.put(x0 + 42, y, MD)
for sy in (20, 46, 72, 98):                                           # 層板與書
    for x in range(0, 64):
        if b.get(x, sy):
            b.put(x, sy, M2)
    x0 = 4 + (115 - sy) * 12 // 115
    for i in range(0, 34, 4):
        h = R.randint(10, 18)
        if R.random() < 0.75:
            col = R.choice(("#3A2018", "#2A2A3A", "#3A3020", "#2A3A2A"))
            for yy in range(sy - h, sy):
                xx = 4 + (115 - yy) * 12 // 115 + 4 + i
                b.put(xx, yy, col); b.put(xx + 1, yy, col)
b.save_txt("home_mid_shelf.txt", outline=False)

# ── 餐桌椅 96×46：桌子＋一張倒下的椅子
t = Grid(96, 46)
t.rect(10, 16, 70, 20, M2); t.hline(10, 70, 16, RIM)
t.rect(14, 21, 17, 45, M1); t.rect(63, 21, 66, 45, M1)
t.rect(22, 10, 40, 15, "#3A3028")                                     # 桌上的盤子與桌巾
t.rect(74, 0, 77, 30, M1); t.rect(74, 28, 92, 31, M2)                 # 椅子（立著）
t.rect(78, 32, 80, 45, M1); t.rect(88, 32, 90, 45, M1)
t.save_txt("home_mid_table.txt", outline=False)

# ── 壞掉的立燈 30×110：燈罩歪掉
l = Grid(30, 110)
l.vline(14, 20, 104, M2); l.vline(15, 20, 104, M1)
l.rect(6, 104, 23, 109, M1)
for y in range(4, 22):                                               # 歪掉的燈罩
    w = 4 + (y - 4) // 2
    l.hline(18 - w + (y - 4) // 3, 18 + w + (y - 4) // 3, y, "#3A2E22")
l.hline(10, 30, 21, RIM)
l.save_txt("home_mid_lamp.txt", outline=False)

# ── 歪掛的全家福 56×44：三個相框（一個掉了只剩釘子、一個歪掉）
f = Grid(56, 44)
def frame(x, y, w, h, tilt):
    for yy in range(h):
        sh = tilt * yy // h
        f.hline(x + sh, x + sh + w - 1, y + yy, "#5A4028")
    for yy in range(2, h - 2):
        sh = tilt * yy // h
        f.hline(x + sh + 2, x + sh + w - 3, y + yy, "#2A221C")
frame(2, 8, 18, 22, 0)
f.rect(6, 14, 8, 18, "#6A5848"); f.rect(12, 16, 14, 20, "#6A5848"); f.rect(9, 20, 11, 24, "#7A6858")  # 三個人影（爸爸、媽媽、女兒）
frame(26, 4, 14, 18, 3)
f.put(46, 10, "#8A8478"); f.put(46, 11, "#5A4028")                  # 掉了的相框只剩釘子
f.save_txt("home_mid_photos.txt")

# ── 地面 128×64：踢腳板＋木地板（橫向的木條、交錯的接縫，越往外木條越寬）
W0, W1, W2, WD = "#3A2A1E", "#44322A", "#33251A", "#221810"
g = Grid(128, 64)
g.rect(0, 0, 127, 4, "#2A1E16"); g.hline(0, 127, 0, "#4A3626")      # 踢腳板
rows = [5, 9, 14, 20, 27, 35, 44, 54, 64]
for r in range(len(rows) - 1):
    y0, y1 = rows[r], rows[r + 1]
    g.rect(0, y0, 127, y1 - 1, W0 if r % 2 else W1)
    g.hline(0, 127, y0, WD)
    off = (r * 37) % 64
    for x in range(off, 128 + off, 64):                               # 交錯的接縫
        g.vline(x % 128, y0, y1 - 1, WD)
    for _ in range(14):                                               # 木紋
        x = R.randrange(128); y = R.randrange(y0 + 1, y1)
        g.hline(x, min(127, x + R.randint(4, 12)), y, W2)
for _ in range(120):                                                  # 灰塵
    x, y = R.randrange(128), R.randrange(5, 64)
    g.put(x, y, R.choice(("#4E3E30", W2)))
g.ellipse(90, 46, 12, 4, "#2E2218")                                   # 水漬
g.save_txt("home_ground.txt", outline=False)

# ── 近景：散落的蠟筆 26×6、倒下的小熊 22×14、碎相框 30×8
c = Grid(26, 6)
for (x, y, col) in ((1, 3, "#C83020"), (6, 2, "#3A6AC0"), (11, 4, "#E8C030"), (16, 2, "#3AA050"), (21, 3, "#C83020")):
    c.hline(x, x + 3, y, col); c.put(x + 4, y, "#E8E0D0")
c.save_txt("home_near_crayons.txt")
bear = Grid(22, 14)
B1, B2 = "#7A5A3A", "#5A4028"
bear.ellipse(14, 9, 6, 4, B1); bear.ellipse(5, 9, 4, 4, B1)          # 身體、頭（側躺）
bear.ellipse(2, 5, 2, 2, B2); bear.ellipse(7, 5, 2, 2, B2)           # 耳朵
bear.put(4, 9, "#1A1210"); bear.ellipse(19, 12, 2, 1, B2); bear.ellipse(11, 12, 2, 1, B2)
bear.hline(12, 16, 7, "#8A6A48")
bear.save_txt("home_near_bear.txt")
p = Grid(30, 8)
p.rect(2, 3, 16, 7, "#5A4028"); p.rect(4, 4, 14, 6, "#4A4E54")      # 倒扣的相框
for (x, y) in ((19, 6), (21, 5), (22, 7), (25, 6), (27, 5)):
    p.put(x, y, "#9AB0B8")
p.save_txt("home_near_frame.txt")

# ── 前景：木門框 64×384、垂下的斷梁 150×130
F0, F1, FR = "#0C0806", "#150F0B", "#4A3018"
d = Grid(64, 384)
d.rect(0, 0, 63, 383, F1)
d.rect(16, 24, 47, 383, None)                                         # 門洞
d.vline(15, 24, 383, FR); d.hline(15, 48, 23, FR)                     # 門框內緣的暖光
for y in range(40, 380, 24):
    d.hline(2, 13, y, F0); d.hline(50, 61, y + 12, F0)                # 木紋
d.save_txt("home_front_doorframe.txt", outline=False)
bm = Grid(150, 130)
for i in range(150):                                                  # 從左上斜斜垂下的梁
    y = i * 110 // 150
    bm.rect(i, y, i, y + 14, F1); bm.put(i, y, FR)
for (x, y) in ((30, 34), (80, 72), (120, 102)):
    bm.rect(x, y - 2, x + 3, y + 18, F0)                              # 斷掉的木條
for i in range(140, 150):                                             # 斷口的碎木
    bm.put(i, 110 + (i % 3) * 4, F1)
bm.save_txt("home_front_beam.txt", outline=False)

# ── 選做：倒下的衣櫃 90×36
k = Grid(90, 36)
k.rect(2, 6, 87, 33, "#4A3424"); k.hline(2, 87, 6, "#6A4C34")       # 衣櫃側躺
k.rect(6, 10, 43, 30, "#3A281C"); k.rect(46, 10, 83, 30, "#3A281C")  # 兩扇門
k.put(42, 20, "#B08A3E"); k.put(47, 20, "#B08A3E")                  # 把手
k.rect(48, 12, 81, 28, "#2A1E14")                                     # 一扇門開了一半
for (x, y, col) in ((52, 34, "#6A5A7A"), (60, 35, "#7A3A3A"), (70, 34, "#5A6A7A")):   # 掉出來的衣服
    k.rect(x, y - 3, x + 6, y, col)
k.save_txt("home_wardrobe.txt")
print("ok")
