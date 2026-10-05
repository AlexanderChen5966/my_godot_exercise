# 失語者 — Godot 專案（階段 1、Lv1～Lv4 完成）

這份檔案是給 Claude Code 讀的專案說明。每次開新對話都會自動載入。

## 目前進度（每次開始前先看）

- **階段 1（視覺小說式）已完成**，下方「要做的功能」「完成標準」是階段 1 的內容，保留作為現有系統的說明。
- 之後改走 **Lv1～5 新路線**（橫向捲軸 2.5D、可移動），練習 MCP 與 AI 輔助開發：
  - 路線、原規劃與新路線的對照、已確定的決策：`docs/開發路線圖.md`
  - 每一級的規格、步驟、驗證方式、完成標準：`docs/Lv製作流程.md`
  - 作者貼給你的分步指令：`PROMPTS.md` 的「LvN 分步指令」（每一級開始時補上該級的指令）
- **暫不支援手機**：Lv1 起可走動區域只做鍵盤操作，不要自行加觸控。按鍵衝突（`interact` 與 `ui_accept`）之後再處理。
- **Lv1（停車場可走動）、Lv2（景深分層與光影）已完成（2026-10-02）；Lv3（Pixelorama MCP 畫主角）已完成（2026-10-05）**：32×48、放大 2 倍，左右各一套共 20 格（待機 4 fps、行走 8 fps），原始檔 `art/player.pxo`，遊戲用 `assets/sprites/player.png`＋`player_frames.tres`。經過與觀察見 `MCP實驗紀錄.md` 的「Lv3」。**劇本 v1.5 已定稿（2026-10-05）**：`docs/story_v1.5_outline.md`、`docs/story_v1.5_draft.md`，素材需求 `docs/asset_requests.md`。**Lv4（多區域、物品與旗標）已完成（2026-10-05）**：停車場（v1.5）→ 街道 → 診所，格式與步驟見 `docs/Lv製作流程.md` 的「Lv4」，經過見 `MCP實驗紀錄.md` 的「Lv4」。**目前進行：Lv5（其餘區域、Bad End 與結局）**：2026-10-05 作者決定把原 Lv5 拆成 Lv5／Lv6（衝動機制、像素人物、平衡在 Lv6）。規格與格式擴充見 `docs/Lv製作流程.md` 的「Lv5」，分步指令在 `PROMPTS.md` 的「Lv5 分步指令」。
- **一次只做一級**：沒有作者的指示，不要開始下一級，也不要提前做後面等級的功能。
- MCP：**godot-mcp-toolkit**（Godot 編輯器）＋ **pixelorama**（像素繪圖，Lv3 起使用）。
  - pixelorama 註冊在 **user 範圍**（`~/Tools/pixelorama-mcp`），擴充功能用自己從原始碼打包的 `PixMcpBridge.zip`。安裝紀錄與排除問題見 `docs/Lv製作流程.md` 的 Lv3 與 `MCP實驗紀錄.md` 的「Lv3 準備」。
  - 使用時要**同時開著 Godot 編輯器和 Pixelorama**；開始前先呼叫一次 `list_canvases` 確認連線（擴充功能也可用 `curl -s http://127.0.0.1:7373/health` 確認）。
  - Pixelorama 的擴充功能在 `127.0.0.1:7373` **沒有驗證機制**，不畫圖時請作者關掉 Pixelorama。
- 劇本 **v1.5 已定稿**：Lv4 寫入停車場、街道、診所的資料，Lv5 寫入其餘部分（作者決定分批，讓遊戲每一步都能玩）。1.0 版劇本備份在 `docs/story_v1.0.json`。`docs/v1.5_劇本調整規劃.md` 是原規劃，內容以新大綱與草稿為準。
- 每一級完成時：在 `MCP實驗紀錄.md` 新增該級的一節，並更新 `docs/開發路線圖.md` 的「進度紀錄」。

## 目標

把原本 Kivy 版的選項式分歧結局遊戲，在 Godot 重做成**網頁版**：背景圖 + 文字 + 選項 + 背景音樂，點擊推進。
這是一個 **MCP 工作流實驗**：場景與節點盡量用 `godot-mcp-toolkit` MCP 工具建立，並用 MCP 執行遊戲、截圖、模擬輸入、讀 log 來驗證。

## 技術限制（不要違反）

- Godot 4.5 以上，**只用 GDScript**（C# 無法匯出網頁版）。
- 渲染器固定 `gl_compatibility`（網頁需要），已在 `project.godot` 設好。
- 基準解析度 1152×768（3:2，與背景圖相同），stretch 模式 `canvas_items` + `keep`。
- 字型已在專案設定指定為 `res://assets/fonts/NotoSansTC-Regular.ttf`，不需要每個節點個別設定。
- **劇本規則（2026-10-05 作者同意修改）**：Claude 可以**起草**劇本（大綱、文字草稿，寫在 `docs/`），但必須經作者審核**定稿**後，才能寫入 `data/story.json` 與 `data/areas/*.json`。未經作者定稿，不可以改寫劇情。
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
scripts/game_state.gd  一輪遊戲的全域狀態（class_name GameStateData；autoload 名稱 GameState，Lv4-1 用 autoload_manage 加入）
scripts/area_data.gd   區域資料讀取、互動點的文字／條件／variants、區域資料的檢查
docs/開發路線圖.md       原規劃（階段 1～4）與新路線（Lv1～5）、決策、進度紀錄
docs/Lv製作流程.md       Lv1～5 的規格、步驟、驗證與完成標準
docs/v1.5_劇本調整規劃.md  劇本 1.5 原規劃（視覺小說格式；方向仍有效，格式改成區域 × 事件）
docs/story_v1.5_outline.md  劇本 v1.5 大綱（定稿：區域、事件、數值、Bad End）
docs/story_v1.5_draft.md    劇本 v1.5 完整文字（定稿，標示原文／改／新）
docs/asset_requests.md      v1.5 素材需求與生成提示詞（作者準備背景、BGM、音效）
docs/story_v1.0.json        1.0 版劇本備份（不放 data/，避免被匯出）
art/player.pxo         主角的 Pixelorama 原始檔（含 .gdignore，不匯出）
assets/sprites/        主角 spritesheet 與 SpriteFrames
data/areas/parking_lot.json  停車場區域資料（Lv4-3 起為 v1.5 格式，文字直接寫在資料裡）
data/areas/street.json  街道區域資料（Lv4-4）
data/areas/clinic.json  診所區域資料（Lv4-5：錄音筆、診療椅的 variants）
data/areas/lab.json     設施走廊區域資料（Lv5-2：女科學家給筆記本、警衛 → BE2）
scenes/areas/          可走動區域的場景：ParkingLot.tscn、Street.tscn、Clinic.tscn、Lab.tscn（之後的都由前一個區域另存後用 Toolkit 修改）
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

- **v1.5（Lv5-1 起）**：`story.json` 只留過場與結局：6 搜捕隊、7 手術台、15 營火、18～20 結局 A／B／C、21～23 Bad End（`ending_type: bad`）；場景 17「最後的動作」是暫時的，Lv5-5 做好牆前後移除。開始遊戲進入 `start_area`（停車場）。新欄位（`effects`、`require`、`locked_text`、`next_area`、`action`、`ending_label`）見 `docs/Lv製作流程.md` 的 Lv5。1.0 版備份在 `docs/story_v1.0.json`。
- 以下是 1.0 的說明（格式相容，舊欄位都還能用）：共 20 個場景、3 個結局（id 18、19、20，`is_ending: true`）。
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
- **Control 的版面屬性不要在 `scene_create_node` 時一起設定**：建立時帶入的 `position`／`size`，甚至 `offset_*`，位置都可能被重設成 (0, 0)（Lv1-4、Lv1-5 各發生一次）。做法：先建立節點，**再用 `node_set_property` 設定 `offset_left/top/right/bottom`**，存檔後檢查 `.tscn`。
- **`node_manage` 的 `duplicate` 不會把子節點存進 `.tscn`**（Lv4-5）：複製出來的子節點（Shape、Marker）只存在編輯器裡，存檔後就不見了。要複製互動點時改用 `scene_create_node` 重新建立子節點，存檔後檢查 `.tscn`。
- 新的可走動區域：用 `editor_save_scene`（帶 `file_path`）把現有區域**另存**，再用 Toolkit 修改（Lv4-4、Lv4-5 的做法）。區域場景裡 **`Points` 要排在 `Player` 前面**，否則高的道具（例如藥櫃）會擋住主角。
- 遠景背景（FarLayer/Backdrop）用 `stretch_mode = 6`（等比例蓋滿）、寬約 1500，不要重複拼接（會有接縫）。
- 選項的鍵盤操作要用 `input_simulate` 的 `key` 類型送真正的按鍵（下方向鍵 `keycode 4194322`、Enter `4194309`）；`action` 類型不會移動焦點。用 `execute_code` 瞬移主角後，要等一下物理更新，互動點才會偵測到。
- 模擬移動用 `input_simulate` 的 `action` 類型（會呼叫 `Input.action_press`）。`key` 類型若要觸發動作，必須帶 `physical_keycode`（本專案的按鍵是用實體按鍵綁定）。
- 測試期間如果使用者也在操作遊戲視窗，座標與狀態會被干擾；量測前先確認狀態，結果異常時先懷疑外部輸入。

### 腳本

- **GDScript 檔案**用一般檔案編輯寫入 `scripts/`（也可用 `script_write`／`script_edit`）。
- 寫完用 `script_check` 檢查單一檔案，或 `lsp_project_diagnostics` 檢查整個專案。編譯錯誤**不會**出現在遊戲 log 裡。
- 新增 `class_name` 後若沒被認得，先確認子資料夾沒有多餘的 `project.godot`，再用 `editor_refresh` 或 `Godot --headless --path . --import` 重新掃描。

### 每完成一個步驟

1. `game_start`（`scene_path: "main"`）執行遊戲。若回傳 `runtime_ready: false`，或之後的 runtime 工具回報 `GAME_NOT_RUNNING`（但 log 顯示遊戲有在跑），先呼叫 `game_start`（`if_running: "return"`, `runtime_poll: true`）再重試；有時要**輪詢兩次**才會連上。實測：`game_start` 之後**等約 3～5 秒**（登錄檔更新後）再呼叫 runtime 工具最穩定。
2. `runtime_screenshot` 截圖確認畫面（**一律用 `image_response_mode: "disk"`** 再讀取存下的 PNG；inline 模式圖片超過約 1MB 會失敗，且曾回傳舊畫面）；需要互動時用 `input_simulate`（`click` 給座標，或 `click_node` 給節點路徑），再截圖確認結果。座標以 1152×768 為準。
3. `debugger_get_log` 讀錯誤與警告（遊戲剛啟動時 log 可能還沒印完，必要時再讀一次）。
4. 修好之後 `game_stop`。

- 流程較長時（例如一路點到三個結局），可另外寫 headless 測試腳本放在暫存區（不要放進專案）。
  **不要直接對本專案跑 headless**：外掛的 `MCPRuntimeServer` autoload 在 headless 也會啟動，會覆蓋 godot-mcp-toolkit 的 runtime 登錄（`~/Library/Application Support/godot-mcp-toolkit/`），導致正在執行的遊戲之後回報 `GAME_NOT_RUNNING`。
  做法：把專案 rsync 到暫存區（排除 `addons/`、`.mcp.json`、`build/`），刪掉副本 `project.godot` 裡的 `MCPRuntimeServer` autoload 與外掛啟用設定，再對副本執行 `Godot --headless --path <副本> --script <測試腳本>`。
- 劇本檢查也會檢查 `data/areas/*.json`：引用是否存在、`exit_to`、互動點類型、是否有出口、區域 BGM，以及區域場景的 `point_id` 是否與 JSON 一一對應（場景尚未建立時只顯示 ⚠ 提醒）。
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

> 下一版 **1.5** 的劇本調整規劃（分歧、快速結局、隱藏數值）見 `docs/v1.5_劇本調整規劃.md`，2026-10-05 起改寫成可移動版的「區域 × 事件」格式（見 `docs/Lv製作流程.md` 的「劇本 v1.5」一節）。實作前仍以本檔的規則為準。
>
> Lv1 的區域資料以 `from` **引用** `story.json` 的文字；**v1.5（Lv4 起）改成把文字直接寫在區域資料裡**（`title`／`text`，格式見 `docs/Lv製作流程.md` 的 Lv4），`from` 仍然支援。修改 `story.json` 時，若刪除或調換了被引用的場景或選項順序，用 `from` 的區域文字也會跟著變，請一併檢查（劇本檢查工具會檢查引用是否有效）。

劇本（`data/story.json`）之後會依 v1.5 定稿修改，例如處理下面的重複劇情。程式是完全依資料運作的，調整劇本時請注意：

- **程式不需要跟著改**的情況：修改文字、標題、hint、選項文字／response、增減場景或選項、改 `next_id`、改背景／BGM 檔名、改 `title_screen`、改 `start_id`。
- 結局判斷只看 `is_ending: true`；結局的選項不論 `next_id` 是多少，都會回到**標題畫面**。
- `next_id` 等於自己 id 的選項＝留在原地（會變暗）；選項數量不限，但超過約 6 個時對話框上方空間會不夠，需要調整 `Choices` 版面。
- 主文字很長時（超過約 3～4 行），對話框（畫面高度 35%）會不夠放，Body 會出現捲動；需要時再調整版面或字級。
- 新增素材放進 `assets/bg/`、`assets/bgm/`；新的 ogg BGM 會自動循環。**新增音效時要把該檔的匯入設定改成不循環**（專案預設 ogg 都循環，click.ogg 已處理）。
- 改完一定要跑劇本檢查（`tools/validate_story.gd`，注意上面「headless 會覆蓋 runtime 登錄」的說明），再重新匯出 Web 版。
- Claude 可以起草，但**未經作者定稿不可以寫入**；寫入後負責檢查格式、跑驗證與測試。

## 已知劇本問題（階段 1 不處理，僅供參考）

- 場景 1~16 大部分選項都通往同一個下一場景，真正的分歧只在場景 17。
- 場景 5/11、7/12、8/13、10/14 劇情重複。
- 用詞已統一（2026-10-02 作者決定）：主角名稱為「楊尚瑜」；保有意識的感染者稱為「**靜語者**」（不是噬語者），場景 15 已修正。
- 原專案缺 `bgm_13`，已用原專案中的〈Escape Through the Chaos〉代替。
