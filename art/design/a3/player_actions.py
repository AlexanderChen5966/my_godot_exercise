# A3 第 8 組：主角的新動作（只畫向右；向左＝左右翻轉，和 Lv3 的待機、行走一樣）32x48
# reach_r 0～2：調查時伸手（手臂從垂下 → 抬起 → 往前伸到胸口高度，停在最後一格）
# lean_r 0～1：衝動強度高時前傾（頭往前下 2px、肩膀往前 1px，兩格交替像喘氣）
# 用法：python3 player_actions.py 輸出資料夾 → player_reach_f0..2.txt、player_lean_f0..1.txt
import sys, subprocess, re
sys.path.insert(0, "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/art/tools")
from pix import Grid, OUT

ROOT = "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/"
OUTDIR = sys.argv[1]
t = subprocess.run(["magick", ROOT + "assets/sprites/player.png", "-crop", "32x48+0+0", "+repage", "txt:-"],
                   capture_output=True, text=True).stdout
W, H = 32, 48
src = [[None] * W for _ in range(H)]
for l in t.splitlines()[1:]:
    m = re.match(r"(\d+),(\d+):.*#([0-9A-F]{8})", l)
    x, y, c = int(m[1]), int(m[2]), m[3]
    src[y][x] = None if c.endswith("00") else "#" + c[:6]

COAT, COAT_L, COAT_D = "#5D5C48", "#8A8676", "#4A4A3A"
SKIN, SKIN_D, BLOOD = "#7D8F86", "#5C6B65", "#6E1F1C"
ARM_COLS = range(16, 21)   # 靠近畫面那隻手臂（第 16～20 欄）
ARM_ROWS = range(16, 29)   # 第 16～28 列（含手）


def body_without_arm():
    g = Grid(W, H)
    for y in range(H):
        for x in range(W):
            c = src[y][x]
            if c is None:
                continue
            if y in ARM_ROWS and x in ARM_COLS:
                c = COAT_D if x < 20 else OUT  # 手臂後面是外套側邊
            if y in range(26, 29) and x in range(15, 18):  # 原本垂下的手
                c = COAT_D
            g.put(x, y, c)
    return g


def arm(g, pts, hand):
    """手臂：沿著折線畫 4px 寬（上緣亮、中間外套色、下緣陰影；原本的手臂約 5px），手 3x2（帶一點血）"""
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(abs(x1 - x0), abs(y1 - y0), 1) * 2
        for i in range(n + 1):
            x = round(x0 + (x1 - x0) * i / n)
            y = round(y0 + (y1 - y0) * i / n)
            g.put(x, y, COAT_L)
            g.put(x, y + 1, COAT)
            g.put(x, y + 2, COAT)
            g.put(x, y + 3, COAT_D)
    hx, hy = hand
    g.rect(hx, hy, hx + 2, hy + 1, SKIN)
    g.put(hx + 2, hy + 1, SKIN_D)
    g.put(hx, hy + 1, BLOOD)


def reach(f):
    g = body_without_arm()
    shoulder = (18, 15)
    # 手抬到胸口高度往前伸（作者 2026-10-14：「手是不是再升高一點」；原本最後一格在腰下方）
    if f == 0:
        arm(g, [shoulder, (20, 19), (22, 21)], (23, 21))
    elif f == 1:
        arm(g, [shoulder, (21, 17), (24, 18)], (25, 18))
    else:
        arm(g, [shoulder, (21, 16), (26, 17)], (27, 17))
    return outlined(g)


def lean(f):
    g = Grid(W, H)
    dy = f  # 第 1 格頭再低 1px（喘氣）
    for y in range(H):
        for x in range(W):
            c = src[y][x]
            if c is None:
                continue
            if y <= 12:
                g.put(x + 2, y + 1 + dy, c)   # 頭往前下
            elif y <= 16:
                g.put(x + 1, y + dy, c)       # 肩膀往前
            else:
                g.put(x, y, c)
    return outlined(g)


def outlined(g):
    o = g.outlined()
    g.g = o
    return g


for f in range(3):
    reach(f).save_txt(f"{OUTDIR}/player_reach_f{f}.txt", outline=False)
for f in range(2):
    lean(f).save_txt(f"{OUTDIR}/player_lean_f{f}.txt", outline=False)
