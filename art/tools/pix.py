# 像素設計圖共用工具（A＋）：格線畫布、矩形、橢圓、自動外框、輸出 ImageMagick txt。
# 設計腳本放在暫存區，用 sys.path 引用這個檔案；txt 用 `magick x.txt PNG32:x.png` 轉成 Pixelorama 能匯入的 PNG。
OUT = "#16181C"


class Grid:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = [[None] * w for _ in range(h)]
        self.no_outline = set()

    def put(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.g[y][x] = c

    def get(self, x, y):
        return self.g[y][x] if 0 <= x < self.w and 0 <= y < self.h else None

    def rect(self, x0, y0, x1, y1, c):  # 含兩端
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.put(x, y, c)

    def hline(self, x0, x1, y, c):
        self.rect(x0, y, x1, y, c)

    def vline(self, x, y0, y1, c):
        self.rect(x, y0, x, y1, c)

    def line(self, x0, y0, x1, y1, c):
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(n + 1):
            self.put(x0 + (x1 - x0) * i // n, y0 + (y1 - y0) * i // n, c)

    def ellipse(self, cx, cy, rx, ry, c):
        for y in range(cy - ry, cy + ry + 1):
            for x in range(cx - rx, cx + rx + 1):
                if ((x - cx) / (rx + 0.5)) ** 2 + ((y - cy) / (ry + 0.5)) ** 2 <= 1:
                    self.put(x, y, c)

    def outlined(self):
        out = [row[:] for row in self.g]
        for y in range(self.h):
            for x in range(self.w):
                if self.g[y][x] is None:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        c = self.get(x + dx, y + dy)
                        if c is not None and c != OUT and c not in self.no_outline:
                            out[y][x] = OUT
                            break
        return out

    def save_txt(self, path, outline=True):
        px = self.outlined() if outline else self.g
        with open(path, "w") as f:
            f.write(f"# ImageMagick pixel enumeration: {self.w},{self.h},255,srgba\n")
            for y in range(self.h):
                for x in range(self.w):
                    c = px[y][x]
                    if c is None:
                        f.write(f"{x},{y}: (0,0,0,0)  #00000000  none\n")
                    else:
                        r, g, b = int(c[1:3], 16), int(c[3:5], 16), int(c[5:7], 16)
                        a = int(c[7:9], 16) if len(c) == 9 else 255   # 可以用 #RRGGBBAA 畫半透明
                        f.write(f"{x},{y}: ({r},{g},{b},{a})  {c[:7]}{a:02X}  srgba({r},{g},{b},{a / 255:.4f})\n")


FONT = {
    "E": ["###", "#..", "##.", "#..", "###"], "X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
    "I": ["###", ".#.", ".#.", ".#.", "###"], "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "B": ["##.", "#.#", "##.", "#.#", "##."], "2": ["##.", "..#", ".#.", "#..", "###"],
}


def text(grid, x, y, s, c, scale=1):
    for ch in s:
        for dy, row in enumerate(FONT[ch]):
            for dx, v in enumerate(row):
                if v == "#":
                    grid.rect(x + dx * scale, y + dy * scale, x + dx * scale + scale - 1, y + dy * scale + scale - 1, c)
        x += 4 * scale
