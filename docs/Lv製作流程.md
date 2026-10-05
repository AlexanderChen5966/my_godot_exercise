# 失語者 Lv1～5 製作流程

給作者和 Claude Code 共用的開發流程。路線與決策見 `docs/開發路線圖.md`。

- **Lv1 寫得最詳細**，可以直接開工；分步指令在 `PROMPTS.md`。
- Lv2 之後先寫流程與完成標準，**做到那一級時再補細節與分步指令**（前一級的結果可能改變做法）。

---

## 0. 每一級共通的流程

| 步驟 | 內容 | 誰做 |
|---|---|---|
| 1 | 讀本文件對應章節與 `CLAUDE.md` | Claude |
| 2 | 用 MCP 建場景、節點、設定；用檔案編輯寫 GDScript | Claude |
| 3 | **自我驗證**：`game_start` → `input_simulate` → `runtime_get_node_state`／`runtime_get_script_vars` 讀狀態 → `runtime_screenshot`（disk 模式）→ `debugger_get_log` | Claude |
| 4 | **人試玩**：手感、氛圍、聲音、文字是否通順 | 作者 |
| 5 | 修正，再回到步驟 3 | 兩者 |
| 6 | 匯出 Web 版（排除 `addons/*`），在瀏覽器確認 | Claude 匯出、作者試玩 |
| 7 | 在 `MCP實驗紀錄.md` 新增「LvN」一節，更新 `docs/開發路線圖.md` 的進度紀錄 | Claude 起草、作者確認 |

### 每一級都要記錄的觀察

- 哪些事 Claude 透過 MCP 自己完成？哪些要繞過 MCP（直接改檔案），原因是什麼？
- Claude 能不能**自己發現問題**？例如角色卡住、觸發不到、畫面跑掉。
- 哪些部分只能靠人判斷？（階段 1 的結論是「聲音和手感要靠人」，每一級都檢查這點是否仍成立）
- MCP 工具本身遇到的問題與解法。

### 共通規則

- 每一級做完，遊戲都必須能**從標題畫面一路玩到結局**。
- 不要改寫劇情文字。區域資料用「引用」的方式取用 `data/story.json` 的文字，不複製（見 Lv1 的資料格式）。
- 新增的 ogg 音效要把匯入設定改成不循環（專案預設 ogg 都循環）。
- headless 測試一律對**專案副本**執行（見 `CLAUDE.md`）。

---

## Lv1 開始前的小修正（選做，約 10 分鐘）

> ✅ 2026-10-02 完成。對話框改為 0.62 後，場景 14 的 Body 高度 103 → 126px（內文 108px），結局 18 也沒有捲軸。
> 直式提示是 `Main` 底下的 `RotateHint`（ColorRect + Label），由 `main.gd` 的 `update_rotate_hint()` 依視窗尺寸切換，顯示時會擋住點擊。

來自階段 1 的檢查結果，可以順便練習「小改動也用 MCP 驗證」：

1. **對話框加高**：場景 14 文字最長，對話框會出現捲軸。把 `DialogPanel` 的 `anchor_top` 從 0.65 改成 0.62，`Choices` 的 `anchor_bottom` 同步改成 0.62。用 `execute_code` 跳到場景 14 截圖確認沒有捲軸。
2. **直拿提示**：網頁在直式畫面（高 > 寬）時，顯示一行「請將裝置橫向持握」。

---

## Lv1：停車場可走動（橫向捲軸、替代美術）

### 目標

把原場景 1～2（地下停車場）做成可以左右走動的區域。走到出口後接回原本的視覺小說流程（場景 3 開始），一路玩到結局。

### 範圍

**要做的：**
- 主角左右移動（不能跳），鏡頭跟隨。
- 4 個互動點：2 個調查點、1 個接近觸發、1 個出口。
- 進入區域時顯示開場文字；互動時沿用階段 1 的對話框與打字機效果。
- 鍵盤操作（← → 或 A D 移動；E／空白鍵／Enter 互動）。

**不做的：**跳躍、物理、數值、物品欄、像素角色、景深與光影、觸控操作。

> 📱 **Lv1 起暫不支援手機**（2026-10-02 決定）：可走動的區域只能用鍵盤操作，手機與平板會停在停車場無法前進。觸控操作之後再評估。
>
> ⌨️ **按鍵衝突留待之後處理**（2026-10-02 決定）：`interact` 的空白鍵／Enter 與既有的 `ui_accept`（跳過打字、繼續）重疊，一次按鍵可能同時開啟又關閉文字。Lv1 先照規格做，試玩若出現問題再修正（處理方式：同一個輸入事件只處理一次並 `set_input_as_handled()`，或把 `interact` 改成只有 E）。

### 區域設計

區域寬 2304px（兩個畫面寬），高 768px，地面在 y = 640。

```
x:  160        600          1000           1500           2150
    │ 起點      │ 閃爍的燈光   │ 地面殘骸        │ 婦人（接近）     │ 出口
    ▼           ▼ 調查        ▼ 調查          ▼ 自動觸發一次    ▼ 按鍵離開
────────────────────────────────────────────────────────────────── 地面 y=640
```

| 互動點 | 類型 | 觸發方式 | 顯示的文字（引用 story.json） | 之後 |
|---|---|---|---|---|
| 開場 | intro | 進入區域時 | 場景 1 的標題與主文字 | 開始操作 |
| 閃爍的燈光 | inspect | 靠近後按互動鍵，可重複 | 場景 1「環顧四周」的 response | 回到操作 |
| 地面殘骸 | inspect | 靠近後按互動鍵，可重複 | 場景 2「翻找地面殘骸」的 response | 回到操作 |
| 婦人 | approach | 走進範圍**自動觸發，只一次** | 場景 2 的標題與主文字（婦人驚慌逃去） | 婦人（替代美術）消失 |
| 出口 | exit | 靠近後按互動鍵 | 場景 2「在口袋中搜尋」的 response（找到照片） | 淡出，前往場景 3 |

原場景 1～2 的其他選項（例如「其他行動」「停下不動」）在可移動版不需要：玩家自己站著不動就是那個選擇。

### 資料格式：`data/areas/parking_lot.json`

地圖（互動點的位置）在 Godot 編輯器裡用 MCP 擺放；文字在 JSON 裡，**用引用的方式取自 `data/story.json`**，不複製文字。之後劇本改版時，區域會自動用到新文字。

```json
{
  "id": "parking_lot",
  "scene": "res://scenes/areas/ParkingLot.tscn",
  "replaces_scenes": [1, 2],
  "exit_to": 3,
  "bgm": "bgm_01.ogg",
  "intro": { "from": { "scene": 1 } },
  "points": {
    "light":  { "type": "inspect",  "label": "閃爍的燈光", "from": { "scene": 1, "choice": 0 } },
    "debris": { "type": "inspect",  "label": "地面殘骸",   "from": { "scene": 2, "choice": 1 } },
    "woman":  { "type": "approach", "once": true,          "from": { "scene": 2 } },
    "exit":   { "type": "exit",     "label": "離開停車場", "from": { "scene": 2, "choice": 0 } }
  }
}
```

引用規則：
- `{ "scene": N }` → 場景 N 的 `title`（當對話框標題）與 `text`。
- `{ "scene": N, "choice": i }` → 場景 N 第 i 個選項（從 0 開始）的 `response`；對話框標題用選項的 `text`。

區域接管規則：
- 呼叫 `show_scene(id)` 時，如果某個區域的 `replaces_scenes` 包含這個 id，就**進入該區域**，不顯示視覺小說畫面。
- 因為 `start_id` 是 1，點「開始」後會直接進入停車場，**不需要改 `story.json`**。

### 架構

```
Main (Control)
├── BgLayer (CanvasLayer, layer = -10)        ← 新增：鏡頭不會移動它
│   └── Background (TextureRect)              ← 從 Main 底下移進來
├── World (Node2D)                            ← 新增：區域場景實例化在這裡
├── UILayer (CanvasLayer, layer = 10)         ← 新增：UI 不受鏡頭影響
│   ├── Fade
│   ├── TitleLayer
│   ├── StoryLayer（Choices、DialogPanel）
│   ├── RotateHint                            ← Lv1-0 已建立，搬進 UILayer 時放在最上層
│   └── PromptLabel (Label)                   ← 新增：「E 調查」提示，顯示在畫面下方中央
├── BgmA / BgmB / Sfx / TypeSfx
```

> ⚠️ **最重要的一點**：Camera2D 會移動整個預設畫布。如果 UI 還留在 Main 底下（預設畫布），對話框和標題會跟著鏡頭跑掉。
> 所以 Lv1 的第一步就是把 UI 移進 `UILayer`、背景移進 `BgLayer`，並先確認階段 1 的流程完全沒壞。

區域場景 `scenes/areas/ParkingLot.tscn`：

```
ParkingLot (Node2D)  script: scripts/area.gd（通用，所有區域共用）
├── Backdrop (Sprite2D 或 TextureRect)   scene_01.webp 調暗，鋪滿 2304×768
├── Ground (ColorRect)                   y = 640 以下的地面色塊
├── Player (CharacterBody2D)             script: scripts/player.gd
│   ├── Body (ColorRect)                 替代美術：32×96 的色塊，腳底對齊 y = 640
│   ├── Shape (CollisionShape2D)
│   └── Camera2D                         limit_left = 0, limit_right = 2304, limit_top = 0, limit_bottom = 768
└── Points (Node2D)
    ├── Light  (Area2D + CollisionShape2D)  script: scripts/interact_point.gd, point_id = "light"
    ├── Debris (Area2D …)                    point_id = "debris"
    ├── Woman  (Area2D …)                    point_id = "woman"，另含一個色塊當替代的婦人
    └── Exit   (Area2D …)                    point_id = "exit"
```

腳本分工：
- `scripts/area_data.gd`（`class_name AreaData`）：讀 `data/areas/*.json`，解析 `from` 引用，提供「場景 id → 區域」的查詢。
- `scripts/area.gd`：區域根節點。設定玩家起點與鏡頭範圍；收到互動點訊號時通知 Main。
- `scripts/player.gd`：左右移動，速度約 140 px/秒（主角步履蹣跚，不要太快）；`can_move` 為 false 時不動（對話中）；用 `clamp` 限制在區域範圍內。
- `scripts/interact_point.gd`：`@export var point_id`；玩家進入範圍時發出訊號，讓 Main 顯示提示；`approach` 類型直接觸發。
- `scripts/main.gd`：
  - 狀態新增 `EXPLORE`（可操作）和 `AREA_TEXT`（顯示區域文字，點擊或按互動鍵關閉）。
  - `show_scene(id)` 先檢查 `AreaData`，被區域接管時改呼叫 `enter_area()`。
  - `enter_area()`：淡出 → 實例化區域到 `World` → 隱藏 `Background` → 播放 BGM → 淡入 → 顯示開場文字。
  - `leave_area(next_id)`：淡出 → 釋放區域 → 顯示 `Background` → `show_scene(next_id)`。
  - 對話框沿用 `_type_text()`；顯示區域文字時 `Choices` 保持空白，並隱藏 `Hint`。
  - 回標題時，若 `World` 底下還有區域，要一併釋放。

### 輸入設定（用 MCP 的 input_map 工具，或 `project_set_setting`）

| 動作名稱 | 按鍵 |
|---|---|
| `move_left` | ←、A |
| `move_right` | →、D |
| `interact` | E、空白鍵、Enter |

### 驗證方式（Claude 用 MCP 自我驗證）

| 檢查 | 怎麼做 |
|---|---|
| 階段 1 沒被破壞 | UI 搬進 CanvasLayer 後，從標題玩到場景 3 再到結局，截圖確認版面 |
| 移動 | `input_simulate` 按住 → 鍵約 2 秒，`runtime_get_node_state` 讀 `Player.position.x`，確認增加了約 280 |
| 邊界 | 一直往左走，x 不會小於 0；往右走不會超過 2304 |
| 鏡頭與 UI | 走到區域中段截圖：背景有捲動，對話框、提示文字仍在畫面固定位置 |
| 調查點 | 走到 x ≈ 600，截圖確認出現「E 調查」提示，按互動鍵後對話框顯示正確文字 |
| 接近觸發 | 走過 x ≈ 1500 自動顯示婦人文字；離開再回來**不會**再觸發 |
| 對話中不能移動 | 文字顯示時按 → 鍵，`Player.position.x` 不變 |
| 出口 | 在出口按互動鍵 → 顯示照片文字 → 點擊 → `runtime_get_script_vars` 確認 `current_id == 3`，截圖是場景 3 的視覺小說畫面 |
| 錯誤 | `script_check`、`lsp_project_diagnostics`、`debugger_get_log` 都沒有錯誤 |

### 人要確認的事（作者試玩）

- 走路速度、互動點的間距會不會太遠或太擠？
- 提示文字看不看得清楚？互動按鍵是否直覺？
- 從可走動區域切回視覺小說，會不會很突兀？

### 完成標準

- [x] 點「開始」後進入停車場，看到開場文字，關閉後可以左右移動
- [x] 兩個調查點、婦人事件、出口都正確觸發，文字與 `story.json` 一致
- [x] 婦人事件只觸發一次；對話中角色不能移動
- [x] 鏡頭跟隨主角，UI 固定不動
- [x] 出口接到場景 3，之後可以一路玩到結局，再回到標題、開始第二輪
- [x] `tools/validate_story.gd` 擴充：檢查區域 JSON 的引用都存在、`exit_to` 存在
- [x] 沒有錯誤；Web 版可玩
- [x] `MCP實驗紀錄.md` 新增「Lv1」一節

---

## Lv2：景深分層與光影（2.5D 的感覺）

### 目標

停車場的**玩法不變**，只改視覺：讓畫面有前後景深與黑暗中的光源，形成 2.5D 的氛圍。這一級主要練習「用 MCP 調整主觀的視覺效果」。

### 要做的

| 項目 | 做法 |
|---|---|
| 視差分層 | 用 `Parallax2D`：遠景（scene_01 調暗，scroll_scale 約 0.3）、中景（柱子剪影，約 0.7）、遊戲層（1.0）、前景（靠近鏡頭的柱子，約 1.3，最暗） |
| 黑暗 | `CanvasModulate` 把世界調暗（約 0.15～0.25） |
| 手電筒 | 主角身上的 `PointLight2D`，用 `GradientTexture2D` 做錐形或圓形光 |
| 警示燈 | 出口附近一盞紅色 `PointLight2D`，用腳本讓它閃爍；呼應背景圖的紅燈 |
| 陰影（選做） | 柱子加 `LightOccluder2D` |
| 標題畫面 | 處理「失語者」壓在 HERE 上的問題（移動位置或換背景） |

替代美術可以繼續用色塊與剪影，這一級的重點是**層次與光**，不是細節。

### 已確定的決策（2026-10-02，開工前）

| 議題 | 決定 |
|---|---|
| 手電筒形狀 | **圓形光暈**（主角周圍一圈柔光）。**備案：錐形光束**（朝面向照出光束、轉身時翻轉，參考 Inside）。圓形試玩後若氛圍不夠，再改用備案；實作時把光的貼圖與位置集中在 `Flashlight` 節點，方便替換 |
| 標題畫面 | Claude 做 2～3 種版本並截圖，**作者挑選** |
| 停車場 → 視覺小說的切換落差 | **Lv2 不處理**，等 v1.5／Lv4 增加可走動區域時再根本解決 |

### 場景結構

```
ParkingLot (Node2D)
├── FarLayer   (Parallax2D, scroll_scale.x ≈ 0.3)  ← 現有 Backdrop（scene_01）搬進來，水平重複
├── MidLayer   (Parallax2D, scroll_scale.x ≈ 0.7)  ← 柱子剪影（暗色色塊）
├── Ground / Player / Points                        ← 遊戲層（1.0），玩法不變
├── RedLight   (PointLight2D)                      ← 出口附近的紅色警示燈，腳本閃爍
├── FrontLayer (Parallax2D, scroll_scale.x ≈ 1.3)  ← 靠近鏡頭、最暗的柱子
└── Darkness   (CanvasModulate)                    ← 世界調暗（約 0.15～0.25）
Player
└── Flashlight (PointLight2D + GradientTexture2D)  ← 圓形光暈
```

### 給作者調整的參數

氛圍要靠人判斷，常調的數值做成 `area.gd` 的 `@export`，在編輯器的屬性面板直接調整，不用改程式：
世界亮度、手電筒半徑與亮度、紅燈亮度與閃爍速度、三層的 `scroll_scale`。

### 分步（指令見 `PROMPTS.md` 的「Lv2 分步指令」）

| 步驟 | 內容 | Claude 的自我驗證 |
|---|---|---|
| Lv2-2 | 三層視差 | 起點、中段、出口截圖；讀各層位移，確認遠景約 0.3 倍、前景約 1.3 倍 |
| Lv2-3 | 黑暗＋手電筒 | 截圖確認光暈跟著主角；**UI 沒有變暗** |
| Lv2-4 | 紅色警示燈閃爍（陰影選做） | 連續讀 `energy`，確認有在變化 |
| Lv2-5 | 標題畫面 2～3 種版本 | 各截一張給作者挑 |
| Lv2-6 | 作者調整氛圍 → 匯出 Web → 紀錄 | 回報 FPS（debug 版讀取）；記錄調整了幾輪 |

> FPS：`execute_code` 不能存取 `Engine`，所以在 `main.gd` 加一個只在 debug 版有效的讀取函式。網頁版的流暢度由作者在瀏覽器確認（自動化分頁在背景會被降速）。

### 要注意

- `CanvasModulate` 只會影響同一個畫布。因為 Lv1 已把 UI 放進 `UILayer`，對話框不會被調暗；但如果發現 UI 變暗，就是 UI 還留在預設畫布上。
- 網頁版用的是 Compatibility 渲染器，2D 燈光可以用，但燈光和陰影太多會影響效能。**驗證時要在瀏覽器確認流暢度**。

### 驗證

- Claude：在三個位置（起點、中段、出口）截圖，比較視差是否有作用；讀 `Engine.get_frames_per_second()`。
- 作者：氛圍好不好、會不會太暗看不清楚、手電筒的範圍是否合適。**這一級主要靠人判斷**，請在紀錄中寫下 AI 調整了幾輪才接近你想要的效果。

### 完成標準

- [x] 移動時明顯看得出前後景深
- [x] 黑暗中有手電筒光與閃爍的紅色警示燈
- [x] UI 不受燈光與調暗影響
- [x] 瀏覽器中流暢（作者主觀確認，Claude 回報 FPS）：Godot 內 60 FPS，作者確認瀏覽器流暢
- [x] `MCP實驗紀錄.md` 新增「Lv2」一節，記錄調整了幾輪、哪些描述方式對 AI 最有效

---

## Lv3：用 Pixelorama MCP 畫主角

### 目標

把色塊主角換成像素角色，有待機與行走動畫。**第一次加入第二個 MCP**，練習兩個 MCP 的配合。

### 安裝（作者操作，一次性）

1. 安裝 **Pixelorama v1.1.10**（Pixelorama-MCP 文件指定的版本），暫時不要升級。
2. 下載 <https://github.com/abidoo22/pixelorama-mcp>，在 `mcp-server/` 執行 `npm install && npm run build`。
3. 在 Pixelorama 安裝擴充功能。⚠️ 附帶的 `PixMcpBridge.pck` 在 v1.1.10 讀不了，要改用自己打包的 `PixMcpBridge.zip`（見下方「實際安裝紀錄」）。安裝後要在 Preferences → Extensions **勾選啟用**。根目錄的 `Pixelorama.pck` 不要用。
4. 確認擴充功能運作：`curl -s http://127.0.0.1:7373/health`。
5. 在專案資料夾加入 MCP：

   ```bash
   claude mcp add -s user pixelorama -- node /絕對路徑/pixelorama-mcp/mcp-server/dist/index.js
   ```

6. 使用時要**同時開著 Godot 編輯器和 Pixelorama**。

#### 實際安裝紀錄（2026-10-02，Claude 執行）

| 項目 | 結果 |
|---|---|
| 原始碼位置 | `~/Tools/pixelorama-mcp`（commit `7549161`，不放進遊戲專案） |
| 安全檢查 | npm 無安裝時腳本；伺服器只連 `127.0.0.1:7373`、不執行系統指令；外掛只監聽 `127.0.0.1`、不執行系統指令，**但沒有驗證機制**（不用時請關掉 Pixelorama） |
| `PixMcpBridge.pck` | 附帶的二進位檔，已比對：5 個原始檔（extension.json、Main.tscn、Main.gd、command_handler.gd、converter.gd）**一字不差**包含在內，沒有多餘程式 |
| `Pixelorama.pck` | 用途不明，**沒有使用** |
| 建置 | 作者的 `package.json` 有 eslint 版本衝突（只影響開發工具）→ 用 `npm ci --legacy-peer-deps`；正式相依套件 `npm audit fix` 後 0 個漏洞；`dist/` 已編譯，提供 103 個工具 |
| Pixelorama | 官方 v1.1.10 `Pixelorama-Mac.dmg` → `/Applications/Pixelorama.app`。**只有 ad-hoc 簽章，Gatekeeper 會擋**，第一次開啟要由作者在「系統設定 → 隱私權與安全性」允許 |
| 擴充功能 | ⚠️ **附帶的 `PixMcpBridge.pck` 不能用**：它是用 Godot 4.7 打包（格式第 4 版），但 Pixelorama 1.1.10 內建 Godot 4.6.2，只讀得懂第 3 版，紀錄檔會出現 `Pack version unsupported: 4`。**解法：用已驗證的 5 個原始檔打包成 `PixMcpBridge.zip`**（內部路徑 `src/Extensions/PixMcpBridge/…` 與 `addons/gdgifexporter/converter.gd`；Pixelorama 也讀 zip，沒有版本問題），放到 `~/Library/Application Support/Pixelorama/extensions/` |
| 啟用 | 擴充功能**預設是停用的**，要在「Edit → Preferences → Extensions」勾選 **pix-MCP Bridge**（等同在 `config.ini` 的 `[extensions]` 寫入 `PixMcpBridge=true`）。啟用後紀錄檔會出現 `[pix-MCP] HTTP server listening on 127.0.0.1:7373` |
| 不要加入 `Pixelorama.pck` | 擴充功能資料夾裡如果出現 8MB 的 `Pixelorama.pck`，那是 **Pixelorama 自己的程式資料**（與 App 內的檔案相同），被當成擴充功能載入時會跳出錯誤視窗。刪掉即可（安裝期間曾出現過，來源推測是透過 Add Extension 選到了 App 內的同名檔案） |
| 確認 | `curl -s http://127.0.0.1:7373/health` → `{"server":"pix-mcp-bridge","status":"ok","pixelorama_version":"v1.1.10-stable",...}` |
| MCP 註冊 | `claude mcp add -s user pixelorama -- node ~/Tools/pixelorama-mcp/mcp-server/dist/index.js`（**user 範圍**）。一開始用 local 範圍，但從某些地方啟動 Claude Code 時 `/mcp` 不會出現，改成 user 範圍後在任何資料夾都會載入。不放進 `.mcp.json`：那個檔案由 Godot 外掛管理、會進 git，且這是本機路徑 |

### 角色規格（可在開工前調整）

| 項目 | 規格 |
|---|---|
| 尺寸 | **32×48 像素，遊戲中放大 2 倍**（64×96，和 Lv1 的色塊一樣高；碰撞範圍、互動點都不用改）。原規格「32×64 放大 3 倍」= 192px，與「約 96px」矛盾，2026-10-05 作者改定。像素圖只用**整數倍**放大 |
| 造型 | **感染者特徵明顯**（2026-10-05 作者決定）：灰青膚色、破損的深色外套、駝背前傾、手上有暗紅血跡（呼應劇本開場「手上有乾裂的血跡」），一眼看出是靜語者 |
| 調色盤 | 約 12～16 色，偏灰綠、褐色的低飽和色調，配合背景插畫；血跡是唯一的暗紅點綴 |
| 動畫 | 待機 4 格（輕微搖晃、喘息）、行走 6 格（**拖著腳、步履蹣跚**）；速度：待機 4 fps、行走 8 fps（作者已確認） |
| 方向 | **左右各畫一套，共 20 格**（2026-10-05 作者決定，不用水平鏡像）。面向右時看到的是主角的**右側**，靠近鏡頭的是有血跡的右手；面向左時看到**左側**，靠近鏡頭的是左手（乾淨），有血跡的右手在身體另一側、只露出一點。光源固定在左上，不跟著翻轉 |
| 畫格配置 | 同一個畫布：0～3 `idle_right`、4～9 `walk_right`、10～13 `idle_left`、14～19 `walk_left`（用 `add_animation_tag` 標記） |
| 輸出 | spritesheet 到 `assets/sprites/player.png`；原始檔 `.pxo` 存到 `art/player.pxo`（`art/` 加進 Web 匯出的 `exclude_filter`） |

### 繪圖方式（依 pixelorama-mcp 的 `AGENTIC_DRAWING_PLAYBOOK.md`）

- Claude 先在本機**用文字格線（ASCII，每個字元代表一種顏色）設計每一格**，存在暫存區，轉成像素清單後，用 **`draw_pixels` 一次送出**（不要逐點呼叫 `draw_pixel`）。
- 每畫完一格用 **`capture_canvas_image`** 截圖自我檢查（多模態），再給作者看。
- 動畫用 **`duplicate_frame`** 複製上一格再修改；**`set_onion_skinning`** 方便比對前後格；`add_animation_tag` 標記 `idle`（0～3 格）與 `walk`（4～9 格）。
- 原始檔用 `save_project` 存成 `art/player.pxo`。

### 兩個 MCP 的分工

| 步驟 | MCP |
|---|---|
| 畫圖、動畫、匯出 spritesheet（`export_animation` 的 `spritesheet` 模式）| **pixelorama** |
| 匯入圖片、建立 `idle`／`walk` 的 SpriteFrames（`spriteframes` 群組）、改場景、驗證 | **godot-mcp-toolkit** |

> pixelorama 也有 `export_godot_spriteframes`，但它一次只能把**整個畫布**匯出成**一個**動畫。待機和行走放在同一個畫布，所以改用「匯出一張 spritesheet → 在 Godot 用 Toolkit 切成兩個動畫」，也正好練習兩個 MCP 的配合。

### 流程（分步指令見 `PROMPTS.md` 的「Lv3 分步指令」）

| 步驟 | 內容 | 停止點 |
|---|---|---|
| Lv3-2 | 建立 32×48 畫布與調色盤，畫**待機第一格**；`capture_canvas_image` 自我檢查；另外把它放進遊戲裡截一張（放大 2 倍、在停車場的燈光下）給作者看 | **作者確認造型、比例、配色** |
| Lv3-3 | 面向右的待機 4 格（輕微搖晃、喘息） | **作者確認動態** |
| Lv3-4 | 面向右的行走 6 格（**拖著腳、步履蹣跚**） | **作者確認動態** |
| Lv3-4b | 面向左的待機 4 格＋行走 6 格（以右向為基礎鏡像後，修正血跡在哪隻手、光源方向等不對稱的細節） | **作者確認** |
| Lv3-5 | 匯出 `assets/sprites/player.png`；Godot：`Player` 底下新增 `AnimatedSprite2D`（`texture_filter = Nearest`、放大 2 倍、腳底對齊 y=0），用 Toolkit 建立 `idle_right`／`walk_right`／`idle_left`／`walk_left`；隱藏原本的色塊 `Body`、移除 Lv3-2 的暫時 `PreviewSprite`；`player.gd` 依「是否移動 × 面向」播放對應動畫（**不用 `flip_h`**）；`art/*` 加進 Web 匯出的 `exclude_filter` | — |
| Lv3-6 | MCP 驗證 → 作者試玩 → Web 匯出 → 紀錄 | 作者確認 |

### 要注意

- 像素清晰：只用 `AnimatedSprite2D` 的 `texture_filter = Nearest`，**不改專案全域的貼圖濾鏡**（背景插畫要維持平滑）。
- 光影：主角會被 Lv2 的世界亮度（0.32）調暗、被手電筒照亮。色塊時期主角會過曝，換成像素圖後要重新確認亮度。
- Pixelorama 不用時請作者關掉（7373 沒有驗證機制）。

### 驗證

- Claude：Pixelorama 端用 `capture_canvas_image`／`get_canvas_snapshot` 檢查畫面；Godot 端截圖確認角色清晰；用 `runtime_get_node_state` 讀 `AnimatedSprite2D` 的 `animation`（移動中是 `walk`、停下是 `idle`）與面向（向左走時播 `*_left`）。
- 作者：**造型和動態好不好看只能靠人判斷**。請記錄 AI 畫了幾次、哪些描述方式有效、哪些需要你手動在 Pixelorama 修。

### 完成標準

- [x] 主角是像素角色，待機與行走動畫正確切換，左右兩個方向的動畫正確
- [x] 像素清晰不模糊
- [x] `MCP實驗紀錄.md` 新增「Lv3」一節：Pixelorama MCP 的穩定度、繪圖品質、兩個 MCP 的配合情況
- [ ] 依結果決定：繼續用 Pixelorama，或購買 Aseprite 在 Lv4 比較

---

## 劇本 v1.5：改寫成「區域 × 事件」格式（Lv3 之後、Lv4 之前）

原規劃在 `docs/v1.5_劇本調整規劃.md`（視覺小說格式）。做完 Lv1～3 之後，改寫成可移動版適用的格式。

### 流程（兩個停止點，都要作者審稿）

1. Claude 寫 `docs/story_v1.5_outline.md`：
   - 區域清單（例如：停車場、街道、診所、研究設施〔過場〕、新區域、舊家、營火〔過場〕）。
   - 每個區域的互動點與事件：類型（intro／inspect／approach／exit／cutscene）、觸發條件、旗標、數值效果。
   - 哪些原場景變成區域、哪些維持視覺小說過場。
   - 處理重複劇情（原場景 11～14）。用詞已統一（2026-10-02）：主角「**楊尚瑜**」、保有意識的感染者「**靜語者**」。
   - 結局改成「在牆前的最後一個動作」，由數值決定可選哪些。
   → **停：作者審大綱**
2. Claude 寫 `docs/story_v1.5_draft.md`：完整文字草稿。→ **停：作者審文字**
3. 定稿後寫入 `data/story.json` 與 `data/areas/*.json`；舊版備份到 `docs/story_v1.0.json`。
4. 同時寫 `docs/asset_requests.md`：新背景、BGM、音效、像素素材的需求與生成提示詞。

> 開始前要先修改 `CLAUDE.md` 的劇本規則：從「Claude 不可改寫劇情」改成「Claude 可以起草，經作者審核定稿後才能寫入」。

---

## Lv4：多區域、物品與旗標

### 目標

依 v1.5 大綱，增加**街道**與**診所**兩個可走動區域，並加入物品與旗標，讓「調查」開始影響後續事件。練習專案變大之後，AI 還能不能維持品質。

### 要做的

| 項目 | 內容 |
|---|---|
| 區域 | 街道（連接停車場與診所）、診所（找錄音筆） |
| 區域切換 | 出口可以通往另一個區域（不只是接回視覺小說）；記住玩家從哪個出口進來，在對應位置出現 |
| 全域狀態 | `GameState` autoload：旗標、持有物品、已觸發事件；回標題時重設 |
| 物品 | 例如錄音筆：在診所撿到後，才能觸發「錄音筆記憶」事件 |
| 條件事件 | 互動點加上 `require_flag`、`set_flag` 欄位 |
| 美術 | 用 Pixelorama MCP 畫小道具（錄音筆、病歷卡、照片）與簡單的場景物件 |
| Aseprite（選做） | 購買 Aseprite 後，用 Aseprite MCP 畫同樣的道具，比較兩個 MCP |

### 驗證

- Claude：用 `execute_code` 直接設定旗標或跳到某個區域，測試各種條件；headless 測試（對專案副本）窮舉「有／沒有撿到物品」的路線。
- 作者：區域之間的節奏、會不會迷路、調查的回饋是否足夠。

### 完成標準

- [ ] 停車場 → 街道 → 診所可以來回走，出現位置正確
- [ ] 撿到物品前後，事件不同
- [ ] 回標題後狀態重設，第二輪正常
- [ ] `validate_story.gd` 能檢查旗標的設定與使用是否對應
- [ ] `MCP實驗紀錄.md` 新增「Lv4」一節（含兩個像素工具 MCP 的比較，如果有做）

---

## Lv5：數值、衝動機制與結局條件

### 目標

完成 v1.5 的遊戲機制，讓選擇真正有後果。練習用 AI 協助遊戲機制設計與平衡。

### 要做的

| 項目 | 內容 |
|---|---|
| 數值 | 記憶、人性（初始值與增減依 v1.5 定稿），調查線索增加記憶 |
| 衝動機制 | 靠近人類時畫面泛紅、手電筒閃爍；玩家要主動遠離，或做出壓抑的動作。失控時人性下降，可能觸發 Bad End。**不是戰鬥**，是張力 |
| Bad End | 共用一張圖與一首音樂；可以「從這裡重試」（回到進入區域時的檢查點與數值）或回標題 |
| 結局 | 在牆前的最後動作，依數值解鎖；未達條件顯示灰色「……（你想不起來）」 |
| 除錯 | 只在 debug 版可按 F3 顯示數值，Web 正式版不顯示 |
| 新素材 | 依 `docs/asset_requests.md` 由作者準備，整合進專案 |

### 驗證

- headless 測試（專案副本）：最佳路線到結局 A、中間路線到 B、最差路線到 C；每個 Bad End 的重試會還原數值。
- MCP 實玩：用 `execute_code` 設定數值後走到關鍵點，截圖確認畫面效果與鎖定的選項。
- 作者：**平衡與節奏只能靠人判斷**，例如衝動機制會不會太煩、結局條件會不會太難或太容易。

### 完成標準

- [ ] 三個結局與所有 Bad End 都走得到，條件正確
- [ ] 衝動機制有張力但不惱人（作者確認）
- [ ] Web 版可玩
- [ ] `MCP實驗紀錄.md` 新增「Lv5」一節，並寫一份整體總結：從階段 1 到 Lv5，AI 與 MCP 在哪些地方幫最多、哪些地方仍需要人
