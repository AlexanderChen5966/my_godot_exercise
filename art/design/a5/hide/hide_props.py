# A5 躲藏：設施走廊的掩護與通風管（顏色沿用推車 lab_cart.png 的金屬色系）
# lab_crates  36x32：兩個金屬補給箱疊在一起（下大上小，偏左），米色標籤、把手
# lab_vent    38x20：牆腳的通風管開口（黑洞＋外框），格柵被拆下來斜靠在右邊；出口那一側用左右翻轉
# 用法：python3 hide_props.py 輸出資料夾 → lab_crates.txt、lab_vent.txt
import sys
sys.path.insert(0, "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/art/tools")
from pix import Grid, OUT

OUTDIR = sys.argv[1]
INK = "#16181C"                       # 外框、最暗
DARK, MID, LIGHT, HI = "#3E4247", "#5A5E64", "#7A7F86", "#9AA0A6"
BEIGE, TEAL, BLACK = "#C8C0B0", "#8AA8B0", "#0B0C0E"


def crate(g, x0, y0, w, h, label_w):
    g.rect(x0, y0, x0 + w - 1, y0 + h - 1, MID)
    g.hline(x0, x0 + w - 1, y0, HI)                 # 上緣反光
    g.rect(x0, y0 + 1, x0 + w - 1, y0 + 2, LIGHT)   # 蓋子
    g.hline(x0, x0 + w - 1, y0 + 3, DARK)
    g.vline(x0 + w - 1, y0 + 1, y0 + h - 1, DARK)   # 右側陰影
    g.hline(x0, x0 + w - 1, y0 + h - 1, DARK)
    for x in (x0 + 2, x0 + w - 3):                   # 角柱（加強條）
        g.vline(x, y0 + 4, y0 + h - 2, LIGHT)
    lx = x0 + (w - label_w) // 2                      # 米色標籤＋兩條字
    g.rect(lx, y0 + 6, lx + label_w - 1, y0 + 9, BEIGE)
    g.hline(lx + 1, lx + label_w - 3, y0 + 7, DARK)
    g.hline(lx + 1, lx + label_w // 2, y0 + 8, DARK)
    hy = y0 + h - 5                                   # 把手
    g.hline(x0 + w // 2 - 3, x0 + w // 2 + 2, hy, INK)
    g.put(x0 + w // 2 - 3, hy - 1, INK)
    g.put(x0 + w // 2 + 2, hy - 1, INK)


g = Grid(36, 32)
crate(g, 1, 13, 34, 18, 12)   # 下面的大箱子
crate(g, 4, 1, 24, 13, 8)     # 上面的小箱子（偏左）
g.hline(26, 33, 13, DARK)     # 小箱子右邊落在大箱子上的影子
g.save_txt(f"{OUTDIR}/lab_crates.txt", outline=True)

v = Grid(38, 20)
v.rect(1, 2, 22, 18, DARK)        # 外框
v.rect(2, 3, 21, 17, MID)
v.hline(2, 21, 3, LIGHT)
v.rect(4, 5, 19, 16, BLACK)       # 開口（裡面全黑）
v.hline(4, 19, 5, INK)
for x in (2, 21):                 # 四角的螺絲孔
    for y in (3, 17):
        v.put(x, y, INK)
# 拆下來的格柵：一片微微傾斜的長方形（每 4 列往右偏 1px），斜靠在右邊牆上；橫向葉片亮暗交替
for i in range(14):
    y = 5 + i
    x = 24 + i // 4
    v.hline(x, x + 8, y, MID)
    v.put(x, y, DARK)
    v.put(x + 8, y, DARK)
    if i in (0, 13):
        v.hline(x, x + 8, y, DARK)          # 上下邊框
    elif i % 2 == 1:
        v.hline(x + 1, x + 7, y, INK)       # 葉片之間的縫
    else:
        v.hline(x + 1, x + 7, y, LIGHT)     # 葉片
v.save_txt(f"{OUTDIR}/lab_vent.txt", outline=True)
