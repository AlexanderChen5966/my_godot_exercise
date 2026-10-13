# 列出各區域場景互動點的位置、觸發範圍與物件尺寸：dump_points.py 專案根目錄 [區域名稱]
import re, sys, os, subprocess
root = sys.argv[1]
names = sys.argv[2:] or ["ParkingLot", "Street", "Clinic", "Lab", "Ruins", "Home", "Wall"]
for name in names:
    t = open(f"{root}/scenes/areas/{name}.tscn", encoding="utf-8").read()
    ext = {i: p for p, i in re.findall(r'\[ext_resource type="Texture2D"[^\]]*path="([^"]+)" id="([^"]+)"\]', t)}
    subs = dict(re.findall(r'\[sub_resource type="RectangleShape2D" id="([^"]+)"\]\nsize = Vector2\(([^)]+)\)', t))
    print(f"== {name}")
    for b in re.split(r'\n(?=\[node )', t):
        m = re.match(r'\[node name="([^"]+)" type="([^"]+)" parent="(Points[^"]*)"', b)
        if not m:
            continue
        n, typ, parent = m.groups()
        pos = re.search(r'\nposition = Vector2\(([^)]+)\)', b)
        info = f"  {parent}/{n} {typ} pos=({pos.group(1) if pos else '0, 0'})"
        sh = re.search(r'shape = SubResource\("([^"]+)"\)', b)
        if sh:
            info += f" size=({subs.get(sh.group(1))})"
        tx = re.search(r'texture = ExtResource\("([^"]+)"\)', b)
        if tx:
            p = ext.get(tx.group(1), "?")
            wh = subprocess.run(["magick", "identify", "-format", "%wx%h", root + "/" + p.replace("res://", "")], capture_output=True, text=True).stdout
            info += f" tex={os.path.basename(p)} {wh}"
        print(info)
