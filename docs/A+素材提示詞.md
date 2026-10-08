# 失語者 A＋素材提示詞

給外部 AI 工具用的提示詞（生圖、Suno、音效工具）。方案見 `docs/A+方案.md`。
v1.5 的素材清單 `docs/asset_requests.md` 仍然有效：**還沒交付的 B1～B7、M1～M2、S1～S6 直接併入本文件**，不用重複準備。

| 節 | 內容 | 用在 | 誰產生 |
|---|---|---|---|
| 1 | 遠景背景 7 張 | A1 | 作者用生圖 AI |
| 2 | 背景音樂 | A4 | **免費素材為主**；找不到再用 Suno 或 ElevenLabs |
| 3 | 音效與環境音 | A4 | **免費素材為主**（作者下載）；找不到再用 AI 補 |
| 4 | Claude 自己做的素材 | A1～A5 | Claude |
| 5 | 勾選清單 | — | — |

---

## 1. 遠景背景（A1）

### 和 v1.5 素材清單的差別

A＋ 把畫面拆成五層。**遠景只放「遠處」的東西**：天空、遠方建築、室內的後牆。
門、櫃子、柱子、車、圍籬、牆上的字等**會被玩家互動或擋在前面的東西，都由 Claude 畫成像素物件**，所以遠景裡不要畫，否則會重複或對不上位置。

### 規格

- 尺寸 **1536×768**（2:1）；做不到時 1152×768 也可以。
- 格式 webp 或 png，放在 `assets/bg/`，檔名照下表。
- 遠景只以 0.2～0.3 倍速移動，**重要的東西放在畫面中間 70%**，左右邊緣會被裁掉一些。
- 下方 1/6 會被像素地面蓋住，畫成模糊的地面或陰影即可。
- 每張產生 2～4 個候選，挑一張；不滿意可以把結果貼給 Claude，Claude 會調整提示詞。

### 每一張都加上的風格（和 v1.5 相同）

```
dark cinematic digital painting, painterly brushwork, muted amber and sepia light with deep teal shadows, volumetric haze, film grain, post-apocalyptic, melancholic and quiet atmosphere
```

### 每一張都加上的構圖（A＋ 遠景版）

```
background layer only, wide side-view panorama, camera parallel to the ground at eye level, distant elements only, soft depth haze, empty and slightly blurred bottom sixth, no foreground objects, no people, no hands, no text, no doors in the foreground
```

負面提示詞（工具有這個欄位時）：
```
people, person, hands, first-person view, text, letters, watermark, deep perspective corridor, fisheye, foreground clutter
```

### 各區域

| # | 檔名 | 區域 | 取代的暫用圖 |
|---|---|---|---|
| P1 | `area_parking.webp` | 停車場 | `scene_01.webp` |
| P2 | `area_street.webp` | 街道（＝v1.5 的 B1） | `scene_03.webp` |
| P3 | `area_clinic.webp` | 診所室內（＝B2） | `scene_04.webp` |
| P4 | `area_lab.webp` | 設施走廊（＝B3） | `scene_13.webp` |
| P5 | `area_ruins.webp` | 廢墟與避難所（＝B4） | `scene_09.webp` |
| P6 | `area_home.webp` | 舊家室內（＝B5） | `scene_14.webp` |
| P7 | `area_wall.webp` | 牆前（＝B6） | `scene_16.webp` |

**P1 停車場**（新增）
```
an underground parking garage seen from the side, rows of concrete pillars fading into darkness, low ceiling with broken fluorescent tubes, a few distant abandoned cars in silhouette, cold teal darkness with a single faint red emergency light far away, damp stains on the walls
```

**P2 街道**
```
a collapsed city street at dusk seen from the side, row of abandoned shops and apartment facades, smoke rising from far away, tilted power lines against an orange hazy sky, a small ivy-covered clinic far on the right side
```

**P3 診所室內**
```
the back wall of an abandoned small clinic interior, peeling pale green paint, a large broken window with ivy growing in, slanted sunbeams with floating dust, faded medical posters without readable text, a dark doorway in the middle distance
```

**P4 設施走廊**
```
the back wall of a research facility corridor in chaos, long observation windows with shattered glass, red emergency lights along the ceiling, fire glow and thick smoke far in the distance, cold steel panels, dark city night visible through a far broken wall on the right
```

**P5 廢墟與避難所**
```
city ruins at night seen from the side, collapsed buildings and distant small fires on the left, on the right far behind a makeshift survivor shelter with warm glowing windows and string lights, cold blue darkness contrasted with the distant warm light
```

**P6 舊家室內**
```
the back wall of a ruined apartment living room, faded floral wallpaper peeling off, a beam of light falling through a hole in the ceiling, dust in the air, a dark hallway in the middle distance, family photos hanging crooked, no readable text
```

**P7 牆前**
```
an empty ruined room seen straight from the side, one bare plaster wall in the center lit by a single soft warm beam of light, everything else cold and dark, very quiet and still, minimal composition
```

---

## 2. 背景音樂（A4）

**先找免費素材**（Freesound、Pixabay Music、OpenGameArt、Incompetech 等），用下方各曲的描述當搜尋方向；找不到適合的，再用 Suno 產生。本專案非商業用途，非商業授權的音樂也可以用，記得寫進 `docs/素材來源.md`。

### Suno 的用法（補缺時）

1. 開啟 **Instrumental**（純音樂，不要歌詞）。
2. 把「風格」欄的提示詞貼進 Style of Music；歌詞欄留空，或只放結構標籤（見各曲）。
3. 每首產生 2 個版本以上，挑一個下載 mp3／wav。
4. 檔案交給 Claude：Claude 會轉成 ogg、找出可以**無縫循環**的位置、調整音量和現有 BGM 一致。
5. Suno 免費方案可以非商業使用；公開發布前確認當下的條款，並寫進 `docs/素材來源.md`。

### 曲目

| # | 檔名 | 用在 | 優先 | 暫用 |
|---|---|---|---|---|
| M1 | `bgm_bad.ogg` | 3 個 Bad End（＝v1.5 的 M1） | 高 | `bgm_17.ogg` |
| M2 | `bgm_shelter.ogg` | 廢墟與避難所（＝v1.5 的 M2） | 中 | `bgm_09.ogg` |
| M3 | `bgm_title.ogg` | 標題畫面（新增，選做） | 低 | `bgm_15.ogg` |

**M1 Bad End**
```
Style: dark ambient, very slow, sparse detuned piano notes over a deep low drone, distant reverb, sense of loss and emptiness, no drums, no melody resolution, 60 BPM, instrumental
Structure tags: [Intro] [Ambient] [Outro]
```

**M2 避難所**
```
Style: melancholic cinematic, solo cello and soft felt piano, a gentle warm melody heard from far away, bittersweet longing, sparse and quiet, no drums, 70 BPM, instrumental
Structure tags: [Intro] [Theme] [Theme] [Outro]
```

**M3 標題**
```
Style: post-apocalyptic cinematic ambient, lonely music box melody over soft strings and a low cello drone, faint vinyl crackle, tender and haunting, a father's lost memory, no drums, 66 BPM, instrumental
Structure tags: [Intro] [Theme] [Outro]
```

> 用 ElevenLabs `compose_music` 時，把 Style 那一行當成提示詞，長度設 90～150 秒。

---

## 3. 音效與環境音（A4）

### 原則：免費素材為主，AI 補缺

本專案是**實驗用、沒有商業用途**（作者 2026-10-08），所以只要授權允許個人／非商業使用就可以用，**以找到適合的聲音為最優先**。

下面表格的英文提示詞，**同時當作免費素材網站的搜尋關鍵字**（取其中 2～4 個關鍵詞搜尋，例如 `footstep concrete shuffle`、`parking garage ambience drip`）。

| 來源 | 授權（大致，以網站當下說明為準） | 適合 |
|---|---|---|
| **Freesound**（freesound.org） | 每個檔案不同：CC0／CC-BY／CC-BY-NC（非商業可用） | 幾乎所有項目，尤其環境音、低吼、心跳；要註冊才能下載 |
| **Sonniss GDC 音效包** | 免費、可商用 | 專業錄音的環境音、門、槍聲；檔案很大，挑需要的 |
| **BBC Sound Effects** | 只限個人、教育、研究用途（RemArc 授權，比一般「非商業」更窄） | 環境音、生活音，品質很好；**公開放上 itch.io 前要再確認**，優先用 Freesound、Sonniss、Kenney |
| **Kenney**（kenney.nl） | CC0 | 介面音、腳步、開門 |
| **Pixabay 音效** | Pixabay 授權 | 一般音效、環境音 |
| **OpenGameArt** | 每個素材不同 | 遊戲音效 |
| **Zapsplat** | 免費版需標示作者 | 量很大 |

**比較難找到合適的**（建議直接用 AI 補）：E2 感染者低吼、E5 婦人尖叫、E6 記憶閃回音。

### 工具

- **免費素材**：作者下載，放在專案外的暫存資料夾（例如 `~/Desktop/失語者_sfx候選/`），每種可以多放幾個候選；Claude 負責轉檔、裁切、音量一致化、接成無縫循環，作者聽過挑選。
- **補缺：ElevenLabs MCP 的 `text_to_sound_effects`**：Claude 產生 2～3 個候選放在暫存資料夾，作者挑選。**每次呼叫會消耗點數**，Claude 只在作者同意的範圍內呼叫。也可以由作者在 ElevenLabs 網站或其他音效工具貼提示詞產生。
- 格式：ogg（或 wav），放在 `assets/sfx/`。**除了環境音，全部關閉循環。**
- 環境音：產生 10～20 秒即可，Claude 會用淡入淡出接成無縫循環。

### 腳步與互動

| # | 檔名 | 提示詞 | 長度 |
|---|---|---|---|
| F1 | `step_concrete_1～3.ogg` | `single dragging footstep on dusty concrete, shuffling, slightly uneven, close, dry` | 0.3～0.5 秒 |
| F2 | `step_glass_1～3.ogg` | `single dragging footstep crunching on broken glass and debris, close` | 0.3～0.5 秒 |
| F3 | `step_wood_1～3.ogg` | `single slow footstep on old creaky wooden floor, close` | 0.4～0.6 秒 |
| I1 | `inspect.ogg` | `hands rummaging through dusty debris and paper, short, close` | 0.5～1 秒 |
| I2 | `pickup.ogg`（＝v1.5 S1） | `soft pickup sound, small plastic object picked up from a dusty shelf, subtle, short, no music` | 0.5～1 秒 |
| I3 | `door_metal.ogg` | `heavy steel stairwell door pushed open, rusty hinge creak, echo in a concrete space` | 1～2 秒 |
| I4 | `door_wood.ogg` | `old wooden door slowly creaking open, quiet room` | 1～2 秒 |

> 腳步每種做 3 個變化，遊戲會隨機輪流播放，聽起來比較自然。

### 事件

| # | 檔名 | 提示詞 | 長度 |
|---|---|---|---|
| E1 | `heartbeat.ogg`（＝S2，取代暫用的 `heartbeat.wav`） | `slow heavy heartbeat, muffled, as heard from inside the body, tense, two beats` | 1～2 秒 |
| E2 | `growl.ogg`（＝S3） | `low guttural growl of an infected human, raspy throat, restrained, short` | 1～2 秒 |
| E3 | `gunshot.ogg`（＝S4） | `single distant gunshot echoing through an empty city street, long reverb tail` | 1～2 秒 |
| E4 | `fence.ogg`（＝S6） | `body hitting a chain-link fence, metal rattle, short` | 1 秒 |
| E5 | `scream.ogg`（A3 婦人逃跑） | `short frightened scream of a middle-aged woman, distant in a concrete parking garage, echo` | 1～2 秒 |
| E6 | `flashback.ogg`（A5 記憶閃回，選做） | `soft reversed piano swell with tape warble and faint static, dreamlike memory transition` | 1.5～2.5 秒 |

### 環境音（循環）

| # | 檔名 | 區域 | 提示詞 |
|---|---|---|---|
| A1 | `amb_parking.ogg` | 停車場 | `underground parking garage ambience, slow water drips, low electrical hum, distant faint groans, cold empty concrete reverb` |
| A2 | `amb_street.ogg` | 街道 | `desolate city street at dusk, steady wind, distant crackling fire, faint metal creaks, no traffic, no voices` |
| A3 | `amb_clinic.ogg` | 診所 | `quiet abandoned building interior, soft wind through a broken window, rustling ivy leaves, a few distant birds` |
| A4 | `amb_lab.ogg` | 設施走廊 | `research facility in chaos, distant two-tone alarm, fire roar far away, sparking electronics, ventilation hum` |
| A5 | `amb_ruins.ogg` | 廢墟 | `city ruins at night, cold wind, distant infected groans, faint muffled human voices from far away` |
| A6 | `amb_home.ogg` | 舊家 | `empty ruined apartment, soft wind, old wood creaking, a loose curtain flapping gently` |
| A7 | `amb_wall.ogg` | 牆前 | `almost silent empty room, very soft low room tone, faint high ringing like tinnitus` |

### 位置音效（循環，`AudioStreamPlayer2D`，走近變大聲）

| # | 檔名 | 放在 | 提示詞 |
|---|---|---|---|
| L1 | `loop_fire.ogg` | 街道的燃燒車體、走廊的火 | `close crackling car fire, burning debris, steady` |
| L2 | `loop_alarm.ogg`（＝S5） | 設施走廊的警示燈 | `facility emergency alarm, two-tone siren, slightly distorted, echoing in a corridor` |
| L3 | `loop_shelter.ogg` | 避難所 | `muffled murmur of a few survivors behind a fence, quiet campfire crackle, warm` |
| L4 | `loop_lamp.ogg` | 停車場的燈管 | `buzzing flickering fluorescent tube, electrical crackle` |

---

## 4. Claude 自己做的素材

| 素材 | 方式 | 等級 |
|---|---|---|
| 7 個區域的中景、近景、前景剪影 | Pixelorama MCP | A1 |
| 像素地面（可拼接）、醒來處的血跡 | Pixelorama MCP | A1 |
| 法線貼圖 | Python 由 sprite 產生（或 Laigter） | A2 |
| 灰塵、火星、灰燼粒子的小貼圖 | Pixelorama MCP 或程式產生 | A2 |
| 霧、光束 shader | Godot shader | A2 |
| 人物與物件的動畫（第 5 節的 A3 清單） | Pixelorama MCP | A3 |
| 介面音（游標移動、確認、取消） | Python 合成或 Toolkit `sound_generate` | A4 |
| 環境音的無縫循環、音量正規化、格式轉換 | ffmpeg | A4 |
| 記憶閃回的畫面效果（雜訊、褪色） | shader，沿用原本 20 張插畫 | A5 |

---

## 5. 勾選清單

**A1 需要（作者，生圖 AI）**
- [ ] P1 `area_parking.webp`（樣板，最先做）
- [ ] P2 `area_street.webp`
- [ ] P3 `area_clinic.webp`
- [ ] P4 `area_lab.webp`
- [ ] P5 `area_ruins.webp`
- [ ] P6 `area_home.webp`
- [ ] P7 `area_wall.webp`
- [ ] B7 `bad_end.webp`（v1.5 清單，A1 期間任何時候都可以）

**A4 需要**
- [ ] 作者（免費素材）：F1～F3、I1～I4、E1、E3、E4、A1～A7、L1～L4 的候選
- [ ] 作者（免費素材，找不到再用 Suno）：M1 `bgm_bad`、M2 `bgm_shelter`（選做）、M3 `bgm_title`（選做）
- [ ] 補缺（ElevenLabs 或網頁工具，作者同意後）：E2 低吼、E5 尖叫、E6 閃回音，以及其他找不到合適素材的項目
- [ ] Claude：整理候選、寫進 `docs/素材來源.md`

沒有準備好的項目都有暫用素材，不會卡住開發。

---

## 6. 素材來源紀錄（`docs/素材來源.md`）

每個外部素材（免費下載、AI 產生）放進專案時，Claude 在 `docs/素材來源.md` 的表格加一列。**表格格式、授權規則都以 `docs/素材來源.md` 為準**（只留一份，避免兩邊不一致）。

