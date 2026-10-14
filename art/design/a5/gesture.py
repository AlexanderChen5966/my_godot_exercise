# A5 手勢：主角比出「我——在——這——裡」（劇本裡教女兒的手勢）。只畫向右；向左＝左右翻轉。32x48
# gesture_r 0：手抬起（從垂下到腰前）
#           1：「我」  手按在自己胸口
#           2：「在」  手掌張開朝前，舉到臉旁
#           3：「這裡」手往前下方指地面
#           4：「這裡」往下點（手和食指再往下 2px；3 和 4 交替兩次，像在點地面，作者 2026-10-14）
# 用法：python3 gesture.py 輸出資料夾 → player_gesture_f0..4.txt
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

# 和 A3 主角新動作（art/design/a3/player_actions.py）相同的顏色與「拿掉手臂的身體」
COAT, COAT_L, COAT_D = "#5D5C48", "#8A8676", "#4A4A3A"
SKIN, SKIN_D, BLOOD = "#7D8F86", "#5C6B65", "#6E1F1C"
ARM_COLS = range(16, 21)
ARM_ROWS = range(16, 29)
SHOULDER = (18, 15)


def body_without_arm():
    g = Grid(W, H)
    for y in range(H):
        for x in range(W):
            c = src[y][x]
            if c is None:
                continue
            if y in ARM_ROWS and x in ARM_COLS:
                c = COAT_D if x < 20 else OUT
            if y in range(26, 29) and x in range(15, 18):
                c = COAT_D
            g.put(x, y, c)
    return g


def sleeve(g, pts, width=3):
    """袖子：沿折線畫 width px 粗（上緣亮、下緣陰影）"""
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(abs(x1 - x0), abs(y1 - y0), 1) * 2
        for i in range(n + 1):
            x = round(x0 + (x1 - x0) * i / n)
            y = round(y0 + (y1 - y0) * i / n)
            g.put(x, y, COAT_L)
            for k in range(1, width):
                g.put(x, y + k, COAT if k < width - 1 else COAT_D)


def frame(f):
    g = body_without_arm()
    if f == 0:      # 手抬起到腰前
        sleeve(g, [SHOULDER, (20, 20), (22, 23)], width=4)
        g.rect(22, 25, 24, 26, SKIN)
        g.put(24, 26, SKIN_D)
    elif f == 1:    # 「我」：手肘往前，手掌按在胸口（手背朝外）
        sleeve(g, [SHOULDER, (21, 19)], width=4)
        sleeve(g, [(22, 20), (20, 20)], width=3)
        g.rect(16, 19, 19, 21, SKIN)            # 手掌按在胸口（3x4，比袖子明顯）
        g.vline(16, 19, 21, SKIN_D)             # 手指的陰影
        g.put(19, 21, BLOOD)
    elif f == 2:    # 「在」：前臂立起，手掌張開朝前，舉到下巴前方（不擋住臉）
        sleeve(g, [SHOULDER, (22, 18), (26, 20)], width=4)
        sleeve(g, [(27, 19), (28, 17)], width=3)
        g.rect(28, 12, 29, 16, SKIN)            # 手掌（側面看是直立的一片），在下巴的前下方，不貼著臉
        g.vline(30, 13, 16, SKIN)               # 張開的手指往前一點
        g.put(28, 11, SKIN)                     # 指尖
        g.vline(27, 13, 16, SKIN_D)
        g.put(29, 16, BLOOD)
    elif f == 3:    # 「這裡」：手往前下方指地面
        sleeve(g, [SHOULDER, (21, 18), (24, 22)], width=4)
        g.rect(24, 24, 26, 26, SKIN)
        g.vline(25, 27, 30, SKIN)               # 食指往下指
        g.put(24, 26, SKIN_D)
    else:           # 「這裡」往下點：手肘伸直一點，手和食指再往下 2px
        sleeve(g, [SHOULDER, (21, 19), (24, 24)], width=4)
        g.rect(24, 26, 26, 28, SKIN)
        g.vline(25, 29, 32, SKIN)
        g.put(24, 28, SKIN_D)
    o = g.outlined()
    g.g = o
    return g


for f in range(5):
    frame(f).save_txt(f"{OUTDIR}/player_gesture_f{f}.txt", outline=False)
