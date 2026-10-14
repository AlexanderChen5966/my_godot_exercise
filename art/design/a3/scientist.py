# A3 第 5 組：女科學家（照原圖 scene_07：深色及肩髮、白袍）8 格，32x48，面向左
# 0～1 idle：筆記本抱在胸前、呼吸（上半身 1px）；2～3 event：遞出筆記本（原本的姿勢，第 2 格手再往前 1px）
# 4～7 run：兩手空空快跑，白袍下襬甩動（遊戲裡往右跑時用 flip_h）
# 用法：python3 scientist.py 輸出資料夾 → scientist_f0..7.txt
import sys, subprocess, re
sys.path.insert(0, "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/art/tools")
from pix import Grid, OUT

ROOT = "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/"
OUTDIR = sys.argv[1]
t = subprocess.run(["magick", ROOT + "assets/sprites/characters/scientist.png", "txt:-"], capture_output=True, text=True).stdout
W, H = 32, 48
src = [[None] * W for _ in range(H)]
for l in t.splitlines()[1:]:
    m = re.match(r"(\d+),(\d+):.*#([0-9A-F]{8})", l)
    x, y, c = int(m[1]), int(m[2]), m[3]
    src[y][x] = None if c.endswith("00") else "#" + c[:6]

COAT, COAT_D, COAT_L = "#D8DCCC", "#A8AEA4", "#D8DCCC"
SKIN = "#C49A7C"
BOOK, PAGE, BOOK_D = "#6E4A30", "#D8D2BC", "#4A3020"
PANTS, SHOE = "#2F3238", "#1F1C1A"


def is_book_arm(x, y):
    """遞出去的筆記本、手、袖口（身體左緣第 8 欄以左，第 19～28 列）"""
    return 19 <= y <= 28 and x < 8


def base(skip_book=True, rows=range(0, H)):
    g = Grid(W, H)
    for y in rows:
        for x in range(W):
            c = src[y][x]
            if c is None or (skip_book and is_book_arm(x, y)):
                continue
            g.put(x, y, c)
    return g


def hug(g, dy=0):
    """筆記本抱在胸前：書貼在白袍前面、往前凸出 3px，手壓在書的右側"""
    g.rect(5, 20 + dy, 10, 28 + dy, BOOK)
    g.hline(5, 10, 28 + dy, BOOK_D)           # 書底的陰影
    g.vline(5, 21 + dy, 27 + dy, PAGE)        # 書頁（朝前的那一側）
    g.rect(9, 23 + dy, 10, 24 + dy, SKIN)     # 手
    g.rect(11, 23 + dy, 12, 24 + dy, COAT_D)  # 袖口


def idle(f):
    dy = f  # 第 1 格整個上半身下沉 1px（吐氣）
    g = Grid(W, H)
    for y in range(0, 37):
        for x in range(W):
            c = src[y][x]
            if c is None or is_book_arm(x, y):
                continue
            g.put(x, y + dy, c)
    for y in range(37, H):
        for x in range(W):
            if src[y][x] is not None:
                g.put(x, y, src[y][x])
    hug(g, dy)
    return g


def event(f):
    g = base(skip_book=False)
    if f == 1:  # 手再往前伸 1px，像在發抖
        g = base(skip_book=True)
        for y in range(19, 29):
            for x in range(0, 8):
                c = src[y][x]
                if c is not None:
                    g.put(x - 1, y, c)
        g.put(7, 22, COAT_D)  # 補上伸長的袖子
    return g


def limb(g, pts, color, width=3):
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
    air = f % 2 == 1
    bob = -2 if air else 0
    lean = lambda y: -2 if y <= 16 else (-1 if y <= 28 else 0)
    g = Grid(W, H)
    for y in range(0, 37):
        for x in range(W):
            c = src[y][x]
            if c is None or is_book_arm(x, y):
                continue
            g.put(x + lean(y), y + bob, c)
    # 白袍下襬往後甩（右邊多 1～2px）
    for y in range(31 + bob, 37 + bob):
        g.hline(22, 22 + (2 if air else 1), y, COAT_D)
    sh = (6, 20 + bob)
    if f == 0:
        arm, hand = [sh, (4, 24 + bob), (1, 22 + bob)], (-1, 21 + bob)
    elif f == 2:
        arm, hand = [sh, (8, 25 + bob)], None
    else:
        arm, hand = [sh, (5, 25 + bob), (3, 25 + bob)], (1, 25 + bob)
    limb(g, arm, COAT, width=2)
    if hand:
        g.rect(hand[0], hand[1], hand[0] + 1, hand[1] + 1, SKIN)
    hip = 37 + bob
    if f in (0, 2):
        limb(g, [(10, hip), (6, 41), (3, 45)], PANTS)
        shoe(g, 2, 46)
        limb(g, [(14, hip), (18, 41), (21, 44)], PANTS)
        shoe(g, 21, 45)
    else:
        limb(g, [(10, hip), (6, 39 + bob), (6, 43 + bob)], PANTS)
        shoe(g, 5, 44 + bob)
        limb(g, [(14, hip), (17, 41 + bob), (22, 38 + bob)], PANTS)
        shoe(g, 23, 37 + bob)
    return g


frames = [idle(0), idle(1), event(0), event(1)] + [run(f) for f in range(4)]
for i, g in enumerate(frames):
    g.save_txt(f"{OUTDIR}/scientist_f{i}.txt", outline=True)
