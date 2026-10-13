import json, re, subprocess, sys
root = sys.argv[1]
plan = {
 "Street": ("FireLight", ["MidLayer/Pole1", "MidLayer/Pole2", "MidLayer/BusStop1", "Points/Poster/Pole"]),
 "Clinic": ("WindowLight", ["MidLayer/IVStand1", "MidLayer/IVStand2", "MidLayer/Wheelchair1", "MidLayer/Benches2", "Near/Gurney/Sprite", "Points/Chair/Prop"]),
 "Lab": ("AlarmLight", ["MidLayer/Rack1", "MidLayer/Rack2", "MidLayer/Rack3", "MidLayer/Rack4", "Near/Cart/Sprite"]),
 "Ruins": ("ShelterLight", ["MidLayer/Barricade2", "MidLayer/FireBarrel2", "Near/Barrier/Sprite"]),
 "Home": ("CeilingLight", ["MidLayer/Lamp1", "MidLayer/Table1", "MidLayer/Sofa1", "Near/Wardrobe/Sprite", "Points/Room/Prop"]),
 "Wall": ("WallLight", ["MidLayer/Chair", "Near/Charcoal"]),
}
SPAN = {"Pole1", "Pole2", "Pole", "IVStand1", "IVStand2", "Lamp1"}
out = {}
for area, (light, nodes) in plan.items():
    t = open(f"{root}/scenes/areas/{area}.tscn", encoding="utf-8").read()
    ext = {i: p for p, i in re.findall(r'\[ext_resource type="Texture2D"[^\]]*path="([^"]+)" id="([^"]+)"\]', t)}
    blocks = re.split(r'\n(?=\[node )', t)
    batch = [{"node_path": f"./{light}", "property": k, "value": v} for k, v in
             [("shadow_enabled", True), ("shadow_filter", 1), ("shadow_filter_smooth", 2.0), ("height", 60.0)]]
    creates = []
    for n in nodes:
        parent, name = n.rsplit("/", 1)
        b = next(b for b in blocks if re.match(rf'\[node name="{name}" type="Sprite2D" parent="{parent}"', b))
        tex = ext[re.search(r'texture = ExtResource\("([^"]+)"\)', b).group(1)]
        off = re.search(r'\noffset = Vector2\(([^,]+), ([^)]+)\)', b)
        ox, oy = (float(off.group(1)), float(off.group(2))) if off else (0, 0)
        poly = json.loads(subprocess.run(["python3", f"{root}/art/tools/occluder_poly.py", tex.replace("res://", root + "/"), "1"] + (["span"] if name in SPAN else []), capture_output=True, text=True).stdout)
        creates.append(n)
        batch.append({"node_path": f"./{n}/Occluder", "property": "occluder", "value": {"type": "NewResource", "class": "OccluderPolygon2D", "properties": {"polygon": {"type": "PackedVector2Array", "values": [{"type": "Vector2", "x": x + ox, "y": y + oy} for x, y in poly]}}}})
    out[area] = {"creates": creates, "batch": batch}
json.dump(out, open(sys.argv[2], "w"), ensure_ascii=False)
for a, v in out.items():
    print(a, v["creates"], [len(e["value"]["properties"]["polygon"]["values"]) for e in v["batch"][4:]])
