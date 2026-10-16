# A6 網頁版瘦身：字型只留遊戲裡用到的字（Noto Sans TC 完整版約 6.8MB）。
# 完整字型保存在 art/fonts/（不匯出），精簡版寫回 assets/fonts/NotoSansTC-Regular.ttf（專案設定不用改）。
# 收集的文字：data/ 的 JSON（劇本、區域、製作群）、scripts/ 與 tools/ 的 .gd、scenes/ 的 .tscn，
# 再加上英數字、常用標點、箭頭與畫線符號（Godot 授權全文與第三方元件清單都是英文）。
# **改了任何文字之後都要重新執行**（劇本檢查會檢查資料裡的字是不是都在字型裡）：
#   ~/Tools/fonttools-venv/bin/python art/tools/font_subset.py
import glob, os, subprocess, sys, unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FULL = os.path.join(ROOT, "art/fonts/NotoSansTC-Regular.ttf")
OUT = os.path.join(ROOT, "assets/fonts/NotoSansTC-Regular.ttf")

chars = set()
for pattern in ["data/**/*.json", "scripts/**/*.gd", "tools/**/*.gd", "scenes/**/*.tscn"]:
    for path in glob.glob(os.path.join(ROOT, pattern), recursive=True):
        chars.update(open(path, encoding="utf-8").read())
ranges = [
    (0x20, 0x7E),      # 英數字與 ASCII 標點
    (0xA0, 0xFF),      # Latin-1（授權文字裡的 ©、引號等）
    (0x2000, 0x206F),  # 一般標點（—、…、‘’“”）
    (0x2190, 0x21FF),  # 箭頭（↑↓←→）
    (0x2500, 0x257F),  # 畫線（─）
    (0x25A0, 0x25FF),  # 幾何圖形（▶▼）
    (0x3000, 0x303F),  # 中文標點（、。「」『』【】〔〕）
    (0xFF00, 0xFFEF),  # 全形符號（，：；！？（））
]
for a, b in ranges:
    chars.update(chr(c) for c in range(a, b + 1))
chars = {c for c in chars if unicodedata.category(c)[0] != "C"}  # 只排除控制字元（isprintable 會把全形空白「　」也濾掉）
cjk = sum(1 for c in chars if ord(c) > 0x2E80)
text_file = os.path.join(ROOT, "art/fonts/_subset_chars.txt")
with open(text_file, "w", encoding="utf-8") as f:
    f.write("".join(sorted(chars)))
venv_tool = os.path.expanduser("~/Tools/fonttools-venv/bin/pyftsubset")
subprocess.run([venv_tool, FULL, f"--text-file={text_file}", f"--output-file={OUT}",
                "--layout-features=*", "--no-hinting"], check=True)
print(f"收集 {len(chars)} 個字元（中文 {cjk} 個）：{os.path.getsize(FULL) / 1048576:.2f} MB → {os.path.getsize(OUT) / 1048576:.2f} MB")
