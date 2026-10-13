# A3 第 4 組：感染者群（自己設計，原圖沒有）8 格，96x44
# 0～3：兩隻蹲著的啃食（頭往下 0/1/2/1，右邊那隻錯開半個週期）；4～7：同樣的啃食＋站著那隻把頭轉過來（頭部左右翻轉）
# 用法：python3 horde.py 輸出資料夾 → horde_f0..7.txt
import sys, subprocess, re
sys.path.insert(0, "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/art/tools")
from pix import Grid

ROOT = "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/"
OUTDIR = sys.argv[1]
t = subprocess.run(["magick", ROOT + "assets/sprites/characters/horde.png", "txt:-"], capture_output=True, text=True).stdout
W, H = 96, 44
src = [[None] * W for _ in range(H)]
for l in t.splitlines()[1:]:
    m = re.match(r"(\d+),(\d+):.*#([0-9A-F]{8})", l)
    x, y, c = int(m[1]), int(m[2]), m[3]
    src[y][x] = None if c.endswith("00") else "#" + c[:6]

LEFT_HEAD = (4, 14, 26, 37)    # 左邊蹲著那隻的頭（x0, x1, y0, y1，含兩端）
RIGHT_HEAD = (63, 73, 26, 37)  # 右邊蹲著那隻的頭
STAND_HEAD = (39, 51, 1, 10)   # 站著那隻的頭（含下巴那一列）
BITE = [0, 1, 2, 1]            # 每格頭往下幾 px


def inside(box, x, y):
    x0, x1, y0, y1 = box
    return x0 <= x <= x1 and y0 <= y <= y1


def frame(f):
    look = f >= 4
    i = f % 4
    g = Grid(W, H)
    heads = [(LEFT_HEAD, BITE[i]), (RIGHT_HEAD, BITE[(i + 2) % 4])]
    # 先畫頭以外的部分
    for y in range(H):
        for x in range(W):
            c = src[y][x]
            if c is None or any(inside(b, x, y) for b, _ in heads) or (look and inside(STAND_HEAD, x, y)):
                continue
            g.put(x, y, c)
    # 蹲著的兩顆頭往下移（低頭咬）
    for box, dy in heads:
        x0, x1, y0, y1 = box
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if src[y][x] is not None:
                    g.put(x, y + dy, src[y][x])
    # 站著那隻轉頭：頭部左右翻轉
    if look:
        x0, x1, y0, y1 = STAND_HEAD
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if src[y][x] is not None:
                    g.put(x0 + x1 - x, y, src[y][x])
    return g


for f in range(8):
    frame(f).save_txt(f"{OUTDIR}/horde_f{f}.txt", outline=False)
