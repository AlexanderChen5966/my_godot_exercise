# 失語者 v1.5 素材需求清單

| 項目 | 內容 |
|---|---|
| 依據 | `docs/story_v1.5_outline.md`、`docs/story_v1.5_draft.md`（皆已定稿） |
| 誰準備 | **背景、BGM、音效：作者**（用下面的提示詞生成）；**像素角色與道具：Claude 用 Pixelorama MCP 畫** |
| 交付方式 | 放進對應資料夾，告訴 Claude 即可；Claude 負責匯入設定（音效關閉循環）與接進遊戲 |
| 素材到之前 | 先用現有的圖和音樂代替（見每一項的「暫用」），不會卡住開發 |

**優先順序**
- **Lv4**：街道、診所的背景，撿東西的音效。
- **Lv5**：其餘區域的背景、Bad End 的圖和音樂、其他音效。

---

## 0. 共通規格與畫風

### 現有畫風（給生圖工具參考）
現有 20 張背景是**電影感的數位繪畫**：琥珀、褐色的暖光，配上深青色的陰影；光線像從霧裡透出來，有顆粒感；末日、廢墟、壓抑而悲傷。很多張是**第一人稱視角**（畫面裡有主角的手）。

### 可走動區域的背景（第 1 節）和過場圖不同
- **橫向全景**：鏡頭與地面平行，像舞台側面，**不要**透視很深的走廊或第一人稱視角。
- **畫面裡不要有人、不要有手**：主角和其他人物是另外畫的像素角色。
- **下方約 1/6 留給地面**：角色站在離畫面底部約 128px 的地方。
- 尺寸：**1536×768（2:1）**。區域寬 2304，但遠景只以 0.3 倍速移動，走完整個區域只會用到約 1500 寬的背景（Lv4-4 實測）；遊戲會等比例縮放到剛好蓋滿（1536×768 左右各裁約 18px），所以**重要的東西不要貼著畫面邊緣**。生成工具做不到 2:1 時，1152×768 也可以（會放大約 1.3 倍，上下各裁掉約 115px）。
- 格式：webp 或 png，放在 `assets/bg/`。

### 每一張背景提示詞都加上這段（風格）
```
dark cinematic digital painting, painterly brushwork, muted amber and sepia light with deep teal shadows, volumetric haze, film grain, post-apocalyptic, melancholic and quiet atmosphere
```

### 可走動區域的背景，再加上這段（構圖）
```
wide side-view panorama, camera parallel to the ground at eye level, flat stage-like composition, empty floor along the bottom sixth of the image, no people, no hands, no text
```
負面提示詞（工具有這個欄位時）：
```
people, person, hands, first-person view, text, watermark, deep perspective corridor, fisheye
```

---

## 1. 可走動區域的背景（作者準備）

| # | 檔名 | 區域 | 用在 | 暫用 |
|---|---|---|---|---|
| B1 | `area_street.webp` | ② 街道 | Lv4 | `scene_03.webp` |
| B2 | `area_clinic.webp` | ③ 診所（室內） | Lv4 | `scene_04.webp`（室外，不太合） |
| B3 | `area_lab.webp` | ④ 設施走廊 | Lv5 | `scene_13.webp` |
| B4 | `area_ruins.webp` | ⑤ 廢墟與避難所 | Lv5 | `scene_09.webp` |
| B5 | `area_home.webp` | ⑥ 舊家（室內） | Lv5 | `scene_14.webp` |
| B6 | `area_wall.webp` | ⑦ 牆前 | Lv5 | `scene_16.webp` |

### B1 街道 `area_street.webp`
塌陷的道路、焦黑的車體還在燃燒、電線桿歪斜（上面會貼尋人啟事，啟事本身由 Claude 畫成像素道具）。右邊遠處看得到一間爬滿藤蔓的小診所。黃昏，橘色的天空。
```
a collapsed city street at dusk, cracked asphalt with a sinkhole, burnt-out cars with small fires still burning, a tilted utility pole, abandoned shops, on the far right a small clinic covered in ivy, orange hazy sky
```

### B2 診所（室內） `area_clinic.webp`
廢棄的小診所：左邊是候診區（倒下的椅子、藥櫃），中間是一扇通往治療室的門，右邊是治療室（牆上貼著發音練習的圖卡、一張診療椅）。爬藤從破窗伸進來，陽光斜照、灰塵飄浮。
```
interior of an abandoned small clinic, left side a waiting area with toppled chairs and a medicine cabinet, center a doorway, right side a small speech therapy room with picture cards pinned on the wall and a single treatment chair, ivy growing through broken windows, slanted sunbeams with floating dust
```

### B3 設施走廊 `area_lab.webp`
研究設施的走廊失控：紅色警示燈、地上的碎玻璃、遠處有火光與濃煙，牆邊有觀察窗和散落的文件，右邊盡頭是一扇破掉的鐵門，門外是夜晚的城市。
```
a research facility corridor in chaos, red emergency lights, shattered glass on the floor, fire and thick smoke in the distance, observation windows and scattered documents along the wall, on the far right a broken steel door opening to a dark city at night
```

### B4 廢墟與避難所 `area_ruins.webp`
左半邊是城市廢墟（瓦礫、殘火、窄巷），右半邊是用鐵絲網圍起來的避難所，裡面亮著溫暖的燈（這是整個遊戲少數溫暖的光）。夜晚。
```
city ruins at night, left half rubble and small fires and a narrow alley, right half a makeshift survivor shelter enclosed by a chain-link fence with warm glowing lights inside, the warm light contrasting with the cold dark ruins
```

### B5 舊家（室內） `area_home.webp`
斷壁殘垣的公寓客廳：左邊是有蠟筆字的牆（字由遊戲另外疊上，背景**不要**畫字）、中間是女兒房間的門（看得到小床）、右邊是一扇窗，窗外是街道。從屋頂破洞透進一道光。
```
interior of a ruined apartment living room, left a blank wall with faint crayon marks, center an open doorway to a child's bedroom with a small bed, right a window looking out to the street, a beam of light through a hole in the ceiling, dust and debris, family photos on the floor
```

### B6 牆前 `area_wall.webp`
殘破的屋子，正中間是一面空白的牆（「我還在」由遊戲疊上），氣氛比其他區域更安靜、更空。冷色調，只有牆上有一道柔和的光。
```
an empty ruined room, a single bare wall at the center lit by one soft beam of light, very quiet and still, cold tones except the warm light on the wall, minimal composition
```

---

## 2. 過場與 Bad End 的圖（作者準備）

過場（搜捕隊、手術台、營火）和三個結局**沿用現有的圖**，不用新做。只需要一張新的：

| # | 檔名 | 用在 | 尺寸 | 暫用 |
|---|---|---|---|---|
| B7 | `bad_end.webp` | 3 個 Bad End 共用 | 1152×768（和現有過場圖相同，可以有人物） | `scene_17.webp` |

### B7 Bad End `bad_end.webp`
不是血腥的畫面，而是「失去」：一隻垂下的感染者的手，旁邊掉著一張照片（或錄音筆），被冷色的光照著，周圍一片黑。
```
dark cinematic digital painting, a limp gray-skinned hand resting on a cold floor, a faded photograph of a father and a little girl lying beside it, a single cold beam of light, everything else fading into darkness, quiet tragedy, no blood, no gore, film grain
```

---

## 3. 背景音樂（作者準備）

各區域先**沿用現有的 BGM**：

| 區域／過場 | BGM |
|---|---|
| 停車場 | `bgm_01` |
| 街道 | `bgm_03` |
| 診所 | `bgm_04` |
| 搜捕隊 | `bgm_06` |
| 手術台 | `bgm_07` |
| 設施走廊 | `bgm_08` |
| 廢墟 | `bgm_09` |
| 舊家 | `bgm_10` |
| 營火 | `bgm_15` |
| 牆前 | `bgm_16` |
| 結局 A／B／C | `bgm_18`／`bgm_19`／`bgm_20` |

只需要新做：

| # | 檔名 | 用在 | 優先 | 暫用 |
|---|---|---|---|---|
| M1 | `bgm_bad.ogg` | 3 個 Bad End | Lv5 | `bgm_17.ogg` |
| M2（選做） | `bgm_shelter.ogg` | 廢墟與避難所（看見妻子的區域） | Lv5 | `bgm_09.ogg` |

格式：ogg，1.5～3 分鐘，**頭尾能無縫循環**（專案會自動循環播放），放在 `assets/bgm/`。

### M1 Bad End `bgm_bad.ogg`
很慢、很空，像一切停止了。低沉的長音、偶爾一聲走音的鋼琴，沒有節奏。
```
dark ambient, very slow, sparse detuned piano notes over a deep low drone, sense of loss and emptiness, no drums, no melody resolution, seamless loop, 60 BPM
```

### M2 避難所（選做） `bgm_shelter.ogg`
在廢墟的冷之中，有一點點溫暖但遙不可及的感覺。大提琴與鋼琴，旋律溫柔但帶著距離。
```
melancholic cinematic, solo cello and soft piano, a gentle warm melody heard from far away, bittersweet longing, sparse and quiet, no drums, seamless loop, 70 BPM
```

---

## 4. 音效（作者準備）

格式：ogg，放在 `assets/sfx/`。**Claude 匯入時會關閉循環**（專案預設 ogg 都會循環，見 `CLAUDE.md`）。

| # | 檔名 | 用在 | 長度 | 優先 |
|---|---|---|---|---|
| S1 | `pickup.ogg` | 撿到物品（錄音筆、筆記本） | 0.5～1 秒 | **Lv4** |
| S2 | `heartbeat.ogg` | 衝動機制：靠近人類時 | 1～2 秒（遊戲會重複播放） | Lv5 |
| S3 | `growl.ogg` | 衝動失控（撲上去） | 1～2 秒 | Lv5 |
| S4 | `gunshot.ogg` | BE1 槍聲 | 1～2 秒（含回音） | Lv5 |
| S5 | `alarm.ogg` | 設施走廊的警報 | 2～4 秒（遊戲會重複播放） | Lv5 |
| S6 | `fence.ogg` | BE3：撞上鐵絲網 | 1 秒 | Lv5（選做） |

提示詞（給 AI 音效工具）：

| # | 提示詞 |
|---|---|
| S1 | `soft pickup sound, small plastic object picked up from a dusty shelf, subtle, short, no music` |
| S2 | `slow heavy heartbeat, muffled, as heard from inside the body, tense, two beats` |
| S3 | `low guttural growl of an infected human, raspy throat, restrained, short` |
| S4 | `single distant gunshot echoing through an empty city street, long reverb tail` |
| S5 | `facility emergency alarm, two-tone siren, slightly distorted, echoing in a corridor` |
| S6 | `body hitting a chain-link fence, metal rattle, short` |

---

## 5. 像素角色與道具（Claude 用 Pixelorama MCP 畫，作者確認）

規格和主角一致：像素風、放大 2 倍顯示、光源左上、用主角的調色盤延伸。

| 類型 | 內容 | 用在 |
|---|---|---|
| 道具 | 錄音筆、照片、尋人啟事、治療室字卡、診療椅、筆記本、實驗紀錄 | Lv4（前 5 個）、Lv5 |
| 人物 | 婦人、女科學家、警衛、感染者群、妻子、女兒 | Lv5（停車場的婦人可在 Lv4 先換掉目前的色塊） |
| 文字疊加 | 牆上的蠟筆字、「我還在」 | Lv5（用遊戲的文字或像素字疊在背景上） |

---

## 6. 作者準備的清單（勾選用）

**Lv4 需要**
- [ ] B1 `area_street.webp`
- [ ] B2 `area_clinic.webp`
- [ ] S1 `pickup.ogg`

**Lv5 需要**
- [ ] B3 `area_lab.webp`
- [ ] B4 `area_ruins.webp`
- [ ] B5 `area_home.webp`
- [ ] B6 `area_wall.webp`
- [ ] B7 `bad_end.webp`
- [ ] M1 `bgm_bad.ogg`
- [ ] M2 `bgm_shelter.ogg`（選做）
- [ ] S2～S5（S6 選做）

沒有準備好的項目都有暫用素材，不會卡住開發。
