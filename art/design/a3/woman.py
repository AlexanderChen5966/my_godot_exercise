# A3 第 3 組：婦人 尖叫 2 格＋逃跑 4 格（面向左，往右跑時遊戲裡用 flip_h）
# 輸出 woman_f0..5.txt（32x48），0～1 尖叫、2～5 逃跑
import sys, subprocess, re
sys.path.insert(0, "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/art/tools")
from pix import Grid, OUT

ROOT = "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/"
OUTDIR = sys.argv[1]
t = subprocess.run(["magick", ROOT + "assets/sprites/characters/woman.png", "txt:-"], capture_output=True, text=True).stdout
W, H = 32, 48
src = [[None] * W for _ in range(H)]
for l in t.splitlines()[1:]:
    m = re.match(r"(\d+),(\d+):.*#([0-9A-F]{8})", l)
    x, y, c = int(m[1]), int(m[2]), m[3]
    src[y][x] = None if c.endswith("00") else "#" + c[:6]

COAT, COAT_D, COAT_L = "#6E6440", "#545030", "#847A50"
SKIN, SKIN_D = "#C49A7C", "#9E7A62"
PANTS, SHOE = "#3A2E26", "#1F1C1A"


def is_hand(x, y):
    """舉起的手與袖子：第 17 列以上是第 8 欄以左，袖口斜到肩膀（第 18～20 列到第 8 欄）"""
    return y <= 20 and x < (9 if y >= 18 else 8)


def copy(dx=0, dy=0, rows=range(0, 35), keep_hand=True, shear=None):
    g = Grid(W, H)
    for y in rows:
        for x in range(W):
            c = src[y][x]
            if c is None or (not keep_hand and is_hand(x, y)):
                continue
            sx = dx + (shear(y) if shear else 0)
            g.put(x + sx, y + dy, c)
    return g


def paste_rows(g, rows, dx=0, dy=0):
    for y in rows:
        for x in range(W):
            if src[y][x] is not None:
                g.put(x + dx, y + dy, src[y][x])


MOUTH = "#2B2622"


def scream(f):
    # 上半身往後縮 1px（受驚往後），腳不動；舉起的手左右抖；嘴巴一小一大地張合（原本的嘴在 (11,14)）
    g = Grid(W, H)
    for y in range(0, 35):
        for x in range(W):
            c = src[y][x]
            if c is None:
                continue
            if is_hand(x, y) and y <= 16:
                g.put(x + (0 if f == 0 else -1), y - (1 if f == 0 else 0), c)
            else:
                g.put(x + 1, y, c)
    paste_rows(g, range(35, 48))
    mouth = [(11, 14), (11, 15)] if f == 0 else [(10, 14), (11, 14), (10, 15), (11, 15)]
    for x, y in mouth:
        g.put(x + 1, y, MOUTH)
    return g


def limb(g, pts, color, width=3):
    """折線（臀部 → 膝蓋 → 腳），每段 width px 寬"""
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(n + 1):
            x = round(x0 + (x1 - x0) * i / n)
            y = round(y0 + (y1 - y0) * i / n)
            for k in range(width):
                g.put(x + k, y, color)


def shoe(g, x, y):
    g.rect(x - 1, y, x + 3, y + 1, SHOE)


def run(f):
    # 快跑：頭往前 2px、上半身 1px；騰空的那兩格身體上移 2px
    air = f % 2 == 1
    bob = -2 if air else 0
    shear = lambda y: -2 if y <= 16 else (-1 if y <= 30 else 0)
    g = copy(dy=bob, rows=range(0, 35), keep_hand=False, shear=shear)
    # 包包：騰空時甩高、落地時往下
    for y in range(28, 39):
        for x in range(18, 28):
            c = src[y][x]
            if c in ("#6A4228", "#8A5A34") or (c == OUT and y >= 30 and x >= 19):
                g.put(x, y + bob, None)
    bag_dy = (-2 if air else 1) + bob
    for y in range(28, 39):
        for x in range(18, 28):
            c = src[y][x]
            if c in ("#6A4228", "#8A5A34") or (c == OUT and y >= 30 and x >= 19):
                g.put(x, y + bag_dy, c)
    # 手臂用力擺、手肘彎曲（肩膀在身體左緣 x 7）
    sh = (7, 20 + bob)
    if f == 0:      # 往前擺：前臂往前上
        arm = [sh, (5, 24 + bob), (2, 22 + bob)]
        hand = (0, 21 + bob)
    elif f == 2:    # 往後擺：藏在身體後面，只露出手肘
        arm = [sh, (9, 25 + bob)]
        hand = None
    else:           # 騰空：手臂在身體前面、彎著
        arm = [sh, (6, 25 + bob), (4, 25 + bob)]
        hand = (2, 25 + bob)
    limb(g, arm, COAT, width=2)
    if hand:
        g.rect(hand[0], hand[1], hand[0] + 1, hand[1] + 1, SKIN)
    hip = 35 + bob
    if f in (0, 2):   # 著地：大步伐，前腳在前、後腳在後
        limb(g, [(10, hip), (6, 40), (3, 45)], PANTS)
        shoe(g, 2, 46)
        limb(g, [(13, hip), (17, 40), (21, 44)], PANTS)
        shoe(g, 21, 45)
    else:             # 騰空：前膝抬高、後腳往後踢
        limb(g, [(10, hip), (6, 38 + bob), (6, 43 + bob)], PANTS)
        shoe(g, 5, 44 + bob)
        limb(g, [(13, hip), (16, 40 + bob), (21, 37 + bob)], PANTS)
        shoe(g, 22, 36 + bob)
    return g


frames = [scream(0), scream(1)] + [run(f) for f in range(4)]
for i, g in enumerate(frames):
    g.save_txt(f"{OUTDIR}/woman_f{i}.txt", outline=True)
