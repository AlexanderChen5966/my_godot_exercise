# A3 第 7 組：妻子、女兒（照原圖 scene_19；妻子依劇本「頭髮剪短了」）
# 妻子 wife_f0..3（32x48，面向左）：分麵包的循環 遞出 → 被拿走、手攤開 → 手收回 → 在腰間拿起下一塊
# 女兒 daughter_f0..4（24x22，只有窗戶露出的上半身）：0 平常、1 眨眼、2～3 舉起小手比手勢、4 轉身（背對窗戶）
# 用法：python3 family.py 輸出資料夾
import sys, subprocess, re
sys.path.insert(0, "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/art/tools")
from pix import Grid, OUT

ROOT = "/Users/alexander/Desktop/Speckit Project/失語者/失語者_Godot/"
OUTDIR = sys.argv[1]


def load(name):
    t = subprocess.run(["magick", ROOT + f"assets/sprites/characters/{name}.png", "txt:-"], capture_output=True, text=True).stdout
    w, h = map(int, re.match(r"# ImageMagick pixel enumeration: (\d+),(\d+)", t).groups())
    g = [[None] * w for _ in range(h)]
    for l in t.splitlines()[1:]:
        m = re.match(r"(\d+),(\d+):.*#([0-9A-F]{8})", l)
        x, y, c = int(m[1]), int(m[2]), m[3]
        g[y][x] = None if c.endswith("00") else "#" + c[:6]
    return w, h, g


# ---- 妻子 ----
W, H, wife = load("wife")
SKIN = "#C49A7C"
SLEEVE, SLEEVE_D = "#9A5A34", "#7A4628"
BREAD, BREAD_D = "#C8A060", "#A07840"


def wife_base(keep_arm):
    g = Grid(W, H)
    for y in range(H):
        for x in range(W):
            c = wife[y][x]
            if c is None:
                continue
            if not keep_arm and 20 <= y <= 25 and x < 10:  # 伸出去的手臂、手、麵包
                continue
            g.put(x, y, c)
    return g


def wife_frame(f):
    if f == 0:  # 原本：拿著麵包遞出去
        return wife_base(True)
    if f == 1:  # 麵包被拿走，手還伸著、攤開
        g = wife_base(True)
        for y in range(20, 26):
            for x in range(0, 5):
                g.put(x, y, None)
        g.rect(4, 22, 5, 23, SKIN)
        return g
    g = wife_base(False)
    if f == 2:  # 手收回，垂在身體前面
        g.rect(8, 20, 9, 27, SLEEVE)
        g.vline(9, 20, 27, SLEEVE_D)
        g.rect(8, 28, 9, 29, SKIN)
    else:       # 在腰間拿起下一塊麵包
        g.rect(8, 20, 9, 24, SLEEVE)
        g.vline(9, 20, 24, SLEEVE_D)
        g.rect(6, 25, 9, 25, SLEEVE)
        g.rect(5, 26, 6, 26, SKIN)
        g.rect(2, 25, 5, 27, BREAD)
        g.hline(2, 5, 27, BREAD_D)
    return g


for f in range(4):
    wife_frame(f).save_txt(f"{OUTDIR}/wife_f{f}.txt", outline=True)

# ---- 女兒（只取窗戶露出的上 22 列）----
DW, DH = 24, 22
_, _, dau = load("daughter")
HAIR, HAIR_L = "#B0602C", "#D07A3C"
SHIRT, SHIRT_D = "#C07838", "#9A5A2A"
SKIN_D = "#9E7A62"


def dau_base():
    g = Grid(DW, DH)
    for y in range(DH):
        for x in range(DW):
            if dau[y][x] is not None:
                g.put(x, y, dau[y][x])
    return g


def dau_frame(f):
    g = dau_base()
    if f == 1:    # 眨眼：眼睛（8,8）換成膚色陰影
        g.put(8, 8, SKIN_D)
    elif f in (2, 3):  # 舉起小手，手心朝外（上臂往外、前臂立起；第 3 格手再高 1px）
        up = 1 if f == 3 else 0
        g.rect(4, 14, 6, 15, SHIRT)          # 上臂（袖子）往外
        g.hline(4, 6, 16, SHIRT_D)
        g.rect(2, 12 - up, 3, 16, "#C49A7C")  # 前臂立起
        g.rect(1, 9 - up, 3, 12 - up, "#C49A7C")  # 手掌
        g.put(1, 8 - up, "#C49A7C")           # 手指
        g.put(2, 8 - up, "#C49A7C")
        g.put(3, 8 - up, "#C49A7C")
        g.put(4, 11 - up, "#C49A7C")          # 拇指
        g.vline(3, 9 - up, 12 - up, SKIN_D)   # 手掌的陰影，讓手指和手掌分得開
    elif f == 4:  # 轉身背對窗戶：臉被頭髮蓋住（整片頭髮色，頭頂一點亮色）
        for y in range(7, 13):
            for x in range(6, 13):
                if g.get(x, y) in ("#C49A7C", "#9E7A62", OUT):
                    g.put(x, y, HAIR)
        for y in range(7, 13):
            g.put(5, y, OUT)
        g.hline(7, 9, 4, HAIR_L)
    return g


for f in range(5):
    dau_frame(f).save_txt(f"{OUTDIR}/daughter_f{f}.txt", outline=True)
