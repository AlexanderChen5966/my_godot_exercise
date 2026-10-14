# A3 第 6 組：警衛（Lv6 自己設計：頭盔、步槍；手電筒裝在槍管下，作者 2026-10-14）32x48，面向左
# 整把槍以肩膀（槍托）為支點轉動，不是只動槍口（第一版只移槍口 5 欄，槍會「折」）。
# 0～3 搜索（低姿戒備，槍口朝下 22°／28°／34°／28° 來回掃）；4 瞄準（舉平 0°，事件開始時）
# 光永遠沿著槍管：遊戲裡的錐形光角度＝槍的角度（ANGLES），從燈頭 lens_point() 射出
# 用法：python3 guard.py 輸出資料夾 → guard_f0..4.txt，並印出每格燈頭位置與角度
import sys, subprocess, re, math
sys.path.insert(0, "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/art/tools")
from pix import Grid, OUT

ROOT = "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/"
OUTDIR = sys.argv[1]
t = subprocess.run(["magick", ROOT + "assets/sprites/characters/guard.png", "txt:-"], capture_output=True, text=True).stdout
W, H = 32, 48
src = [[None] * W for _ in range(H)]
for l in t.splitlines()[1:]:
    m = re.match(r"(\d+),(\d+):.*#([0-9A-F]{8})", l)
    x, y, c = int(m[1]), int(m[2]), m[3]
    src[y][x] = None if c.endswith("00") else "#" + c[:6]

GUN, GUN_L = "#2B2B2B", "#4A4F58"
LENS, LIGHT_BODY = "#E8D890", "#6A707A"
SKIN, SLEEVE, SLEEVE_D = "#C49A7C", "#4E5560", "#3A4048"  # 袖子用頭盔的亮灰，才不會和身體混在一起
ANGLES = [22, 28, 34, 28, 0]   # 槍口往下的角度（度）
PIVOT = (17.0, 20.5)           # 槍托抵住肩膀的位置（槍的中心軸起點）
SHOULDER = (13, 17)            # 前手袖子從這裡出發
LENGTH = 17                    # 槍長（沿中心軸）


def body():
    """身體：拿掉原本的槍與前手，被擋住的胸口補回第 27 列的背心／外套顏色"""
    g = Grid(W, H)
    for y in range(H):
        for x in range(W):
            c = src[y][x]
            if c is None:
                continue
            if 16 <= y <= 25 and x < 8:
                continue
            if 19 <= y <= 25 and 8 <= x <= 16:
                c = src[27][x]
            g.put(x, y, c)
    for y in range(16, 26):
        if g.get(8, y) is not None:
            g.put(7, y, OUT)
    return g


def axis(tt, off, deg):
    """槍的中心軸上第 tt 格、往槍的下方偏 off 格的位置（面向左，deg 越大槍口越低）"""
    a = math.radians(deg)
    dx, dy = -math.cos(a), math.sin(a)       # 沿槍管往前
    nx, ny = -dy, dx                         # 槍的「下方」法線（面向左時：(sin, cos)… 取朝下那一側）
    nx, ny = (math.sin(a), math.cos(a))
    return PIVOT[0] + dx * tt + nx * off, PIVOT[1] + dy * tt + ny * off


def put(g, p, c):
    g.put(int(round(p[0])), int(round(p[1])), c)


def rifle(deg):
    g = Grid(W, H)
    steps = [i / 2 for i in range(0, LENGTH * 2 + 1)]  # 半格取樣，斜線不會斷
    for tt in steps:
        put(g, axis(tt, 0, deg), GUN_L if 8 <= tt <= 13 else GUN)   # 上緣（機匣反光）
        put(g, axis(tt, 1, deg), GUN)
    for tt in (7.5, 8, 8.5, 9):                                       # 彈匣
        for off in (2, 3):
            put(g, axis(tt, off, deg), GUN)
    for tt in (14, 14.5, 15, 15.5, 16):                               # 手電筒機身（槍管下）
        put(g, axis(tt, 2, deg), LIGHT_BODY)
        put(g, axis(tt, 3, deg), GUN_L)
    lx, ly = axis(16.5, 2, deg)                                       # 燈頭：上下相連的 2 格
    g.put(int(round(lx)), int(round(ly)), LENS)
    g.put(int(round(lx)), int(round(ly)) + 1, LENS)
    rear = axis(4, 2, deg)                                            # 後手（扳機）
    g.rect(int(round(rear[0])), int(round(rear[1])), int(round(rear[0])) + 1, int(round(rear[1])), SKIN)
    front = axis(11.5, 2, deg)                                        # 前手（護木下）
    # 前手袖子：從肩膀連到前手，2px 粗
    sx, sy = SHOULDER
    fx, fy = front
    n = int(max(abs(fx - sx), abs(fy - sy)) * 2) + 1
    for i in range(n + 1):
        x = sx + (fx - sx) * i / n
        y = sy + (fy - sy) * i / n
        g.put(int(round(x)), int(round(y)), SLEEVE)
        g.put(int(round(x)), int(round(y)) + 1, SLEEVE)
        g.put(int(round(x)), int(round(y)) + 2, SLEEVE_D)
    g.rect(int(round(fx)) - 1, int(round(fy)), int(round(fx)), int(round(fy)) + 1, SKIN)
    # 槍身最後畫一次，讓槍蓋在袖子上面
    for tt in steps:
        put(g, axis(tt, 0, deg), GUN_L if 8 <= tt <= 13 else GUN)
        put(g, axis(tt, 1, deg), GUN)
    return g


def lens_point(deg):
    return axis(16.5, 2.5, deg)


def aim():
    """瞄準（舉平）：沿用原本的姿勢，只把手電筒換成看得出形狀的一支（掛在槍管前端下方）"""
    g = Grid(W, H)
    for y in range(H):
        for x in range(W):
            if src[y][x] is not None:
                g.put(x, y, src[y][x])
    for y in (22, 23):
        g.put(0, y, OUT)
        g.put(1, y, LENS)
    for x in (2, 3, 4):
        g.put(x, 22, LIGHT_BODY)
        g.put(x, 23, GUN_L)
    for x in range(0, 5):
        g.put(x, 24, OUT)
    return g


for i, deg in enumerate(ANGLES):
    if deg == 0:
        aim().save_txt(f"{OUTDIR}/guard_f{i}.txt", outline=False)
        print(f"格 {i}：角度 0°（瞄準，原本的姿勢），燈頭 (1.0, 22.5)")
        continue
    b = body()
    r = rifle(deg)
    ro = r.outlined()
    for y in range(H):
        for x in range(W):
            c = ro[y][x]
            if c is None:
                continue
            # 外框只畫在背景（透明）上，不畫過背心，免得手臂看起來像背帶
            if c == OUT and r.get(x, y) is None and b.get(x, y) is not None:
                continue
            b.put(x, y, c)
    b.save_txt(f"{OUTDIR}/guard_f{i}.txt", outline=False)
    lx, ly = lens_point(deg)
    print(f"格 {i}：角度 {deg}°，燈頭 ({lx:.1f}, {ly:.1f})")
