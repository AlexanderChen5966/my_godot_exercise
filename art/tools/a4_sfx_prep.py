# A4-1c：整理聲音候選（試聽用 WAV）。用法：python3 -I art/tools/a4_sfx_prep.py ~/Desktop/失語者_sfx候選，再用 a4_sfx_page.py 產生試聽網頁
# 單發音效：去掉前後空白、峰值 -3 dBFS；環境音／循環：無縫循環、-22 LUFS；音樂：-15 LUFS（和現有 BGM 一致）
import sys, os, subprocess, array, math, json, glob, random

SRC = sys.argv[1]
OUT = os.path.join(SRC, "整理後")
SR = 44100
random.seed(7)
LOG = []   # (資料夾, 檔名, 說明)


def ff(*args):
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args], check=True)


def src(folder, pattern):
    m = sorted(glob.glob(os.path.join(SRC, folder, pattern)))
    if not m:
        raise SystemExit(f"找不到 {folder}/{pattern}")
    return m[0]


def load(path, ch=1, start=0.0, dur=None, af=None):
    a = ["-ss", str(start)] + (["-t", str(dur)] if dur else []) + ["-i", path]
    if af:
        a += ["-af", af]
    p = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", *a, "-ac", str(ch), "-ar", str(SR),
                        "-f", "f32le", "-"], capture_output=True, check=True)
    x = array.array("f")
    x.frombytes(p.stdout)
    return x


def save(x, folder, name, note, ch=1):
    d = os.path.join(OUT, folder)
    os.makedirs(d, exist_ok=True)
    path = os.path.join(d, name)
    tmp = path + ".raw"
    with open(tmp, "wb") as f:
        x.tofile(f)
    ff("-f", "f32le", "-ar", str(SR), "-ac", str(ch), "-i", tmp, "-c:a", "pcm_s16le", path)
    os.remove(tmp)
    LOG.append((folder, name, note, len(x) / SR / ch))


def env(x, win=0.01):
    n = int(SR * win)
    return [math.sqrt(sum(v * v for v in x[i:i + n]) / n) for i in range(0, len(x) - n, n)]


def peak_norm(x, db=-3.0):
    p = max(abs(v) for v in x) or 1.0
    g = 10 ** (db / 20) / p
    return array.array("f", (v * g for v in x))


def gain(x, db):
    g = 10 ** (db / 20)
    return array.array("f", (v * g for v in x))


def fades(x, fin=0.001, fout=0.05, ch=1):
    x = array.array("f", x)
    n = len(x) // ch
    a, b = int(fin * SR), int(fout * SR)
    for i in range(min(a, n)):
        for c in range(ch):
            x[i * ch + c] *= i / a
    for i in range(min(b, n)):
        for c in range(ch):
            x[(n - 1 - i) * ch + c] *= i / b
    return x


def trim(x, th_db=-45.0, pad=0.02, tail=0.15):
    """去掉前後低於 th_db（相對峰值）的部分"""
    e = env(x)
    p = max(e) or 1.0
    on = [i for i, v in enumerate(e) if v > p * 10 ** (th_db / 20)]
    s = max(0, on[0] * 0.01 - pad)
    t = min(len(x) / SR, on[-1] * 0.01 + 0.01 + tail)
    return x[int(s * SR):int(t * SR)]


def lufs(path):
    p = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", path, "-af", "ebur128", "-f", "null", "-"],
                       capture_output=True, text=True)
    for l in reversed(p.stderr.splitlines()):
        if l.strip().startswith("I:"):
            return float(l.split()[1])
    return -70.0


def loudness_to(x, target, ch=1):
    tmp = os.path.join(OUT, "_tmp.wav")
    raw = tmp + ".raw"
    with open(raw, "wb") as f:
        x.tofile(f)
    ff("-f", "f32le", "-ar", str(SR), "-ac", str(ch), "-i", raw, tmp)
    l = lufs(tmp)
    os.remove(raw)
    os.remove(tmp)
    y = gain(x, target - l)
    p = max(abs(v) for v in y)
    if p > 0.89:   # 峰值不超過 -1 dBFS
        y = gain(y, 20 * math.log10(0.89 / p))
    return y


def make_loop(x, xf, ch=1):
    """x 長度 = 循環長度 + xf；開頭 xf 秒和結尾交叉淡化，首尾相接沒有接縫"""
    n = len(x) // ch - int(xf * SR)
    k = int(xf * SR)
    y = array.array("f", x[:n * ch])
    for i in range(k):
        w = i / k
        for c in range(ch):
            y[i * ch + c] = x[i * ch + c] * math.sqrt(w) + x[(n + i) * ch + c] * math.sqrt(1 - w)
    return y


def steady_windows(path, dur, count=1, skip=2.0):
    """找出音量最平穩的 count 段（不重疊），回傳開始秒數"""
    x = load(path, 1, af="lowpass=3000")
    e = env(x, 0.1)
    w = int(dur * 10)
    cands = []
    for i in range(int(skip * 10), len(e) - w - int(skip * 10), 5):
        seg = e[i:i + w]
        m = sum(seg) / w
        if m <= 1e-5:
            continue
        sd = math.sqrt(sum((v - m) ** 2 for v in seg) / w)
        cands.append((sd / m, i / 10))
    cands.sort()
    picked = []
    for _, s in cands:
        if all(abs(s - p) >= dur for p in picked):
            picked.append(s)
        if len(picked) == count:
            break
    return picked


def loop_from(path, start, dur, xf=2.0, ch=2, target=-22.0, af=None):
    x = load(path, ch, start, dur + xf, af)
    return loudness_to(make_loop(x, xf, ch), target, ch)


def onsets(x, rel=0.2, gap=0.15):
    e = env(x)
    p = max(e)
    out, last = [], -99
    for i in range(1, len(e)):
        if e[i] > p * rel and e[i - 1] <= p * rel and (i - last) * 0.01 > gap:
            out.append(i * 0.01)
            last = i
    return out


def split_events(x, rel=0.2, maxlen=0.6, pre=0.02):
    segs = []
    ons = onsets(x, rel)
    for j, t in enumerate(ons):
        s = max(0.0, t - pre)
        end = min(ons[j + 1] - pre if j + 1 < len(ons) else len(x) / SR, t + maxlen)
        segs.append(x[int(s * SR):int(end * SR)])
    return segs


def best_by_peak(segs, n):
    """挑峰值最接近中位數的 n 個（避免太大或太小聲的步伐）"""
    pk = [max(abs(v) for v in s) for s in segs]
    med = sorted(pk)[len(pk) // 2]
    order = sorted(range(len(segs)), key=lambda i: abs(pk[i] - med))
    return [segs[i] for i in sorted(order[:n])]


def mix(a, b, b_db=0.0, offset=0.0, ch=1):
    n = max(len(a), len(b) + int(offset * SR) * ch)
    y = array.array("f", [0.0]) * n
    for i, v in enumerate(a):
        y[i] += v
    g = 10 ** (b_db / 20)
    o = int(offset * SR) * ch
    for i, v in enumerate(b):
        y[o + i] += v * g
    return y


def oneshot(path, folder, name, note, start=0.0, dur=None, af=None, db=-3.0, fout=0.08, th=-45.0, tail=0.15):
    x = load(path, 1, start, dur, af)
    x = fades(peak_norm(trim(x, th, tail=tail), db), fout=fout)
    save(x, folder, name, note)
    return x


def kenney(folder, names, note):
    for i, nm in enumerate(names):
        p = glob.glob(os.path.join(SRC, "*", "kenney_" + nm))[0]
        oneshot(p, folder, f"k{i + 1}_{nm.replace('.ogg', '')}.wav", note)


def energy_windows(path, dur, count, ch=1):
    x = load(path, 1)
    e = env(x, 0.05)
    w = int(dur / 0.05)
    sc = [(sum(e[i:i + w]), i * 0.05) for i in range(0, len(e) - w, 2)]
    sc.sort(reverse=True)
    picked = []
    for _, s in sc:
        if all(abs(s - p) >= dur for p in picked):
            picked.append(s)
        if len(picked) == count:
            break
    return sorted(picked)


os.makedirs(OUT, exist_ok=True)
COMP = "acompressor=threshold=-24dB:ratio=6:attack=1:release=60:makeup=2"   # 壓住火的劈啪尖峰

# ---------- 腳步 ----------
x = load(src("F1 水泥", "535052*"))
for i, s in enumerate(best_by_peak(split_events(x), 3)):
    save(fades(peak_norm(trim(s)), fout=0.06), "F1 水泥腳步", f"a{i + 1}_patchytherat.wav", "Freesound 一連串腳步切出的單步")
kenney("F1 水泥腳步", [f"footstep_concrete_00{i}.ogg" for i in range(5)], "Kenney 水泥腳步")

x = load(src("F2 碎玻璃", "376459*"))
for i, s in enumerate(best_by_peak(split_events(x, maxlen=0.7), 3)):
    save(fades(peak_norm(trim(s)), fout=0.08), "F2 碎玻璃腳步", f"a{i + 1}_mystikuum.wav", "Freesound 踩玻璃切出的單步")
for i in range(3):   # B：Kenney 水泥腳步＋玻璃碎裂（-9 dB，晚 20ms）
    step = trim(load(glob.glob(os.path.join(SRC, "*", f"kenney_footstep_concrete_00{i}.ogg"))[0]))
    glass = trim(load(glob.glob(os.path.join(SRC, "*", f"kenney_impactGlass_light_00{i}.ogg"))[0]))
    save(fades(peak_norm(mix(peak_norm(step), peak_norm(glass), -9.0, 0.02))), "F2 碎玻璃腳步",
         f"b{i + 1}_kenney_mix.wav", "Kenney 水泥腳步＋玻璃碎裂（混音）")

oneshot(src("F3 木頭", "565489*"), "F3 木頭腳步", "a1_jakegwizdak.wav", "Freesound 木頭腳步（只有一個）")
kenney("F3 木頭腳步", [f"footstep_wood_00{i}.ogg" for i in range(5)], "Kenney 木頭腳步")

# ---------- 互動 ----------
p = src("I1 調查（翻找）", "400656*")
for i, s in enumerate(energy_windows(p, 0.9, 3)):
    oneshot(p, "I1 調查", f"a{i + 1}_lampeight.wav", f"Freesound 翻找（{s:.1f} 秒處）", s, 0.9, fout=0.2)
kenney("I1 調查", ["cloth1.ogg", "cloth3.ogg", "bookFlip2.ogg"], "Kenney 布料／翻書")

oneshot(src("I2 撿起", "332504*"), "I2 撿起", "a1_rambler52.wav", "Freesound（注意：原檔是小貨車開門聲）")
kenney("I2 撿起", ["handleSmallLeather2.ogg", "metalClick.ogg", "beltHandle1.ogg", "bookPlace1.ogg"], "Kenney 小物件")

p = src("I3 鐵門", "429130*")
segs = split_events(load(p), rel=0.15, maxlen=4.0)
save(fades(peak_norm(trim(segs[0], tail=0.4)), fout=0.3), "I3 鐵門", "a1_leonelmail_open.wav", "Freesound 彈簧鐵門（只取開門）")
oneshot(src("I3 鐵門", "700705*"), "I3 鐵門", "b1_mathewhenry.wav", "Freesound 鐵門吱嘎", tail=0.3)
door = load(src("I3 鐵門", "700705*"))
latch = load(glob.glob(os.path.join(SRC, "*", "kenney_metalLatch.ogg"))[0])
save(fades(peak_norm(mix(peak_norm(trim(latch)), peak_norm(trim(door, tail=0.3)), -2.0, 0.12)), fout=0.2), "I3 鐵門",
     "c1_latch_mix.wav", "Kenney 門閂＋鐵門吱嘎（混音）")

oneshot(src("I4 木門", "273466*"), "I4 木門", "a1_jemburyturner.wav", "Freesound 大門吱嘎", tail=0.4, fout=0.3)
kenney("I4 木門", ["doorOpen_1.ogg", "doorOpen_2.ogg"], "Kenney 開門")

# ---------- 事件 ----------
p = src("E1 心跳", "332820*")
x = load(p)
ons = onsets(x, 0.25, 0.08)
gaps = [ons[i + 1] - ons[i] for i in range(len(ons) - 1)]
lub = next(i for i in range(2, len(gaps)) if gaps[i] < 0.45)   # 第一拍（後面緊接第二拍）
s = ons[lub] - 0.02
save(fades(peak_norm(x[int(s * SR):int((s + min(0.3, gaps[lub] - 0.03)) * SR)]), fout=0.06), "E1 心跳",
     "a1_single_beat.wav", "單拍（遊戲會自己播第二拍，延遲 0.16 秒、-5 dB）")
save(fades(peak_norm(x[int(s * SR):int((s + gaps[lub] + 0.35) * SR)]), fout=0.1), "E1 心跳",
     "b1_two_beats.wav", "一組兩拍（原錄音的節奏；要改成整組播放）")

oneshot(src("E2 低吼", "804460*"), "E2 低吼", "a1_oozername.wav", "Freesound 喪屍低吼", tail=0.3, fout=0.25)
p = src("E2 低吼", "500555*")
for i, s in enumerate(energy_windows(p, 1.8, 3)):
    oneshot(p, "E2 低吼", f"b{i + 1}_agaudiodesigns.wav", f"Freesound 男性呻吟（{s:.1f} 秒處）", s - 0.1, 2.0, fout=0.4)

oneshot(src("E3 槍聲", "384715*"), "E3 槍聲", "a1_morganpurkis.wav", "Freesound 遠處槍聲", th=-55, tail=0.8, fout=0.6)
oneshot(src("E3 槍聲", "387477*"), "E3 槍聲", "b1_cosmicembers.wav", "Freesound 遠處槍聲", th=-55, tail=0.8, fout=0.6)

fence = oneshot(src("E4 撞鐵絲網", "236970*"), "E4 撞鐵絲網", "a1_sadc0415.wav", "Freesound 鐵絲網", tail=0.3, fout=0.25)
punch = trim(load(glob.glob(os.path.join(SRC, "*", "kenney_impactPunch_heavy_000.ogg"))[0]))
save(fades(peak_norm(mix(peak_norm(punch), fence, -1.0, 0.01)), fout=0.25), "E4 撞鐵絲網", "b1_body_mix.wav",
     "Kenney 身體撞擊＋鐵絲網（混音）")

p = src("E5 婦人尖叫", "609973*")
oneshot(p, "E5 婦人尖叫", "a1_starnezio.wav", "Freesound 尖叫（原音）", tail=0.2)
oneshot(p, "E5 婦人尖叫", "b1_starnezio_garage.wav", "加上停車場回音、稍微悶一點（像在遠處）",
        af="lowpass=5000,apad=pad_dur=1.2,aecho=0.8:0.55:70|140|260:0.4|0.25|0.15", tail=1.0, fout=0.6)

# ---------- 環境音（循環，立體聲）----------
def amb(folder, path, dur, count, name, note, xf=2.0, af=None, ch=2, target=-22.0):
    outs = []
    for i, s in enumerate(steady_windows(path, dur + xf, count)):
        y = loop_from(path, s, dur, xf, ch, target, af)
        save(y, folder, f"{chr(97 + i)}1_{name}.wav", f"{note}（{s:.0f} 秒處起，{dur:.0f} 秒循環）", ch)
        outs.append(y)
    return outs

amb("A1 停車場", src("A1 停車場", "803970*"), 20, 2, "ixwolf", "Freesound 廢棄地下室低鳴")
amb("A2 街道", src("A2 街道", "871969*"), 20, 2, "kkenny101", "Freesound 陣風")
amb("A3 診所", src("A3 診所", "686762*"), 20, 2, "cyntrix", "Freesound 廢棄建築外")
vent = amb("A4 設施走廊", src("A4 設施走廊", "510475*"), 16, 1, "lydmakeren", "Freesound 通風系統")[0]
siren = load(src("L2 警報", "414494*"), 2, af="lowpass=1500,aecho=0.8:0.6:120|240:0.35|0.2,volume=-16dB")
y = array.array("f", vent)
for t in range(0, 16, 4):       # 每 4 秒疊一次遠處的警報（悶、有回音）
    o = int(t * SR) * 2
    for i, v in enumerate(siren[:min(len(siren), len(y) - o)]):
        y[o + i] += v
save(loudness_to(y, -22.0, 2), "A4 設施走廊", "b1_vent_siren_mix.wav", "通風＋遠處警報（混音）", 2)

wind = amb("A5 廢墟", src("A5 廢墟", "852845*"), 20, 1, "kkenny101", "Freesound 風")[0]
groan = load(src("E2 低吼", "500555*"), 2, energy_windows(src("E2 低吼", "500555*"), 1.8, 1)[0], 2.0,
             af="lowpass=900,aecho=0.8:0.7:180|380:0.4|0.25,volume=-14dB")
y = array.array("f", wind)
for t in (3.0, 13.5):           # 遠處兩聲低吼
    o = int(t * SR) * 2
    for i, v in enumerate(fades(groan, 0.2, 0.6, 2)[:len(y) - o]):
        y[o + i] += v
save(loudness_to(y, -22.0, 2), "A5 廢墟", "b1_wind_groan_mix.wav", "風＋遠處低吼（混音）", 2)

old = amb("A6 舊家", src("A6 舊家", "393808*"), 20, 2, "pfranzen", "Freesound 有風、吱嘎的老房子")
y = array.array("f", old[0])
for t, nm in ((4.0, "creak1"), (12.5, "creak3")):
    c = load(glob.glob(os.path.join(SRC, "*", f"kenney_{nm}.ogg"))[0], 2, af="volume=-10dB")
    o = int(t * SR) * 2
    for i, v in enumerate(c[:len(y) - o]):
        y[o + i] += v
save(loudness_to(y, -22.0, 2), "A6 舊家", "c1_house_creak_mix.wav", "a1＋Kenney 木頭吱嘎（混音）", 2)

# A7 牆前：自己合成（極低的房間聲＋很細的耳鳴，耳鳴慢慢起伏）
tmp = os.path.join(OUT, "_a7.wav")
ff("-f", "lavfi", "-i", "anoisesrc=color=brown:amplitude=0.25:d=22:r=44100", "-f", "lavfi",
   "-i", "aevalsrc='0.012*sin(2*PI*6200*t)*(0.6+0.4*sin(2*PI*t/11))':d=22:s=44100",
   "-filter_complex", "[0]lowpass=300,volume=0.5[a];[a][1]amix=inputs=2:normalize=0", "-ac", "2", tmp)
x = load(tmp, 2)
os.remove(tmp)
save(loudness_to(make_loop(x, 2.0, 2), -30.0, 2), "A7 牆前", "a1_synth_tinnitus.wav", "Claude 合成：低頻房間聲＋細耳鳴（20 秒循環，刻意比別區小聲）", 2)

# ---------- 位置音效（循環，單聲道：走近變大聲、左右聲道由遊戲決定）----------
p = src("L1 火", "564621*")
save(loudness_to(make_loop(load(p, 1, af=COMP), 1.0), -20.0), "L1 火", "a1_nox_sound.wav", "Freesound 火（10 秒循環）")
p = src("L2 警報", "414494*")
save(loudness_to(load(p, 1), -20.0), "L2 警報", "a1_mr_keybored.wav", "Freesound 設施警報（原本就能循環）")
save(loudness_to(load(p, 1, af="aecho=0.8:0.5:90|180:0.3|0.15"), -20.0), "L2 警報", "b1_mr_keybored_echo.wav",
     "加走廊回音（尾巴會疊到下一圈，循環時更連續）")
p = src("L3 避難所", "634880*")
s = steady_windows(p, 22, 1)[0]
walla = load(p, 1, s, 22, af="lowpass=1400")
fire = load(src("L1 火", "564621*"), 1, af=COMP)
fire = array.array("f", (fire * 3)[:len(walla)])
save(loudness_to(make_loop(walla, 2.0), -20.0), "L3 避難所", "a1_walla_muffled.wav", "Freesound 人聲（悶，像隔著圍籬，20 秒循環）")
save(loudness_to(make_loop(mix(walla, fire, -8.0), 2.0), -20.0), "L3 避難所", "b1_walla_fire_mix.wav", "a1＋營火（混音）")
p = src("L4 燈管", "125064*")
s = steady_windows(p, 10, 1, skip=1.0)[0]
save(loudness_to(make_loop(load(p, 1, s, 11), 1.0), -24.0), "L4 燈管", "a1_hum_loop.wav", f"Freesound 燈管嗡聲（{s:.0f} 秒處起，10 秒循環）")
x = load(p, 1)
e = env(x, 0.05)
w = 30
vi = max(range(0, len(e) - w), key=lambda i: max(e[i:i + w]) - min(e[i:i + w]))
oneshot(p, "L4 燈管", "b1_flicker_oneshot.wav", f"啟動器的喀喀聲（{vi * 0.05:.1f} 秒處，燈管閃的時候播一次）", vi * 0.05, 1.5, fout=0.2)

# ---------- 音樂（-15 LUFS，和現有 BGM 一致；結尾和開頭交叉淡化成循環）----------
def music(folder, path, name, note, xf=4.0):
    x = load(path, 2)
    save(loudness_to(make_loop(x, xf, 2), -15.0, 2), folder, name, note, 2)

music("M1 Bad End", src("M1 Bad End", "822541*"), "a1_metris.wav", "Freesound 反轉和弦")
for i, f in enumerate(sorted(glob.glob(os.path.join(SRC, "M2、M3", "*.mp3")))):
    music("M2、M3", f, f"{chr(97 + i)}1_{os.path.basename(f).rsplit('.', 1)[0]}.wav", "Pixabay")

# ---------- 介面音（Claude 合成）----------
def synth(name, expr, d, note):
    tmp = os.path.join(OUT, "_ui.wav")
    ff("-f", "lavfi", "-i", f"aevalsrc='{expr}':d={d}:s=44100", tmp)
    x = load(tmp, 1)
    os.remove(tmp)
    save(fades(peak_norm(x, -6.0), 0.002, 0.02), "UI 介面音", name, note)

synth("a1_cursor.wav", "sin(2*PI*1400*t)*exp(-t*90)", 0.06, "游標移動：短的木頭敲擊感")
synth("a2_confirm.wav", "(sin(2*PI*660*t)*lt(t,0.07)+sin(2*PI*990*t)*gte(t,0.07))*exp(-mod(t,0.07)*30)", 0.16, "確認：兩個音往上")
synth("a3_cancel.wav", "(sin(2*PI*880*t)*lt(t,0.07)+sin(2*PI*587*t)*gte(t,0.07))*exp(-mod(t,0.07)*30)", 0.16, "取消：兩個音往下")
synth("b1_cursor_soft.wav", "sin(2*PI*700*t)*exp(-t*60)*(1+0.3*sin(2*PI*2100*t))", 0.08, "游標移動：比較低、柔")
synth("b2_confirm_soft.wav", "sin(2*PI*523*t)*exp(-t*14)+0.5*sin(2*PI*784*t)*exp(-t*18)", 0.3, "確認：柔和的和弦")

with open(os.path.join(OUT, "_log.json"), "w", encoding="utf-8") as f:
    json.dump(LOG, f, ensure_ascii=False)
print(len(LOG), "個檔案")
