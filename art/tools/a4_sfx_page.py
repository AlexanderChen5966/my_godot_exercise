import json, sys, os, html
O = sys.argv[1]
log = json.load(open(os.path.join(O, "_log.json"), encoding="utf-8"))
LIC = {"pfranzen": "CC BY 4.0（要標示 pfranzen）", "cosmicembers": "CC BY 3.0（要標示 cosmicembers）",
       "rambler52": "CC BY 4.0（要標示 rambler52）", "metris": "CC BY 4.0（要標示 Metris）",
       "synth": "Claude 合成", "UI": "Claude 合成"}
GOAL = {
 "F1 水泥腳步": ("step_concrete_1～3", "停車場、設施走廊、牆前。挑 3 個（遊戲隨機輪流）"),
 "F2 碎玻璃腳步": ("step_glass_1～3", "街道、診所、廢墟。挑 3 個"),
 "F3 木頭腳步": ("step_wood_1～3", "舊家。挑 3 個"),
 "I1 調查": ("inspect", "調查時（配合伸手）"),
 "I2 撿起": ("pickup", "撿起錄音筆、照片"),
 "I3 鐵門": ("door_metal", "停車場、設施走廊的出口"),
 "I4 木門": ("door_wood", "舊家的門"),
 "E1 心跳": ("heartbeat", "衝動機制。a1 單拍＝遊戲自己補第二拍（現在的做法）"),
 "E2 低吼": ("growl", "選「撲上去」類選項、感染者群"),
 "E3 槍聲": ("gunshot", "Bad End 槍聲"),
 "E4 撞鐵絲網": ("fence", "撲向妻子、撞上鐵絲網"),
 "E5 婦人尖叫": ("scream", "婦人尖叫（A3 的動畫）"),
 "A1 停車場": ("amb_parking", "環境音（循環）"), "A2 街道": ("amb_street", "環境音（循環）"),
 "A3 診所": ("amb_clinic", "環境音（循環）"), "A4 設施走廊": ("amb_lab", "環境音（循環）"),
 "A5 廢墟": ("amb_ruins", "環境音（循環）"), "A6 舊家": ("amb_home", "環境音（循環）"),
 "A7 牆前": ("amb_wall", "環境音（循環），刻意很小聲"),
 "L1 火": ("loop_fire", "街道的車、廢墟的火桶（走近變大聲）"),
 "L2 警報": ("loop_alarm", "設施走廊的警示燈"),
 "L3 避難所": ("loop_shelter", "避難所（隔著圍籬）"),
 "L4 燈管": ("loop_lamp", "停車場燈管（a1 嗡聲循環；b1 是閃的時候播一次）"),
 "M1 Bad End": ("bgm_bad", "3 個 Bad End 的音樂"),
 "M2、M3": ("bgm_shelter／bgm_title", "選做：避難所、標題畫面各挑一首，或都不用"),
 "UI 介面音": ("ui_cursor／ui_confirm／ui_cancel", "選項游標移動、確認、取消（a 組或 b 組）"),
}
groups = {}
for folder, name, note, dur in log:
    groups.setdefault(folder, []).append((name, note, dur))
def lic(folder, name):
    for k, v in LIC.items():
        if k.lower() in (folder + name).lower():
            return v
    if "M2" in folder:
        return "Pixabay Content License"
    if name.startswith("k") or "kenney" in name:
        return "CC0（Kenney）"
    return "CC0"
rows = []
for folder, items in groups.items():
    tgt, use = GOAL.get(folder, ("", ""))
    loop = folder[0] in "AML" and "oneshot" not in "".join(n for n, _, _ in items) or folder[0] in "AM"
    rows.append(f'<section><h2>{html.escape(folder)}</h2><p class="meta">檔名 <code>{tgt}</code>・{html.escape(use)}</p><ul>')
    for name, note, dur in items:
        lp = (folder[0] in "AM" or (folder[0] == "L" and "oneshot" not in name))
        rid = html.escape(folder + "/" + name)
        rows.append(
            f'<li><label><input type="checkbox" data-id="{rid}"> <b>{html.escape(name.rsplit(".",1)[0])}</b></label>'
            f'<span class="note">{html.escape(note)}・{dur:.1f} 秒・{html.escape(lic(folder, name))}{"・循環播放" if lp else ""}</span>'
            f'<audio controls preload="none" {"loop" if lp else ""} src="{html.escape(folder)}/{html.escape(name)}"></audio></li>')
    rows.append("</ul></section>")
page = f'''<!doctype html><html lang="zh-Hant-TW"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>A4 聲音試聽</title><style>
:root{{--bg:#f6f5f2;--fg:#222;--muted:#666;--card:#fff;--line:#ddd;--acc:#8a3b2a}}
@media (prefers-color-scheme:dark){{:root{{--bg:#16181b;--fg:#e8e6e1;--muted:#9a978f;--card:#1f2226;--line:#33373c;--acc:#e08a6a}}}}
body{{background:var(--bg);color:var(--fg);font:15px/1.6 -apple-system,"PingFang TC",sans-serif;margin:0;padding:16px}}
main{{max-width:880px;margin:auto}} h1{{font-size:22px}} h2{{font-size:17px;margin:0 0 2px;color:var(--acc)}}
section{{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:12px 14px;margin:12px 0}}
.meta,.note{{color:var(--muted);font-size:13px}} ul{{list-style:none;padding:0;margin:6px 0 0}}
li{{display:grid;grid-template-columns:1fr;gap:2px;padding:8px 0;border-top:1px solid var(--line)}}
audio{{width:100%;height:34px}} code{{font-size:12px}}
#out{{position:sticky;bottom:0;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:10px;margin-top:12px}}
textarea{{width:100%;height:90px;box-sizing:border-box;background:var(--bg);color:var(--fg);border:1px solid var(--line)}}
button{{font:inherit;padding:4px 12px}}
</style></head><body><main><h1>失語者 A4 聲音試聽</h1>
<p class="meta">勾選你要的檔案（腳步各挑 3 個，其他各挑 1 個；都不喜歡就不勾，在下面備註）。按「複製選擇結果」，貼給 Claude。音量已經大致一致，遊戲裡會再依類別調整。循環類會自動重播，可以聽接縫。</p>
{"".join(rows)}
<div id="out"><textarea id="t" placeholder="備註（例如：A3 都不喜歡、E2 想要更低沉）"></textarea>
<button id="c">複製選擇結果</button> <span id="s" class="note"></span></div></main>
<script>
document.getElementById("c").onclick=()=>{{
 const sel=[...document.querySelectorAll("input:checked")].map(i=>i.dataset.id);
 const txt="A4 選擇：\\n"+sel.join("\\n")+"\\n備註："+document.getElementById("t").value;
 navigator.clipboard.writeText(txt).then(()=>document.getElementById("s").textContent="已複製 "+sel.length+" 個",
  ()=>{{document.getElementById("t").value=txt;document.getElementById("s").textContent="無法自動複製，請手動複製上面的文字";}});
}};
document.addEventListener("play",e=>document.querySelectorAll("audio").forEach(a=>{{if(a!==e.target)a.pause();}}),true);
</script></body></html>'''
open(os.path.join(O, "試聽.html"), "w", encoding="utf-8").write(page)
print("ok")
