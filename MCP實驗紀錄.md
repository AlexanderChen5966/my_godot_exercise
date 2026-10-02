# 失語者 階段 1：MCP 實驗紀錄

- 日期：2026-10-02
- 環境：macOS（Apple M2 Pro）、Godot 4.7.2 stable、Node 26、Claude Code
- 目標：用 Claude Code + Godot MCP 把 Kivy 版選項式遊戲重做成 Godot 網頁版，並觀察 MCP 能幫上多少忙。
- 結果：**階段 1 的 7 項完成標準全部達成**，網頁版已由使用者在瀏覽器實測（含聲音）。

---

## 1. 結論摘要

| 問題 | 觀察 |
|---|---|
| MCP 能不能建出整個 UI？ | 能。換成 Godot MCP Toolkit 後，步驟 4～6 的節點、版面、主題覆寫、音效資源**全部用 MCP 完成，沒有手改 `.tscn`**。 |
| MCP 能不能自己驗證？ | 能，而且是最大的收穫：`runtime_screenshot` + `input_simulate` + `runtime_get_script_vars` 讓 Claude 自己點、自己看、自己讀狀態，找出問題。 |
| 哪些還是要靠一般檔案編輯？ | GDScript 本身、`.import` 匯入參數、`export_presets.cfg`、長流程的自動測試。 |
| 哪些一定要人？ | **聽聲音**（BGM 換曲、音效好不好聽）、在外掛 UI 裡啟用外掛、安裝匯出模板、在真正的瀏覽器裡玩。 |
| 最大的坑 | MCP 工具本身的不穩定（截圖回傳舊畫面、runtime 登錄被覆蓋），而不是遊戲程式。 |

---

## 2. 兩套 MCP 的比較

一開始照 README 用 **Coding-Solo/godot-mcp**，步驟 3 之後換成 **Godot MCP Toolkit**（v1.0.2，MIT）。

| 項目 | Coding-Solo/godot-mcp | Godot MCP Toolkit |
|---|---|---|
| 架構 | 每次呼叫另開 headless Godot，執行一個操作就結束 | 編輯器外掛，透過 WebSocket 操作**開著的編輯器** |
| 編輯器要開著嗎 | 不用 | 一定要 |
| 修改根節點／掛腳本 | ✗（根節點固定叫 `root`） | ✓ `node_set_script`、`node_set_property` |
| 刪除／改名／排序節點 | ✗ 只有 `add_node` | ✓ `scene_delete_node`、`node_manage` |
| 主題覆寫、資源屬性 | ✗ 只能設數值 | ✓ 字型大小、顏色、陰影、AudioStream 都能直接設 |
| 專案設定 | ✗ | ✓ `project_set_setting` |
| 截圖 | ✗ | ✓ `runtime_screenshot` |
| 模擬輸入 | ✗ | ✓ `input_simulate`（click、key、click_node…） |
| 讀執行中變數 | ✗ | ✓ `runtime_get_script_vars`、`runtime_get_node_state`、`execute_code` |
| 腳本錯誤 | ✗ 解析錯誤只出現在 stdout，`errors` 欄位是空的 | ✓ `script_check`、`lsp_project_diagnostics` |
| 與編輯器衝突 | 會：MCP 直接寫 `.tscn`，編輯器存檔可能蓋掉 | 不會：改動經由編輯器並可復原 |

換掉的直接原因：步驟 1～3 中，**8 件事裡有 6 件必須繞過 MCP**（手改 `.tscn`、`project.godot`，或寫在 `_ready()`），而且 Claude 看不到畫面，使用者回報「按下沒反應」時只能靠推理和自寫測試。

---

## 3. 各步驟使用的工具

| 步驟 | 內容 | 用到的 MCP 工具 | 繞過 MCP 的部分（原因） |
|---|---|---|---|
| 0 | 確認連線 | `get_godot_version`、`get_project_info`（舊） | — |
| 1 | 讀劇本、顯示場景 1 | `create_scene`、`add_node`×6、`run_project`、`get_debug_output`（舊） | 根節點改名、掛腳本、設主場景、StyleBox（舊 MCP 不支援） |
| 2 | 選項與跳轉 | `add_node`×2（舊） | Hint 改成 RichTextLabel（舊 MCP 不能改型別） |
| 3 | 回應文字、選過的變暗 | `add_node`（舊） | — |
| — | **換 MCP** | — | 下載外掛並審查程式碼、使用者在編輯器啟用外掛 |
| 4 | 打字機、換場淡入淡出 | `scene_create_node`、`control_set_layout`、`node_manage`、`editor_save_scene`、`script_check`、`game_start`、`input_simulate`、`runtime_screenshot`、`debugger_get_log` | 無 |
| 5 | 標題畫面、BGM、音效 | 同上 ＋ 主題覆寫屬性、AudioStream 資源、`editor_refresh`、`runtime_get_node_state` | `click.ogg.import` 改成不循環（沒有改單一檔案匯入參數的工具） |
| 6 | 結局、回標題 | 同上 ＋ `execute_code`（直接跳到場景 17）、`lsp_project_diagnostics` | — |
| 7 | 網頁匯出 | — | `export_presets.cfg`、headless 匯出、Chrome 自動化（MCP 沒有匯出工具） |

---

## 4. 遇到的問題與解法

### 遊戲本身

| 問題 | 發現方式 | 原因 | 解法 |
|---|---|---|---|
| `StoryData` 找不到 | debug 輸出出現 `Debugger Break` | `scripts/` 裡多了一份 `project.godot`，Godot 把整個資料夾當成別的專案而略過 | 移除；寫進 CLAUDE.md 禁止事項 |
| 「按下沒反應」 | 使用者回報 | 選到 `next_id` 等於自己的選項，畫面原地重畫 | 先顯示 response（步驟 3），選過的變暗 |
| 選項讓故事「重複循環」 | 使用者回報 | 劇本本身：場景 11～14 重演 5/7/8/10 的事件 | 程式不處理，留給作者調整劇本 |
| click 音效一直響 | 使用者回報 | 專案把所有 ogg 匯入預設都設成循環，連 click.ogg 也是 | 只對 click.ogg 關掉循環 |
| 音效太單調 | 使用者回饋 | — | 打字時每 2～4 字隨機響一次，音高和音量隨機，標點不出聲 |

### MCP 工具

| 問題 | 原因 | 解法（已寫進 CLAUDE.md） |
|---|---|---|
| 舊 MCP 回報「沒有錯誤」，實際上有解析錯誤 | 錯誤只在 `output`，不在 `errors`；而且剛啟動就讀，錯誤還沒印出來 | 換工具；讀 log 前先等幾秒 |
| `game_start` 之後 `GAME_NOT_RUNNING` | **自己跑的 headless 測試也會啟動外掛 runtime，覆蓋共用的登錄檔** | headless 測試改在拿掉外掛的專案副本上執行；必要時用 `runtime_poll: true` 重新連線 |
| 截圖拿到舊畫面 | inline 回傳的圖片超過約 1MB 傳輸上限 | 一律用 `image_response_mode: "disk"` |
| 只更新單一檔案，匯入設定沒有生效 | 只改 `.import` 不會觸發重新匯入 | 用不帶參數的 `editor_refresh` 整個專案重新掃描 |
| Chrome 自動化測試很慢 | 自動化分頁在背景（`document.hidden`），畫面更新被節流 | 實際遊玩由使用者在前景瀏覽器測試 |

---

## 5. 人與 Claude 的分工

**Claude（透過 MCP 與檔案編輯）**
- 建立全部場景與節點、寫兩支 GDScript（約 370 行）
- 每個步驟執行遊戲、截圖、模擬點擊、讀變數來驗證
- 寫 headless 測試，跑過三條結局路線（每一步都檢查 response、打字跳過、換場、BGM）
- 查出 MCP 本身的問題並記錄解法；更新 CLAUDE.md／README／PROMPTS

**使用者**
- 在 Godot 編輯器裡啟用外掛、產生 `.mcp.json`、安裝匯出模板
- **聽聲音**：確認 BGM 換曲、指出 click 音效太煩、要求鍵盤感
- 發現遊玩體驗問題（「按下沒反應」「故事重複循環」）
- 在瀏覽器實際玩網頁版

使用者回報的 4 個問題中，有 3 個是**體驗或聲音**（反應回饋、音效、劇情重複），自動測試和截圖都抓不到。

---

## 6. 給階段 3（可走動的地圖）的建議

1. **繼續用 Godot MCP Toolkit**。地圖需要的 `tilemap`、`tileset`、`spriteframes`、`animation_authoring`、`navigation` 工具群組都有，用 `discover_tools` 開啟需要的就好。
2. **驗證以 MCP 為主**：`input_simulate` 可以送方向鍵、`runtime_get_node_state` 可以讀角色座標，比截圖更準確。截圖記得用 disk 模式。
3. **headless 測試一律用專案副本**，不要直接對專案執行，否則會干擾 MCP。
4. **聲音和手感還是要人來確認**，每一步保留讓使用者試玩的時間。
5. 新增任何 ogg 音效時記得關掉循環（專案預設是循環）。
6. 劇本調整後的流程見 PROMPTS.md「之後：劇本調整後」。

---

## 7. 最終狀態

- 節點樹：與 CLAUDE.md 建議架構一致，另外多了 `TypeSfx`（打字音效）
- `scripts/main.gd`：狀態機 TITLE／TRANSITION／TYPING／CHOOSING／RESPONSE
- `build/web/`：`index.pck` 約 48MB、`index.wasm` 約 40MB，不含 `addons/`、`tools/`、`.mcp.json`
- 完成標準：7／7 ✅
- 尚未處理：劇本重複（等作者調整）、標題文字與背景字跡重疊（可選的視覺調整）

---
---

# Lv1：停車場可走動（橫向捲軸、替代美術）

- 日期：2026-10-02
- MCP：Godot MCP Toolkit（只用這一個）
- 結果：Lv1 完成標準 8 項全部達成。網頁版在瀏覽器確認可以進入停車場；作者在 Godot 中試玩確認手感。

## 1. 各步驟使用的工具

| 步驟 | 內容 | MCP 工具 | 繞過 MCP 的部分（原因） |
|---|---|---|---|
| Lv1-0 | 對話框加高、直式持握提示 | `node_set_property`（batch）、`scene_create_node`、`control_set_layout`、`execute_code`（跳到場景 14、代入直式尺寸）、`input_simulate`、`runtime_screenshot` | `main.gd`（GDScript） |
| Lv1-1 | 讀規格、提出計畫 | — | — |
| Lv1-2 | UI 搬進 CanvasLayer | `scene_create_node`（CanvasLayer、Node2D）、`node_manage`（reparent `keep_global_transform: false`、reorder）、`node_set_property`（18 個 unique name） | `main.gd` 改用 `%Name` |
| Lv1-3 | 輸入設定、區域資料 | `input_map_action`、`input_map_event`、`script_check`、`editor_refresh` | `area_data.gd`、`validate_story.gd`；headless 驗證與反向測試 |
| Lv1-4 | 停車場、主角、鏡頭 | `scene_create`、`scene_create_node`（CharacterBody2D、CollisionShape2D＋`NewResource`、Camera2D、TextureRect、ColorRect）、`node_set_script`、`node_set_property`、`input_simulate`（action）、`execute_code` 讀座標 | `area.gd`、`player.gd` |
| Lv1-5 | 4 個互動點 | `scene_create_node`（Area2D＋碰撞形狀）、`node_set_script`、`node_set_property`（point_id、offset）、`node_manage` | `interact_point.gd`、`main.gd` 狀態 |
| Lv1-6 | 接上主流程 | `game_start`、`input_simulate`、`runtime_get_script_vars`、`runtime_screenshot`、`lsp_project_diagnostics` | `main.gd`；headless 三輪完整流程測試 |
| Lv1-7 | 匯出、紀錄 | — | headless 匯出（專案副本）；Chrome 自動化確認網頁版 |

**節點與場景**：Lv1 的所有節點（Main 的圖層搬移、停車場整個場景、互動點、提示文字）都用 MCP 建立，**沒有手改 `.tscn`**。繞過 MCP 的只有 GDScript、`.import`／匯出設定，以及 headless 測試。

## 2. Claude 自己發現並修好的問題

| 問題 | 怎麼發現的 | 解法 |
|---|---|---|
| `scene_create_node` 帶入版面屬性（`position`／`size`／`offset_*`）時，位置被重設成 (0,0)：地面跑到畫面上方、色塊沒對齊腳底 | MCP 回報成功，但**讀 `.tscn` 檢查**才發現（Lv1-4、Lv1-5 各一次） | 先建立，再用 `node_set_property` 設 offset |
| MCP 警告 anchor「存檔後可能不會保留」 | 工具回傳的 warning | 讀 `.tscn` 確認其實有保留（誤報） |
| 新腳本 `class_name` 在 `script_check` 中找不到 | `script_check` 錯誤訊息 | `editor_refresh` 後通過 |
| 移動距離異常（2 秒走 711px，之後自己往左） | 讀座標與遊戲狀態，發現遊戲被點進了場景 1 | 判斷為**使用者同時在操作遊戲視窗**；排除後重測正確（2 秒 = 280.0px） |
| 模擬按鍵能不能驅動 `Input.is_action_pressed()` | 計畫階段列為風險，**讀外掛原始碼**確認 | `action` 類型會呼叫 `Input.action_press`，不用改寫 |
| runtime 工具常回報 `GAME_NOT_RUNNING` | 多次重現；檢查登錄檔內容是正確的 | `game_start` 之後**等 3～5 秒**再呼叫 |
| 網頁版能否讀到 `data/areas/` | 計畫階段列為風險 | 匯出後在 Chrome 實際確認可以進入停車場 |
| 作者提出「按鍵衝突可能一按就開又關」 | — | 依「同一事件只處理一次」實作，MCP 驗證按一次 E 後狀態是打字中 |

## 3. 自動驗證的範圍

- **MCP 實玩**：移動（1 秒 137.7px、2 秒 280.0px）、左右邊界 16／2288、鏡頭限制 576～1728、UI 不隨鏡頭移動、4 個互動點的提示與文字、婦人只觸發一次、對話中不能移動、出口接場景 3、結局 → 標題 → 第二輪重新觸發。
- **headless**：三輪完整流程（停車場 → 場景 3～17 → 結局 A／B／C → 標題），全部通過。
- **劇本檢查**：區域資料 8 種錯誤的反向測試全部抓到；場景與 JSON 的 point_id 一一對應。
- **編譯**：`lsp_project_diagnostics` 7 個腳本 0 個問題（含警告）。

## 4. 作者試玩的回饋

| 項目 | 回饋 |
|---|---|
| 走路速度 | 很好，維持現在的節奏（140 px/秒） |
| 空白鍵／Enter 衝突 | 沒有問題 |
| 互動點 | OK |
| 提示文字 | 清楚 |
| **切換感** | **落差很大**：從可走動的停車場切回視覺小說很突兀。以第一版來說成果不錯，但**希望之後都用停車場這種可走動的方式進行** |

只有「切換感」需要人判斷，而且自動測試完全不會發現：它不是 bug，是體驗。這再次符合階段 1 的結論：**手感與整體體驗要靠人**。

## 5. 觀察與結論

1. **MCP 能自己驗證「移動與觸發」**：模擬按鍵＋讀座標的方式非常準確（誤差來自計時），比截圖可靠。Lv1 規格裡的驗證表全部由 Claude 自己完成。
2. **MCP 回報成功不代表結果正確**：版面屬性跑位兩次都是讀 `.tscn` 才發現。結論：**每次用 MCP 建立或修改節點後，都要讀檔或讀屬性確認**。
3. **與使用者同時操作會互相干擾**：MCP 驅動的是作者也看得到、點得到的同一個遊戲視窗。驗證時要先說明「請勿操作」，結果異常時先懷疑外部輸入。
4. **資料引用的設計有效**：區域文字用 `from` 引用 `story.json`，劇本統一用詞（靜語者）時區域不用改；劇本檢查也能同時把關兩邊。

## 6. 給下一級的建議

- **作者的回饋（切換落差大）建議提早處理**：目前路線是 Lv2（視差光影）→ Lv3（像素角色）→ v1.5 → Lv4（多區域）。如果更在意整體可走動的體驗，可以考慮把「多區域」提前，或在 Lv2 先做一個過渡（例如視覺小說畫面也顯示主角剪影）。是否調整順序由作者決定。
- MCP 建節點：先建立，再設版面屬性，最後讀 `.tscn` 確認。
- 測試前請作者不要操作遊戲視窗。

## 7. Lv1 最終狀態

- 新增：`scenes/areas/ParkingLot.tscn`、`scripts/area_data.gd`、`area.gd`、`player.gd`、`interact_point.gd`；Main 加入 `BgLayer`／`World`／`UILayer`／`PromptLabel`／`RotateHint`。
- 狀態機：TITLE／TRANSITION／TYPING／CHOOSING／RESPONSE／EXPLORE／AREA_TEXT。
- `build/web/`：`index.pck` 約 48MB，包含 `data/areas/`，不含 `addons/`、`tools/`、`.mcp.json`。

---
---

# Lv2：景深分層與光影（2.5D 的感覺）

- 日期：2026-10-02
- MCP：Godot MCP Toolkit（只用這一個）
- 狀態：**Lv2 完成**（完成標準 5/5）。作者在 Godot 與瀏覽器試玩確認，瀏覽器流暢沒有卡頓。

## 1. 各步驟使用的工具

| 步驟 | 內容 | MCP 工具 | 繞過 MCP 的部分（原因） |
|---|---|---|---|
| Lv2-2 | 三層視差 | `scene_create_node`（Parallax2D、ColorRect）、`node_manage`（reparent、reorder）、`node_set_property`（offset）、`execute_code`（讀 `get_screen_position()`） | `area.gd` 的視差參數（GDScript） |
| Lv2-3 | 黑暗＋手電筒 | `scene_create_node`（CanvasModulate、PointLight2D＋**巢狀 `NewResource`**：Gradient → GradientTexture2D）、`node_set_property`（`light_mask`）、`execute_code`（執行中直接改數值） | `area.gd` 的光影參數 |
| Lv2-4 | 紅色警示燈 | `scene_create_node`（PointLight2D）、`node_set_script`、`execute_code`（取樣 energy、執行中調整） | `flicker_light.gd` |
| Lv2-5 | 標題畫面 | `execute_code`（執行中切換三種版面並截圖）、`node_set_property`（寫入選定版本） | — |

所有節點與資源都用 MCP 建立，**沒有手改 `.tscn`**。

## 2. 調整了幾輪

| 項目 | 誰發現 | 輪數 | 經過 |
|---|---|---|---|
| 前景柱子擋住出口的主角 | Claude（截圖） | 1 | 前景移動 1.3 倍，鏡頭到底時第 4 根柱子剛好停在出口 → 移到 2240～2360 |
| 手電筒太弱 | Claude（截圖） | 1 | 半徑 256px＋背景已調暗 → 亮度 1.6、大小 1.5 |
| **背景只看到黑黑一片** | **作者** | 1 | 背景圖本身 55% × 世界 20% ≈ 11% → 背景改回原亮度、世界亮度 0.32（Claude 截 A／B 兩種，作者選 B） |
| 紅燈幾乎看不見 | Claude（截圖） | 2 | 先調大仍看不見 → 查出「2D 燈光 = 燈色 × 表面顏色」，暗青色的停車場反射不出紅色 → 亮度 5.0、範圍 2.0 |
| 標題壓在 HERE 上 | 階段 1 檢查 | 1 | Claude 做 A／B／C 三種版本截圖，作者選 A（下方置中） |

合計：Claude 自己發現並調整 **4 次**，作者回饋 **1 次**，作者做選擇 **2 次**（亮度方案、標題版本）。

## 3. 哪些描述方式對 AI 最有效

- **「看不到 X」比「調亮一點」有用**：作者說「背景只看到黑黑一片」，Claude 能直接去找「為什麼背景會黑」，結果找到是兩層調暗疊加，而不是單純把數值調大。
- **給選項讓作者挑，比 AI 自己決定好**：亮度（A／B）與標題（A／B／C）都是先截多張圖再讓作者選。主觀的東西，AI 負責產生候選，人負責選。
- **執行中直接改數值再截圖**（`execute_code`）是調整氛圍最快的方式：不用改檔、不用重啟，一輪只要幾秒。

## 4. 哪些只能靠人判斷

- 「背景太黑」是作者發現的。Claude 截圖時有看到「暗」，但以為那就是想要的氛圍，**無法判斷暗到什麼程度算過頭**。
- 標題版面的偏好（A 最接近原本的版面，B／C 風格較強），只能由作者決定。
- 紅燈的強度、閃爍頻率是否舒服，作者試玩確認沒問題。

這符合階段 1 與 Lv1 的結論：**AI 能找出「有沒有作用」與「為什麼沒作用」，但「好不好看」要靠人**。

## 5. AI 自己查出原因的例子

紅燈第一次調大後還是看不見，Claude 沒有繼續盲目加大數值，而是：
1. 讀 `.tscn` 確認設定和手電筒完全相同（排除設定錯誤）。
2. 推論「燈色 × 表面顏色」：暗青色表面的紅色成分很少。
3. 把亮度拉到 6 做驗證，確認判斷正確後才定案，並把原因寫進 `area.gd` 的註解。

## 6. 給作者調整的參數（ParkingLot 的屬性面板）

| 群組 | 參數 | 目前值 |
|---|---|---|
| 景深（視差） | `far_scroll`／`mid_scroll`／`front_scroll` | 0.3／0.7／1.3 |
| 光影 | `world_brightness` | 0.32 |
| 光影 | `flashlight_scale`／`flashlight_energy` | 1.5／1.6 |
| 光影 | `red_light_energy`／`red_light_speed` | 5.0／1.6 |

## 7. 效能與 Web 版（Lv2-6）

| 項目 | 結果 |
|---|---|
| Godot 內 FPS（debug 版，`main.gd` 的 `debug_fps()`） | 標題 60、移動中 60、出口附近紅燈最亮時 60（螢幕更新率上限） |
| Web 版匯出 | `index.pck` 約 47.8MB，含區域資料、停車場場景、閃爍腳本；不含外掛與 `.mcp.json` |
| 瀏覽器流暢度 | **作者確認流暢，沒有卡頓**（Compatibility 渲染器＋ 2 盞 2D 燈光＋ 3 層視差） |
| 陰影（`LightOccluder2D`） | 選做，這一級不做 |

- `execute_code` 不能存取 `Engine`，所以在 `main.gd` 加了只在 debug 版回傳數值的 `debug_fps()`。
- 網頁版的流暢度只能由作者判斷：自動化的瀏覽器分頁在背景會被降速，量不出真實 FPS。

## 8. Lv2 結論

1. **MCP 能建出完整的 2.5D 視覺結構**：Parallax2D、CanvasModulate、PointLight2D（含巢狀資源）全部用 MCP 建立。
2. **MCP 很適合「量化驗證」**：視差倍率用讀座標驗證，與設定完全吻合；燈光閃爍用取樣 energy 驗證。
3. **「執行中改數值 → 截圖」是調整主觀效果最快的方法**，並讓作者從多個候選中選擇。
4. **主觀判斷仍然要靠人**：「背景太黑」是作者發現的。
