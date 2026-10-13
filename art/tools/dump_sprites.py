import re, sys, subprocess
root, name = sys.argv[1], sys.argv[2]
t = open(f"{root}/scenes/areas/{name}.tscn", encoding="utf-8").read()
ext = {i: p for p, i in re.findall(r'\[ext_resource type="Texture2D"[^\]]*path="([^"]+)" id="([^"]+)"\]', t)}
for b in re.split(r'\n(?=\[node )', t):
    m = re.match(r'\[node name="([^"]+)" type="([^"]+)" parent="((?:Near|MidLayer|Points)[^"]*)"', b)
    if not m: continue
    n, typ, parent = m.groups()
    if typ not in ("Sprite2D","StaticBody2D","Area2D"): continue
    g = lambda k: (re.search(rf'\n{k} = ([^\n]+)', b) or [None,None])[1]
    tex = re.search(r'texture = ExtResource\("([^"]+)"\)', b)
    size = ""
    if tex:
        p = ext[tex.group(1)].replace("res://", root+"/")
        try: size = subprocess.run(["magick","identify","-format","%wx%h",p],capture_output=True,text=True).stdout
        except: pass
    print(f"{parent}/{n} {typ} pos={g('position')} scale={g('scale')} off={g('offset')} tex={size}")
