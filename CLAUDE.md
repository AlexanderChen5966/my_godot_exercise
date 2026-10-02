# 失語者 — Godot 專案（階段 1 完成，進行中：Lv1）

這份檔案是給 Claude Code 讀的專案說明。每次開新對話都會自動載入。

## 目前進度（每次開始前先看）

- **階段 1（視覺小說式）已完成**，下方「要做的功能」「完成標準」是階段 1 的內容，保留作為現有系統的說明。
- 之後改走 **Lv1～5 新路線**（橫向捲軸 2.5D、可移動），練習 MCP 與 AI 輔助開發：
  - 路線、原規劃與新路線的對照、已確定的決策：`docs/開發路線圖.md`
  - 每一級的規格、步驟、驗證方式、完成標準：`docs/Lv製作流程.md`
  - 作者貼給你的分步指令：`PROMPTS.md` 的「Lv1 分步指令」
- **暫不支援手機**：Lv1 起可走動區域只做鍵盤操作，不要自行加觸控。按鍵衝突（`interact` 與 `ui_accept`）之後再處理。
- **目前進行：Lv1（停車場可走動）**。開始實作前，先讀 `docs/Lv製作流程.md` 的「0. 每一級共通的流程」與「Lv1」兩節。
- **一次只做一級**：沒有作者的指示，不要開始下一級，也不要提前做後面等級的功能。
- MCP：目前只用 **godot-mcp-toolkit**。Pixelorama MCP 從 Lv3 才加入（安裝方式見 `docs/Lv製作流程.md` 的 Lv3）。
- 劇本 **v1.5 暫停**，Lv3 完成後才會改寫成「區域 × 事件」格式；在那之前不要依 `docs/v1.5_劇本調整規劃.md` 實作任何東西。
- 每一級完成時：在 `MCP實驗紀錄.md` 新增該級的一節，並更新 `docs/開發路線圖.md` 的「進度紀錄」。

## 目標

把原本 Kivy 版的選項式分歧結局遊戲，在 Godot 重做成**網頁版**：背景圖 + 文字 + 選項 + 背景音樂，點擊推進。
這是一個 **MCP 工作流實驗**：場景與節點盡量用 `godot-mcp-toolkit` MCP 工具建立，並用 MCP 執行遊戲、截圖、模擬輸入、讀 log 來驗證。

## 技術限制（不要違反）

- Godot 4.5 以上，**只用 GDScript**（C# 無法匯出網頁版）。
- 渲染器固定 `gl_compatibility`（網頁需要），已在 `project.godot` 設好。
- 基準解析度 1152×768（3:2，與背景圖相同），stretch 模式 `canvas_items` + `keep`。
- 字型已在專案設定指定為 `res://assets/fonts/NotoSansTC-Regular.ttf`，不需要每個節點個別設定。
- **不要修改 `data/story.json` 的文字內容**（劇本由作者負責）。可以讀、不可以改寫劇情。
- 不要手動編輯 `.godot/` 資料夾。
- 不要修改 `addons/godot_mcp_toolkit/`（第三方外掛），也不要手動改 `project.godot` 的 `[editor_plugins]`、`[autoload] MCPRuntimeServer`（外掛自己管理）。
- 子資料夾裡**不可以有 `project.godot`**（例如 `scripts/project.godot`），否則 Godot 會把整個資料夾當成別的專案而略過，導致 `class_name` 找不到。

## 專案結構

```
project.godot          專案設定（解析度、字型、匯入預設值都已設好）
export_presets.cfg     已有一個名為 "Web" 的匯出設定，輸出到 build/web/index.html
data/story.json        劇本資料（見下方格式）
assets/bg/             20 張背景 scene_01.webp ~ scene_20.webp（1152×768）
assets/bgm/            20 首背景音樂 bgm_01.ogg ~ bgm_20.ogg（匯入時已設為循環）
assets/sfx/click.ogg   點擊音效
assets/fonts/          Noto Sans TC
tools/validate_story.gd  劇本檢查工具
addons/godot_mcp_toolkit/  Godot MCP Toolkit 編輯器外掛（v1.0.2，MIT）
.mcp.json              Claude Code 的專案 MCP 設定（由外掛產生，連到 godot-mcp-toolkit）
scenes/Main.tscn       主場景
scripts/story_data.gd  劇本讀取（class_name StoryData）
scripts/main.gd        主畫面邏輯
docs/開發路線圖.md       原規劃（階段 1～4）與新路線（Lv1～5）、決策、進度紀錄
docs/Lv製作流程.md       Lv1～5 的規格、步驟、驗證與完成標準
docs/v1.5_劇本調整規劃.md  劇本 1.5 原規劃（暫停中）
data/areas/parking_lot.json  Lv1 停車場區域資料（文字以引用方式取自 story.json）
MCP實驗紀錄.md           每一級的 MCP 實驗觀察
```

Lv1 之後會新增（依 `docs/Lv製作流程.md`）：`scenes/areas/`、`scripts/area_data.gd`、`scripts/area.gd`、`scripts/player.gd`、`scripts/interact_point.gd`。

## 劇本格式（data/story.json）

```json
{
  "game_title": "失語者",
  "start_id": 1,
  "title_screen": { "bg": "scene_16.webp", "bgm": "bgm_15.ogg" },
  "scenes": [
	{
	  "id": 1,
	  "title": "停車場甦醒",
	  "text": "場景主文字（一段）",
	  "hint": "請選擇行動：",
	  "extra_hint": "可能是空字串",
	  "bg": "scene_01.webp",        // 位於 res://assets/bg/
	  "bgm": "bgm_01.ogg",          // 位於 res://assets/bgm/
	  "is_ending": false,
	  "choices": [
		{ "text": "按鈕文字", "response": "選了之後顯示的回應", "next_id": 2 }
	  ]
	}
  ]
}
```

- 共 20 個場景、3 個結局（id 18、19、20，`is_ending: true`）。
- 結局場景只有一個選項「重新開始」，`next_id` 為 1。
- 有些選項的 `next_id` 等於自己的場景 id（例如「停留不動」），代表留在原場景：顯示回應後重新顯示同一場景的選項即可。
  回到同一場景時，**已選過的選項以半透明顯示**（仍可點），換到新場景時重置，讓玩家知道哪些選過了（場景 4 有 3 個留在原地的選項）。

## 要做的功能（階段 1 MVP）

1. **標題畫面**：背景 `title_screen.bg`、大標題 `game_title`、「點擊開始」。
   瀏覽器規定使用者互動後才能播放聲音，所以**第一次點擊之後才開始播放 BGM**。
2. **劇情畫面**：
   - 全螢幕背景（`TextureRect`，`expand_mode = ignore size`，`stretch_mode = keep aspect covered`）。
   - 畫面下方半透明對話框（約占畫面高度 35%），內含場景標題、主文字。
   - 主文字用 `RichTextLabel` 做**打字機效果**（`visible_ratio` 或 `visible_characters` 逐步增加）；打字中點擊 → 直接顯示全部。
   - 文字全部顯示後，顯示 `hint`（若 `extra_hint` 不是空字串也一併顯示，用較淡的顏色）以及選項按鈕（由 `choices` 動態產生，垂直排列）。
3. **選擇流程**：點選項 → 播放 click 音效 → 隱藏選項 → 在對話框顯示 `response`（同樣打字機）→ 顯示「▼ 點擊繼續」→ 點擊後前往 `next_id`。
4. **換場**：背景淡出淡入（約 0.4 秒，可用 `Tween` 或 `ColorRect` 黑幕）。
5. **BGM**：只有當新場景的 `bgm` 和目前播放的不同時才換曲，換曲時舊曲淡出、新曲淡入（約 0.8 秒）。相同曲目時不要重新開始播放。
6. **結局**：`is_ending` 為 true 時，對話框上方顯示「— 結局 —」標記；選「重新開始」回到**標題畫面**（不是直接回場景 1）。
7. 視窗大小改變時版面不跑掉（使用 anchors／Container，不寫死座標）。

## 建議架構

- `scripts/story_data.gd`：`class_name StoryData`，負責讀 JSON、提供 `get_scene(id) -> Dictionary`、`start_id`、`title_screen`。
- `scenes/Main.tscn`（根節點 `Control`，全螢幕）+ `scripts/main.gd`：管理狀態（TITLE / TYPING / CHOOSING / RESPONSE / ENDING）。
- 建議節點樹：

```
Main (Control, full rect)
├── Background (TextureRect)
├── Fade (ColorRect, 黑色, mouse_filter = ignore)
├── TitleLayer (Control)
│   ├── TitleLabel (Label)
│   └── StartLabel (Label)  「點擊開始」
├── StoryLayer (Control)
│   ├── Choices (VBoxContainer)
│   └── DialogPanel (PanelContainer, 半透明)
│       └── VBox (VBoxContainer)
│           ├── EndingTag (Label)  「— 結局 —」
│           ├── SceneTitle (Label)
│           ├── Body (RichTextLabel)
│           ├── Hint (RichTextLabel)  ← extra_hint 要用較淡顏色，所以用 RichTextLabel + BBCode
│           └── Continue (Label)  「▼ 點擊繼續」
├── BgmA (AudioStreamPlayer)
├── BgmB (AudioStreamPlayer)   ← 兩個播放器交替做 crossfade
├── Sfx (AudioStreamPlayer)
├── TypeSfx (AudioStreamPlayer)  ← 打字音效（max_polyphony 4）
└── RotateHint (ColorRect)      ← 直式畫面時顯示「請將裝置橫向持握」（Lv1-0）
```

- `project.godot` 的 `run/main_scene` 要設成 `res://scenes/Main.tscn`。

## 工作方式（MCP 實驗規則）

### MCP：godot-mcp-toolkit（編輯器外掛）

- 使用 **Godot MCP Toolkit**（`addons/godot_mcp_toolkit/` + `.mcp.json` 的 `godot-mcp-toolkit`）。它透過 WebSocket 連到**正在開著的 Godot 編輯器**，所以使用前編輯器必須開啟此專案，外掛為啟用狀態。
- 常駐工具不夠時，用 `discover_tools` 啟用群組（一次只開需要的，約 5 個以內）。本專案常用：`theme`（StyleBox／字型／顏色覆寫）、`runtime_advanced`、`editor_advanced`、`lsp_code_analysis`、`audio`、`cleanup`。
- 原本的 Coding-Solo/godot-mcp（`create_scene`、`add_node`、`run_project`、`get_debug_output`）已由 Toolkit 取代，不要混用：兩者同時改 `.tscn` 會互相覆蓋。

### 建立場景與節點

- **優先用 MCP 工具**：`scene_create`、`scene_open`、`scene_create_node`、`node_set_property`、`node_set_script`、`control_set_layout`、`scene_delete_node`、`node_manage`、`editor_save_scene`；主題樣式用 `theme` 群組的 `theme_edit`；專案設定用 `project_set_setting`。
- MCP 做不到的，再直接編輯 `.tscn` 或在腳本 `_ready()` 中設定，並說明原因。
- 透過 MCP 修改場景後要 `editor_save_scene`。若直接改了 `.tscn` 檔案，要提醒使用者在編輯器重新載入，避免編輯器存檔時覆蓋。
- 執行時動態產生的節點（例如選項按鈕）寫在腳本裡。

### 腳本

- **GDScript 檔案**用一般檔案編輯寫入 `scripts/`（也可用 `script_write`／`script_edit`）。
- 寫完用 `script_check` 檢查單一檔案，或 `lsp_project_diagnostics` 檢查整個專案。編譯錯誤**不會**出現在遊戲 log 裡。
- 新增 `class_name` 後若沒被認得，先確認子資料夾沒有多餘的 `project.godot`，再用 `editor_refresh` 或 `Godot --headless --path . --import` 重新掃描。

### 每完成一個步驟

1. `game_start`（`scene_path: "main"`）執行遊戲。若回傳 `runtime_ready: false`，或之後的 runtime 工具回報 `GAME_NOT_RUNNING`（但 log 顯示遊戲有在跑），先呼叫 `game_start`（`if_running: "return"`, `runtime_poll: true`）再重試；有時要**輪詢兩次**（間隔幾秒）才會連上。
2. `runtime_screenshot` 截圖確認畫面（**一律用 `image_response_mode: "disk"`** 再讀取存下的 PNG；inline 模式圖片超過約 1MB 會失敗，且曾回傳舊畫面）；需要互動時用 `input_simulate`（`click` 給座標，或 `click_node` 給節點路徑），再截圖確認結果。座標以 1152×768 為準。
3. `debugger_get_log` 讀錯誤與警告（遊戲剛啟動時 log 可能還沒印完，必要時再讀一次）。
4. 修好之後 `game_stop`。

- 流程較長時（例如一路點到三個結局），可另外寫 headless 測試腳本放在暫存區（不要放進專案）。
  **不要直接對本專案跑 headless**：外掛的 `MCPRuntimeServer` autoload 在 headless 也會啟動，會覆蓋 godot-mcp-toolkit 的 runtime 登錄（`~/Library/Application Support/godot-mcp-toolkit/`），導致正在執行的遊戲之後回報 `GAME_NOT_RUNNING`。
  做法：把專案 rsync 到暫存區（排除 `addons/`、`.mcp.json`、`build/`），刪掉副本 `project.godot` 裡的 `MCPRuntimeServer` autoload 與外掛啟用設定，再對副本執行 `Godot --headless --path <副本> --script <測試腳本>`。
- 修改劇本或素材後，執行劇本檢查（同樣會啟動 runtime 外掛，請在**沒有用 MCP 執行遊戲時**跑，或照上面的方式對副本執行）：
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/validate_story.gd`
- 每個步驟結束時，簡短回報：做了什麼、用了哪些 MCP 工具、哪些改用其他方式（與原因）、截圖與 log 是否正常。

### 網頁匯出注意

- **遊戲需要的資料不能少**：Web 設定的 `include_filter` 是 `data/*.json, data/areas/*.json`。之後新增資料資料夾（例如 `data/xxx/`）時要一併加入，匯出後檢查 `.pck` 裡確實有這些檔案。
- Godot 4.3+ 預設的腳本匯出模式（Binary tokens）**不會**排除外掛腳本，匯出前要在 Web 設定的 `exclude_filter` 加上 `addons/*`（外掛會自動移除 `.mcp.json` 與 runtime autoload）。

## 完成標準（Definition of Done）

- [x] 從標題畫面點擊開始，可以一路玩到三個結局中的任一個。
- [x] 每個選項都會先顯示 `response` 再前進。
- [x] 「停留不動」類選項會留在原場景並能再次選擇。
- [x] 相同 BGM 不會重播；不同 BGM 有淡入淡出。
- [x] 結局選「重新開始」回到標題畫面。
- [x] `debugger_get_log` 與 `lsp_project_diagnostics` 沒有錯誤。
- [x] 能用 Web 匯出設定輸出到 `build/web/`，在瀏覽器中可玩，且有聲音。

> 2026-10-02 階段 1 全部完成（使用者已在瀏覽器實測）。實驗過程與觀察見 `MCP實驗紀錄.md`。

## 劇本之後可能再調整（附註）

> 下一版 **1.5** 的劇本調整規劃（分歧、快速結局、隱藏數值）見 `docs/v1.5_劇本調整規劃.md`，目前**暫停**：
> 等 Lv3 完成後，會改寫成可移動版的「區域 × 事件」格式再開始（見 `docs/Lv製作流程.md` 的「劇本 v1.5」一節）。實作前仍以本檔的規則為準。
>
> Lv1 起，區域資料（`data/areas/*.json`）以 `from` **引用** `story.json` 的文字，不複製。修改 `story.json` 時，若刪除或調換了被引用的場景或選項順序，區域文字也會跟著變，請一併檢查（劇本檢查工具會在 Lv1 擴充這項檢查）。

劇本（`data/story.json`）之後會由作者修改，例如處理下面的重複劇情。程式是完全依資料運作的，調整劇本時請注意：

- **程式不需要跟著改**的情況：修改文字、標題、hint、選項文字／response、增減場景或選項、改 `next_id`、改背景／BGM 檔名、改 `title_screen`、改 `start_id`。
- 結局判斷只看 `is_ending: true`；結局的選項不論 `next_id` 是多少，都會回到**標題畫面**。
- `next_id` 等於自己 id 的選項＝留在原地（會變暗）；選項數量不限，但超過約 6 個時對話框上方空間會不夠，需要調整 `Choices` 版面。
- 主文字很長時（超過約 3～4 行），對話框（畫面高度 35%）會不夠放，Body 會出現捲動；需要時再調整版面或字級。
- 新增素材放進 `assets/bg/`、`assets/bgm/`；新的 ogg BGM 會自動循環。**新增音效時要把該檔的匯入設定改成不循環**（專案預設 ogg 都循環，click.ogg 已處理）。
- 改完一定要跑劇本檢查（`tools/validate_story.gd`，注意上面「headless 會覆蓋 runtime 登錄」的說明），再重新匯出 Web 版。
- Claude 仍然**不可以自行改寫劇情**；作者提供新版劇本後，只負責檢查格式、跑驗證與測試。

## 已知劇本問題（階段 1 不處理，僅供參考）

- 場景 1~16 大部分選項都通往同一個下一場景，真正的分歧只在場景 17。
- 場景 5/11、7/12、8/13、10/14 劇情重複。
- 用詞已統一（2026-10-02 作者決定）：主角名稱為「楊尚瑜」；保有意識的感染者稱為「**靜語者**」（不是噬語者），場景 15 已修正。
- 原專案缺 `bgm_13`，已用原專案中的〈Escape Through the Chaos〉代替。
