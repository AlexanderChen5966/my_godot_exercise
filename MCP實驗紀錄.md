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

---
---

# Lv3 準備：安裝 Pixelorama MCP（第二個 MCP）

- 日期：2026-10-02
- 結果：**安裝完成**，`/mcp` 看得到 pixelorama，擴充功能在 `127.0.0.1:7373` 回應正常（93 個工具）。
- 安裝細節見 `docs/Lv製作流程.md` 的 Lv3「實際安裝紀錄」。

## 1. 安裝前的安全檢查（Claude）

| 檢查 | 結果 |
|---|---|
| npm 安裝時腳本（`postinstall` 等） | 沒有；正式相依套件只有官方 MCP SDK 與 zod |
| MCP 伺服器 | 只連 `127.0.0.1:7373`，不執行系統指令；寫檔只發生在匯出工具 |
| Pixelorama 外掛（約 5000 行 GDScript） | 只監聽 `127.0.0.1`，不執行系統指令；**沒有驗證機制**（本機任何程式都能下指令），不用時要關掉 Pixelorama |
| 附帶的 `PixMcpBridge.pck`（二進位） | 比對後 5 個原始檔一字不差包含在內，沒有多餘程式 |
| 根目錄的 `Pixelorama.pck` | 用途不明，不使用 |

## 2. 遇到的問題與解法

| # | 問題（症狀） | 原因 | 解法 | 誰發現 |
|---|---|---|---|---|
| 1 | `npm install` 失敗（ERESOLVE） | 作者 `package.json` 的 eslint 版本衝突（只影響開發工具），連帶裝不到 TypeScript | 用專案附的 lock 檔：`npm ci --legacy-peer-deps` | Claude |
| 2 | `npm audit` 有 3 個漏洞 | MCP SDK 內建 HTTP 功能的相依套件（本 MCP 走 stdio，用不到） | `npm audit fix --omit=dev --legacy-peer-deps` → 0 個漏洞 | Claude |
| 3 | Pixelorama 無法開啟 | App 只有 ad-hoc 簽章，Gatekeeper 阻擋 | 作者自行在「系統設定 → 隱私權與安全性」允許（安全設定由作者決定，Claude 不繞過） | — |
| 4 | **Preferences → Extensions 看不到 pix-MCP Bridge** | 紀錄檔：`Pack version unsupported: 4`。附帶的 `.pck` 是 **Godot 4.7** 打包（格式第 4 版），Pixelorama 1.1.10 內建 **Godot 4.6.2**，只讀得懂第 3 版。作者附的檔案與他文件指定的版本不相容 | 查 Pixelorama 原始碼，確認它也讀 `.zip` → 用已驗證的 5 個原始檔打包成 `PixMcpBridge.zip`（zip 沒有版本問題） | Claude（讀紀錄檔＋.pck 檔頭） |
| 5 | 換成 zip 後仍看不到／伺服器沒啟動 | 擴充功能資料夾被加入了 8MB 的 `Pixelorama.pck`（Pixelorama **自己的程式資料**），被當成擴充功能載入而跳出錯誤視窗，干擾畫面 | 刪除那份 `Pixelorama.pck`、清空 `Monitoring.ini` 的可疑紀錄 | Claude |
| 6 | 擴充功能載入了卻沒動作 | Pixelorama 的擴充功能**預設是停用的** | 在 Preferences → Extensions 勾選啟用（等同 `config.ini` 的 `[extensions] PixMcpBridge=true`）；紀錄檔出現 `HTTP server listening on 127.0.0.1:7373` 即成功 | Claude（讀 Pixelorama 原始碼） |
| 7 | `claude mcp list` 有 pixelorama，但 `/mcp` 看不到 | 用 **local 範圍**註冊，只在 Claude Code 判定的專案路徑相符時載入；啟動方式對不上就不會出現（godot-mcp-toolkit 寫在 `.mcp.json`，所以不受影響） | 改成 **user 範圍**：`claude mcp add -s user pixelorama -- node ~/Tools/pixelorama-mcp/mcp-server/dist/index.js`。不放 `.mcp.json`：那個檔案由 Godot 外掛管理、會進 git，且這是本機路徑 | 作者回報，Claude 查設定檔 |

## 3. Claude 判斷錯誤、事後更正的地方

| 一開始的判斷 | 實際情況 | 怎麼發現的 |
|---|---|---|
| 擴充功能資料夾裡的 `Pixelorama.pck` 是「作者修改過、來源不明的版本」 | 與 `/Applications/Pixelorama.app/Contents/Resources/Pixelorama.pck` **完全相同**，就是 Pixelorama 自己的程式資料 | `cmp` 比對 |
| 「Pixelorama 每次啟動都會把自己裝成擴充功能」（Pixelorama 的 bug） | 重新啟動後**沒有重現**；比較可能是透過 Preferences 的 Add Extension 選到了 App 內的同名檔案 | 再啟動一次觀察 |

教訓：**推論出原因後，要先重現或比對確認，再下結論**。這兩次都是先說了結論，後來才用比對／重現推翻。

## 4. 觀察

1. **第二個 MCP 的安裝難度比第一個高很多**：Godot MCP Toolkit 從 Asset Store 下載後啟用即可；Pixelorama MCP 是個人專案，遇到 7 個問題，其中 4 個是作者的檔案或文件本身的問題（版本不相容、依賴衝突、未說明預設停用）。
2. **「讀紀錄檔＋讀原始碼」是排除問題最有效的方式**：版本不相容、預設停用都是從 Pixelorama 的紀錄檔和原始碼找到的，而不是靠猜。
3. **自己從原始碼打包，比使用附帶的二進位檔更安全**：裝進去的就是檢查過的程式碼。
4. **需要作者的地方**：允許未認證的 App 開啟（安全設定）、在 App 介面中操作、確認 `/mcp` 的顯示。

---
---

# Lv3：用 Pixelorama MCP 畫主角（第一次兩個 MCP 配合）

- 日期：2026-10-05
- MCP：**pixelorama**（畫圖、動畫、匯出）＋ **godot-mcp-toolkit**（匯入、SpriteFrames、場景、驗證）
- 成果：32×48 像素、放大 2 倍的主角（感染者造型）。左右各一套，共 **20 格**：待機 4 格（4 fps）＋行走 6 格（8 fps）× 2 個方向。
- 狀態：**Lv3 完成**（完成標準 4/4）。作者在 Godot 與瀏覽器試玩確認（`index.pck` 約 47.8MB），並決定之後**繼續用 Pixelorama**。

## 1. 各步驟使用的工具

| 步驟 | 內容 | MCP 工具 | 繞過 MCP 的部分（原因） |
|---|---|---|---|
| Lv3-2 | 待機第 1 格 | pixelorama `draw_pixels`（一次 497 像素、16 色）、`capture_canvas_image`、`export_image`（放大 8 倍自我檢查）、`save_project` | 造型用 Python 以形狀設計並自動加外框（MCP 沒有「設計」能力，只負責畫）；Godot 預覽用 Toolkit 建立暫時的 Sprite2D |
| Lv3-3 | 待機 4 格 | `duplicate_frame`、`select_rect`＋`transform_selection`（上半身下沉 1px、頭再下垂 1px）、`add_animation_tag`、`set_fps` | — |
| Lv3-4 | 面向右行走 6 格 | `add_frame`、`draw_pixels`（第 1 格整格）、**`copy_cel`＋只送差異像素**（擦除用 `#00000000`）、`get_pixel`、`export_gif`、`delete_animation_tag`／`add_animation_tag` | 腿部姿勢用 Python 依姿勢表產生；放大 GIF 用 ImageMagick 製作 |
| Lv3-4b | 面向左 10 格 | 同上；9 格依「與哪一格差最少」排順序再用 `copy_cel` | 翻轉與修正（血跡換手、陰影換邊、遠側的手）用 Python 計算 |
| Lv3-5 | 放進遊戲 | pixelorama `export_animation`（spritesheet）；Toolkit `editor_refresh`、**`spriteframes_from_spritesheet`**、`scene_create_node`、`node_set_property`、`scene_delete_node`、`editor_save_scene`、`script_check`、`lsp_project_diagnostics`；驗證用 `game_start`、`input_simulate`（action）、`execute_code`、`runtime_screenshot`、`debugger_get_log` | `player.gd`（GDScript）、`.import` 改無損、`export_presets.cfg` |
| Lv3-6 | 匯出 | — | headless 匯出（專案副本，MCP 沒有匯出工具） |

所有節點與 SpriteFrames 都用 MCP 建立，**沒有手改 `.tscn`／`.tres`**。

## 2. 畫了幾次、改了幾輪

| 項目 | 誰發現 | 經過 |
|---|---|---|
| 第 1 版沒有駝背、兩腿黏在一起 | Claude（文字格線預覽） | 重畫第 2 版 |
| 後腦勺有兩格膚色（像耳朵長在後面） | Claude（放大 8 倍檢查） | 改成頭髮 |
| 待機第 3 格頭部移動後，下巴外框缺口、血跡少一格 | Claude（逐像素比對） | 補 2 格 |
| 「沒有走路的移動感、轉向沒有另一方向的像素」 | **作者** | Lv3-4／3-4b 處理；作者決定左右各畫一套（不用鏡像） |
| 行走後半步的步幅比前半步窄 | Claude（並排圖） | 兩腿的髖部差 2px，用相同偏移會不對稱 → 加大後半步的偏移 |
| 左向的外框變成兩層 | Claude（文字格線預覽） | 補外框時把舊外框當成身體 → 改成只看非外框像素 |
| 行走速度 8 fps 或 12 fps | **作者選擇** | Claude 做兩個 GIF，作者選 8 fps |

作者**沒有手動在 Pixelorama 修改任何像素**，全部透過 MCP 完成。

合計：Claude 自己發現並修正 **5 次**，作者回饋 **1 次**、做選擇 **3 次**（造型方案、左右畫法、行走速度），作者確認 **5 次**（造型、待機、行走、左向、試玩）。

## 3. 兩個 MCP 的配合

```
Python 設計像素 ──▶ pixelorama 畫格、標籤、存 .pxo
                     │ export_gif → 放大 GIF 給作者確認
                     │ export_animation（spritesheet）
                     ▼
            assets/sprites/player.png
                     │ Toolkit editor_refresh（匯入）
                     │ spriteframes_from_spritesheet（切成 4 個動畫）
                     ▼
     ParkingLot 的 Player/Sprite（AnimatedSprite2D）→ Toolkit 執行、操作、讀狀態驗證
```

- 兩個 MCP 之間**沒有直接連結**，靠檔案交接（spritesheet）。交接前用 ImageMagick 把 spritesheet 和已確認的畫格逐像素比對（0 差異），避免傳錯版本。
- 原本計畫用 pixelorama 的 `export_godot_spriteframes`，但它只能把**整個畫布**匯出成**一個**動畫，所以改用「spritesheet ＋ Toolkit 切割」。結果 Toolkit 的 `spriteframes_from_spritesheet` 一次呼叫就切好 4 個動畫，比預期簡單。

## 4. Pixelorama MCP 的穩定度與特性

| 觀察 | 內容 |
|---|---|
| 穩定度 | 整個 Lv3 呼叫了數十次，**沒有斷線或失敗**。需要 Pixelorama 一直開著 |
| 繪圖精確度 | 每一步都匯出後逐像素比對，**20 格全部 0 差異**：送出什麼就畫出什麼 |
| 傳送量 | 每格約 500 像素（約 17KB JSON）。改成「`copy_cel` 複製最相近的格 → 只送差異」後，每格只需 0～157 像素，**行走與左向共 16 格的傳送量約少了 3 分之 2**（約 2,600 像素，整格送出要約 7,800） |
| 擦除 | `draw_pixels` 的顏色用 `#00000000` 就能擦除（文件沒寫，用 `get_pixel` 驗證過） |
| **標籤會自動延伸** | 在最後一個標籤後面 `add_frame`，該標籤會被延長到包含新畫格（發生 2 次）。新增畫格後一定要 `get_animation_tags` 檢查 |
| fps 是整個專案共用 | 各動畫不同速度無法存在 `.pxo` 裡，改在 Godot 的 SpriteFrames 設定 |

## 5. AI 畫像素圖的方式

- **AI 不是「看著畫」，而是「算出來」**：用 Python 以形狀（橢圓、矩形、每列寬度表）組出角色 → 自動加外框 → 印成文字格線檢查 → 再送給 MCP。姿勢用數字表描述（膝蓋與腳踝的偏移、身體下沉量）。
- **好處**：修改很精準（「後半步偏移加大 2px」）、左右兩套可以從同一份資料推導，且每格都能驗證。
- **限制**：「好不好看」AI 判斷不了。造型方案、動作是否自然、播放速度，都是作者看 GIF 後決定的。
- **給作者看的形式很重要**：原尺寸 32×48 太小，一律放大 8 倍並做成 GIF；兩種速度並排讓作者比較，比文字描述有效。

## 6. Godot 端的重點

- 圖片匯入改成**無損**（專案預設有損 0.82，像素圖會糊）；節點用 Nearest 濾鏡、放大 2 倍。
- 角色在畫格中偏左 1px，左右兩套互為翻轉，所以 Sprite 的 x 在面向右時是 3、面向左時是 −1，轉身時身體中心才不會跳動。
- 動畫依「**實際**有沒有移動」切換（不是看有沒有按鍵），走到區域邊緣被擋住時會回到待機。
- `editor_refresh` 指定單一**新**檔案時不會匯入，要用全專案掃描。

## 7. Lv3 結論

1. **兩個 MCP 能完成「畫圖 → 進遊戲」的完整流程**，中間只靠一張 spritesheet 交接。
2. **Pixelorama MCP 很精確也很穩定**，但它只是「畫筆」：造型與動作要另外用程式設計，AI 的優勢在精確修改與驗證。
3. **「複製相近的格＋只送差異」是畫動畫的關鍵技巧**，傳送量大幅減少。
4. **主觀判斷仍然靠人**：作者指出「沒有走路感、沒有轉向」，並選了左右分開畫和 8 fps。

---
---

# Lv4：多區域、物品與旗標

- 日期：2026-10-05
- MCP：**godot-mcp-toolkit**（區域場景、autoload、SpriteFrames 以外的節點、驗證）＋ **pixelorama**（6 個像素道具）
- 成果：停車場（改成 v1.5）→ 街道 → 診所三個區域可以來回走；錄音筆「拿到前後事件不同」；數值（記憶、人性）與旗標在背景記錄；離開診所接回 1.0 的場景 6。
- 狀態：**Lv4 完成**（完成標準 5/5）。自動測試 24/24 通過；作者在 Godot 與瀏覽器試玩確認（`index.pck` 約 47.9MB）。

## 1. 各步驟使用的工具

| 步驟 | 內容 | MCP 工具 | 繞過 MCP 的部分（原因） |
|---|---|---|---|
| Lv4-0 | 範圍與資料格式 | — | 寫文件 |
| Lv4-1 | GameState、新格式、劇本檢查 | `autoload_manage`（註冊 GameState）、`script_check`、`lsp_project_diagnostics` | GDScript；劇本檢查與單元測試在專案副本上跑 |
| Lv4-2 | 區域切換 | `execute_code` 以 `Dictionary.merge` **在記憶體裡加一個測試區域**（不建檔案）、`input_simulate`、`runtime_screenshot` | `main.gd`／`area.gd`／`player.gd` |
| Lv4-3 | choice／item／variants、停車場 v1.5 | `scene_create_node`（醒來的地方）、`input_simulate` 的 `key`（方向鍵＋Enter 測選項） | `main.gd`、`parking_lot.json` |
| Lv4-4 | 街道 | **`editor_save_scene` 另存**停車場 → `node_manage`（改名、排序）、`scene_delete_node`、`node_set_property`（批次） | `street.json` |
| Lv4-5 | 診所 | 同上；`node_manage` duplicate（**子節點沒存進檔案**，改成重建） | `clinic.json`、`area_data.gd`（variant 分開記錄） |
| Lv4-6 | 像素道具 | pixelorama `create_canvas`／`draw_pixels`／`import_image`／`save_project`／`export_image`；Toolkit 建立 Sprite2D | Python 設計格線、ImageMagick 比對 |
| Lv4-7 | 測試與匯出 | — | headless 自動測試（副本，載入真正的 Main.tscn）、headless 匯出 |

## 2. Claude 自己發現並修好的問題

| # | 問題 | 怎麼發現 | 解法 |
|---|---|---|---|
| 1 | 街道的 `spawns` 指向還沒建立的診所 | 劇本檢查 | 先拿掉，診所建好再加回 |
| 2 | 背景圖重複拼接在中段有接縫 | 截圖 | 遠景只以 0.3 倍速移動，只需約 1500 寬 → 一張圖等比例蓋滿；**素材尺寸因此改成 1536×768** |
| 3 | 複製的互動點存檔後缺子節點 | 讀 `.tscn` | Toolkit 的 duplicate 不保存子節點 → 重建 |
| 4 | **先看過診療椅，拿到錄音筆後的選項版本不會出現** | MCP 照設計的流程實際走一遍 | 自動旗標讓「只觸發一次」誤判 → 每個 variant 的完成紀錄與數值來源分開（`clinic.chair#0`） |
| 5 | 藥櫃擋住主角 | 截圖 | 區域場景裡 `Points` 排在 `Player` 前面 |
| 6 | 藥櫃色塊太高（主角的兩倍），錄音筆高過頭頂 | 截圖 | 降到 120 |
| 7 | 照片、啟事、字卡的人臉用了主角的灰青膚色 | 放大預覽 | 改成一般膚色（感染前／圖畫） |
| 8 | `import_image` 匯入後 1 個像素變成相近的顏色 | 逐像素比對 | `draw_pixels` 補回 |

作者回饋 3 次（媽媽改長頭髮、字卡往下、藥櫃也畫成像素圖），每一步都由作者試玩確認後才繼續。

## 3. 自動驗證

| 層級 | 內容 | 結果 |
|---|---|---|
| 劇本檢查 | 新增 12 項（物品／旗標／數值對得上、出口與出現位置存在、每個區域走得到）；用故意寫錯 12 處的測試區域確認全部抓得到 | 通過 |
| 單元測試 | GameState 與 variants 的邏輯 | 12/12 |
| **自動遊玩測試**（Lv4-7） | headless 載入真正的 `Main.tscn`，用互動鍵與按選項跑三輪：A 不拿錄音筆、B 拿錄音筆、C 回標題再玩一輪 | **24/24** |
| 測試的有效性 | 故意把診療椅的條件改錯 → 遊玩測試 4 項失敗、劇本檢查也抓到 | 兩道檢查都有效 |

## 4. 兩個 MCP 的特性（Lv4 新發現）

| MCP | 觀察 |
|---|---|
| godot-mcp-toolkit | `editor_save_scene` 帶 `file_path` 可以另存場景，**做新區域最快**；`duplicate` 不保存子節點；`input_simulate` 的 `action` 不會移動按鈕焦點，測鍵盤選項要用 `key`；瞬移主角後要等物理更新 |
| pixelorama | 小道具一個畫布、`draw_pixels` 一次送完最單純；大圖改用 **`import_image`**：只吃 RGB／RGBA（調色盤 PNG 會被拒絕），而且**會把相近的顏色合併**，匯入後一定要比對 |

## 5. 專案變大之後，AI 的品質

- **規模**：腳本 9 個、區域 3 個、互動點 14 個。主要的錯誤（診療椅的 variant）不是寫錯程式，而是**兩個功能組合時的邊界情況**（自動旗標 × 只觸發一次 × variants）。
- **抓到它的是「照作者設計的流程實際走一遍」**（先坐 → 拿錄音筆 → 再坐），單元測試原本沒有這個情況。修好後把它加進單元測試和遊玩測試。
- **自動遊玩測試的價值**：三輪 24 項只要幾十秒，之後 Lv5 加東西時可以重複執行，確認 Lv4 的行為沒有被破壞。

## 6. Lv4 結論

1. **資料驅動的格式撐得住**：三個區域、物品、條件、多出口都只靠 JSON 描述，程式不用為每個區域寫特例。
2. **MCP 做場景、測試靠腳本**：建區域與調畫面用 Toolkit 最快；完整的遊玩流程用 headless 測試比 MCP 一步步操作穩定得多。
3. **「另存再修改」是做新區域的好方法**，但要注意複製節點的陷阱。
4. **給 Lv5 的建議**：剩下的 4 個區域照「另存 → 修改 → 資料 → 遊玩測試」的流程做；數值、Bad End、結局條件加進遊玩測試（最佳／一般／最差路線）。

---
---

# Lv5：其餘區域、Bad End 與結局

- 日期：2026-10-05～10-06
- MCP：**godot-mcp-toolkit**（4 個新區域場景、執行與截圖驗證）；本級沒有用到 pixelorama（像素人物與場景物件移到 Lv6）
- 成果：停車場 → 街道 → 診所 →〔搜捕隊〕→〔手術台〕→ 設施走廊 → 廢墟與避難所 → 舊家 →〔營火〕→ 牆前 → 結局，**7 個區域＋3 段過場**從頭玩到尾；3 個 Bad End 可以「從這裡重試」（回到檢查點、數值還原）；結局依記憶／人性解鎖，不夠的選項顯示灰色「……（你想不起來）」。
- 狀態：**Lv5 完成**（完成標準 6/6）。自動測試 Lv4 24/24、Lv5 29/29；劇本檢查通過；作者在瀏覽器試玩確認（`index.pck` 約 47.9MB）。

## 1. 各步驟使用的工具

| 步驟 | 內容 | MCP 工具 | 繞過 MCP 的部分（原因） |
|---|---|---|---|
| Lv5-0 | 拆成 Lv5／Lv6、範圍與格式 | — | 寫文件 |
| Lv5-1 | 檢查點、Bad End 重試、數值選項與鎖定、F3 數值 | `execute_code`（設定數值、跳到場景）、`input_simulate`、`runtime_screenshot` | `main.gd`、`game_state.gd`；劇本檢查加「窮舉路線」 |
| Lv5-2 | 設施走廊 | `editor_save_scene` 另存診所 → `node_manage`、`scene_delete_node`、`node_set_property`（批次） | `lab.json`、區域選項支援 `item` |
| Lv5-2-1 | 診所字卡掛到柱子上（作者回饋） | `scene_create_node`、`node_set_property` | — |
| Lv5-3 | 廢墟與避難所 | 同 Lv5-2 | `ruins.json` |
| Lv5-4 | 舊家 | 同上；互動點子節點用 `scene_create_node` 重建（避開 duplicate 的陷阱） | `home.json`（女兒用 variants 依筆記本換文字） |
| Lv5-5 | 牆前與結局 | 同上；`execute_code` 設定數值後重新產生選項，截圖三種解鎖情況 | `wall.json`、`story.json`（刪暫時的場景 17）；最後的亮度微調**直接改 `.tscn`**（原因見下方 #6） |
| Lv5-6 | 測試、匯出、紀錄 | `lsp_project_diagnostics` | headless 遊玩測試與匯出（專案副本，MCP 沒有匯出工具） |

## 2. Claude 自己發現並修好的問題

| # | 問題 | 怎麼發現 | 解法 |
|---|---|---|---|
| 1 | 結局 A 需要記憶 6，但 Lv5-1 時最多只到 5；BE2、BE3 走不到 | 劇本檢查的**窮舉路線** | 預期中的缺口，當成待辦清單：每補一個區域重跑，Lv5-3 起全部通過（最後上限記憶 9、人性 9） |
| 2 | 暫存區被系統清空，Lv4 的遊玩測試腳本不見 | 要執行時找不到 | 依對話紀錄重寫；作者決定測試放進專案的 `tests/`，加 `run_tests.sh` 自動建立副本 |
| 3 | 診所的柱子被窗光與手電筒照得太亮 | 截圖 | 改成暗的舊灰泥色 |
| 4 | 舊家的窗戶與女孩被對話框擋住 | 截圖 | 往上移到對話框上方 |
| 5 | 牆前沒有出口，劇本檢查報錯 | 劇本檢查 | 規則放寬：一定能選（沒有 `require`）、會離開區域的選項也算出口（「永遠遊走」） |
| 6 | **另存後編輯器仍在編輯原檔**：牆前的修改被存進 `Home.tscn` | 存檔回傳的路徑是 `Home.tscn` | 另存成 `Wall.tscn` 後用 git 還原 `Home.tscn`；寫進 `CLAUDE.md` 的規則 |
| 7 | 另存的 `Wall.tscn` 分頁停在舊內容，`editor_refresh` 也不會重新載入 | `scene_get_tree` 的根節點還叫 Home | 不在那個分頁存檔；亮度微調直接改 `.tscn`，請作者關掉分頁重開 |
| 8 | 牆面色塊被燈照成幾乎全白 | 截圖 | 調暗色塊與燈光 |
| 9 | 測試時出現 `set_can_move` on Nil | 遊戲 log | **Claude 測試步驟的錯**：在 `_start_game` 淡出還沒結束時就切換區域；分開執行即正常，玩家不會遇到 |

作者回饋：場景物件（燈、殘骸、車體等色塊）改在 Lv6 畫成像素圖；診所字卡不要漂浮。

## 3. 自動驗證

| 層級 | 內容 | 結果 |
|---|---|---|
| 劇本檢查 | 格式＋**窮舉所有路線**：6 個結局都走得到、數值上限（寬鬆估計）達到結局門檻、鎖住的選項門檻達得到 | 通過（9 個場景、7 個區域） |
| Lv4 遊玩測試 | 停車場～診所三輪（改成繼承共用的 `play_base.gd`） | 24/24 |
| **Lv5 遊玩測試** | 最佳路線（記憶 9、人性 8）→ A；一般路線（記憶 3、人性 −2，A 鎖住）→ B；最差路線（初始值，只剩 C）→ C；BE1／BE2／BE3 重試回到檢查點、數值與物品還原、事件人物重新出現；Bad End 回標題後重設 | **29/29**（全部約 40 秒） |
| lsp | 全專案（含測試） | 12 個檔案 0 錯誤 |
| Web 匯出 | `.pck` 內有 `story.json` 與 7 個區域資料；沒有外掛、測試、劇本檢查工具 | 通過 |

## 4. MCP 的特性（Lv5 新發現）

| 觀察 | 說明 |
|---|---|
| 另存不會切換編輯中的場景 | `editor_save_scene` 帶 `file_path` 後，接下來不帶路徑的存檔仍寫回**原檔**。Lv4 沒出事是因為另存後剛好先 `scene_open` 了新檔 |
| 編輯器不會重新載入已開的分頁 | 檔案在外部被改（或在另存前就開過），分頁會停在舊內容，`editor_refresh` 無效；`scene_get_tree` 的 `source` 和根節點名稱可以拿來確認 |
| runtime 連線仍要輪詢 | `game_start` 後常見 `GAME_NOT_RUNNING`，登錄檔其實已寫好；`runtime_poll` 後再等 3～5 秒最穩 |
| `execute_code` 很適合測資料驅動的遊戲 | 直接設定數值（`Dictionary.merge`）再重新產生選項，一次截完三種解鎖情況，不用真的玩三輪 |
| 過場的選項沒有鍵盤焦點 | 區域裡的選項會自動聚焦（可用 Enter），過場（搜捕隊、手術台、營火）只能用滑鼠點；測試時用 `click` 座標 |

## 5. Lv5 結論

1. **資料格式撐到最後**：7 個區域、3 段過場、6 個結局、檢查點都只靠 JSON 描述；Lv5 的程式改動集中在 Lv5-1，之後 4 個區域幾乎只寫資料與排場景。
2. **窮舉路線是好用的「待辦清單」**：還沒做的區域會讓結局走不到、門檻達不到，每補一塊就少一項錯誤，最後全綠。
3. **遊玩測試從 Lv4 延續下來最有價值**：共用操作抽成 `play_base.gd` 後，Lv5 的 29 項一次就通過；之後 Lv6 調整數值平衡時可以直接重跑。
4. **MCP 的編輯器狀態要自己確認**：另存、外部修改都可能讓「編輯器裡的場景」和「磁碟上的檔案」不一致，存檔前先看 `scene_get_tree`。
5. **給 Lv6 的建議**：過場選項的鍵盤焦點、像素人物與場景物件（取代色塊）、衝動機制（甲）、數值平衡（目前最佳路線記憶 9／人性 8，結局 A 門檻記憶 6、人性 3，可以再收緊）。

---
---

# Lv6：衝動機制、像素人物與場景物件、鍵盤操作、平衡

- 日期：2026-10-06
- MCP：**godot-mcp-toolkit**（節點、shader 疊層、`sound_generate`、換色塊、執行與截圖驗證）＋ **pixelorama**（6 組人物、18 張場景物件）
- 成果：所有選項只用鍵盤就能選；靠近「還沒發生的事件」時畫面泛紅、心跳加快、手電筒閃爍；6 組人物畫成像素圖（原圖有的照原圖）；6 個區域的色塊換成像素物件（燈、殘骸、車、路牌、柱子、圍籬、窗戶、門等）。
- 狀態：**Lv6 完成**（完成標準 6/6）。自動測試 Lv4 24/24、Lv5 29/29、Lv6 24/24；劇本檢查通過；lsp 14 個檔案 0 錯誤；作者完整試玩一輪確認平衡不用調整；Web 版 `index.pck` 約 47.9MB。

## 1. 各步驟使用的工具

| 步驟 | 內容 | MCP 工具 | 繞過 MCP 的部分（原因） |
|---|---|---|---|
| Lv6-0 | 範圍、`impulse` 格式、人物規格、物件清單 | — | 寫文件 |
| Lv6-1 | 所有選項自動聚焦、鎖住的不能聚焦 | `input_simulate`（`key`：方向鍵、Enter）、`runtime_screenshot` | `main.gd`；`test_lv6.gd` 改用真正的按鍵 |
| Lv6-2 | 衝動機制（甲） | `scene_create_node`（ImpulseOverlay＋Heartbeat）、`node_set_property`（ShaderMaterial）、**`sound_generate`**（暫用心跳聲）、`execute_code`（瞬移量距離）、`runtime_screenshot` | shader、`impulse_fx.gd`、`main.gd`、劇本檢查認得 `impulse` |
| Lv6-3 | 婦人（定規格） | pixelorama `create_canvas`、`draw_pixels`、`clear_cel`、`save_project`、`export_image`；Toolkit 換 `Figure` | 造型用 Python 格線設計；`.import` 改無損 |
| Lv6-4 | 其餘 5 組人物 | pixelorama `import_image`、`draw_pixels`（補像素）；Toolkit `node_set_property`（`region_rect` 讓女兒只露出上半身） | 同上 |
| Lv6-5 | 6 個區域的場景物件（牆前保留色塊、改英文字） | pixelorama `import_image`、`draw_pixels`、**`draw_rect`（半透明玻璃）**、`rename_canvas`、`switch_canvas`；Toolkit `scene_delete_node`、`scene_create_node`、`node_manage`（`duplicate` 燈光、`reorder` 前後順序）、`node_set_property` | Python 設計（共用 `pix.py`：外框、半透明、字型）、ImageMagick 逐像素比對 |
| Lv6-6 | 平衡 | — | 作者試玩一輪，數值不變 |
| Lv6-7 | 測試、匯出、紀錄 | `lsp_project_diagnostics` | headless 遊玩測試與匯出（專案副本，MCP 沒有匯出工具） |

## 2. 作者回饋與調整

Lv6 幾乎每一步都是「Claude 做第一版 → 作者看截圖 → 改一輪」，主觀的地方都由作者決定：

| 項目 | 作者的回饋 | 調整 |
|---|---|---|
| 婦人 | 「是參照原本場景圖片的人物塑造的嗎」 | 第一版只照劇本文字設計 → 照 scene_02 重畫；之後立下規則：**原圖有的照原圖畫，沒有的才自己設計**（存進記憶） |
| 婦人的嘴 | 尖叫的嘴型很怪 | 改回閉著的一格（手舉起來保留） |
| 警衛 | 要拿槍 | 加步槍與槍管下的手電筒 |
| 女兒 | 全身站在窗前很怪 | `region_rect` 只顯示上半身＋窗台擋住切口 |
| 感染者群 | 應該是一般人大小 | 照主角比例重畫（舊版另存 `horde_small`） |
| 出口 | 「做個門把才有門的感覺，用喇叭鎖」、不用 EXIT | 坡道 → 喇叭鎖鐵門；EXIT 版另存備用；之後換色成木門、做成破損版、舊家的鑲板門 |
| 燈管 | 頻率再慢一點 | 熄滅機率 0.03 → 0.01 |
| 車體 | 放大 1.3 倍 | 座標乘 1.3 重畫（不用非整數縮放，像素大小一致） |
| 尋人啟事的桿子 | 畫風一致 | 和路牌同畫風的水泥電線桿 |
| 背景已有字的兩個色塊 | 保留，改成英文 | `Daddy, I know it's you.`、`I'm still here.` |

## 3. Claude 自己發現並修好的問題

| # | 問題 | 怎麼發現 | 解法 |
|---|---|---|---|
| 1 | 選項剛出現時按空白鍵會**直接選到第一個**（自動聚焦的副作用） | MCP 截圖時狀態不對 | 選項出現後 0.3 秒內不接受選擇；加進測試 |
| 2 | 遊戲嵌在編輯器裡，編輯器不在前景時截圖是**舊畫面** | 截圖裡主角位置和讀到的座標不一致 | 先送一個無作用的 `execute_code`、等 0.5 秒再截（寫進 `CLAUDE.md`） |
| 3 | 新 PNG 預設**有損壓縮**，像素顏色會跑掉 | 遊戲截圖顏色和設計不同 | `.import` 改 `compress/mode=0` |
| 4 | Pixelorama `import_image` **會掉像素**（每張 3～49 格；稀疏細線的圍籬掉 471 格） | 每張匯出後都逐像素比對 | 用 `draw_pixels` 一次補回；比對改用 txt 逐格比（`compare -metric AE` 的數字不是格數） |
| 5 | `import_image` 會把**半透明像素變成不透明**（窗戶玻璃變實心） | 逐像素比對差 4540 格、並排看圖 | 匯入後用 `draw_rect`／`draw_pixels` 以 `#RRGGBBAA` 重畫玻璃 |
| 6 | 燈管被場景的暗色蓋成灰色，看不出是亮的 | 截圖 | `node_manage` 複製紅色警示燈，改成淡藍色、偶爾熄滅（文字「光線閃爍」） |
| 7 | 第一版預覽：感染者像墓碑、背像石頭、破窗像星空、鐵絲網太密看不到妻子 | 給作者看之前先看預覽 | 各自改一輪才交給作者 |
| 8 | 連續兩次在長串工具操作後**用英文回報** | 作者提醒 | 寫進記憶：工具之間的進度短句也用繁體中文 |

## 4. 自動驗證

| 層級 | 內容 | 結果 |
|---|---|---|
| 劇本檢查 | 格式、窮舉路線、`impulse` 欄位（故意寫錯 2 種都抓到） | 通過 |
| Lv4／Lv5 遊玩測試 | 改用真正的按鍵選選項後照常通過 | 24/24、29/29 |
| **Lv6 遊玩測試** | 選項聚焦與方向鍵、Enter 只開始打回應、空白鍵一次只做一件事、0.3 秒內不誤選、鎖住的選項不能聚焦、結局用 Enter 回標題、標題按一次空白鍵不跳過開場；衝動強度隨距離變化、選項出現時最強、選完淡出、手電筒還原、人走後不再觸發 | **24/24** |
| 像素圖 | 每張設計圖與匯出圖逐格比對 | 6 組人物＋18 張物件全部 0 差異 |
| lsp | 全專案 | 14 個檔案 0 錯誤 |
| Web 匯出 | `.pck` 有劇本、7 個區域資料、人物與物件圖、shader、心跳聲；沒有外掛、測試、`art/` 原始檔、劇本檢查工具 | 通過 |

## 5. MCP 的特性（Lv6 新發現）

| 觀察 | 說明 |
|---|---|
| Pixelorama 的 `import_image` 不是無損的 | 大張、稀疏、半透明的圖都會出錯；`draw_pixels` 才是精確的。最穩的做法是「匯入 → 比對 → 補差異」 |
| `draw_pixels` 一次可以送很多格 | 圍籬一次補 471 格沒有問題 |
| Toolkit `sound_generate` 夠當暫用音效 | 心跳聲直接在專案裡產生，作者之後再換 |
| `node_manage` 的 `duplicate` 適合複製燈光 | 沒有子節點的節點可以安全複製（GradientTexture 與腳本都會帶過去） |
| `reorder` 控制畫的前後 | 妻子在圍籬後、海報在電線桿前、窗戶在女兒前，都靠節點順序 |
| runtime 偶爾要重開 | 一次 `GAME_NOT_RUNNING` 輪詢無效，`game_stop`＋`game_start` 後正常 |

## 6. Lv6 結論

1. **「AI 先做、人來挑」是畫素材最有效的節奏**：每一區先給預覽或截圖，作者一句話（「用喇叭鎖」「放大 1.3 倍」「畫風一致」）就能精準改；造型的好壞仍然只有人能判斷。
2. **參考原圖要明確寫成規則**：第一個人物沒看原圖，作者指出後寫進規格與記憶，之後 5 組人物、6 區物件都先找原圖。
3. **工具會出錯，所以每一步都要能驗證**：Pixelorama 的匯入會掉像素、會吃掉透明度，靠逐像素比對全部抓出來；如果只看截圖，很多錯不會被發現。
4. **測試讓「改體驗」也能放心**：鍵盤、衝動機制、0.3 秒防誤選都寫成測試，之後換素材、調參數都可以重跑。
5. **作者的評價**：以第一版來說很好；下一版想做會動的像素、音效、更多場景與互動方式（記在 `docs/開發路線圖.md` 第 6 節）。

---
---

# 整體總結：階段 1 到 Lv6

從 Kivy 版的選項式遊戲，到 Godot 網頁版的橫向捲軸冒險（7 個區域、3 段過場、6 個結局、衝動機制、像素人物與物件），全程用 Claude Code ＋ 兩個 MCP（godot-mcp-toolkit、pixelorama）完成。

## 1. 每一級做了什麼

| 級 | 內容 | 主要的 MCP 用法 |
|---|---|---|
| 階段 1 | 視覺小說版：標題、打字機、選項、BGM 交叉淡入、結局 | Toolkit 建整個 UI、截圖與模擬點擊驗證 |
| Lv1 | 停車場可以走動（替代美術） | 建區域場景、`input_simulate` 走路 |
| Lv2 | 景深分層與光影 | Parallax2D、CanvasModulate、PointLight2D；執行中改數值再截圖給作者選 |
| Lv3 | 畫主角（20 格動畫） | 第一次兩個 MCP 配合：Pixelorama 畫 → spritesheet → Toolkit 切成 SpriteFrames |
| Lv4 | 多區域、物品與旗標、劇本 v1.5 | 另存區域再修改；headless 遊玩測試開始 |
| Lv5 | 其餘區域、Bad End、結局依數值 | 資料驅動，4 個區域幾乎只寫 JSON 與排場景 |
| Lv6 | 鍵盤、衝動機制、像素人物與物件 | Pixelorama 量產素材、Toolkit 換色塊與 shader |

## 2. AI 與 MCP 幫最多的地方

| 地方 | 為什麼 |
|---|---|
| **自己執行、自己看、自己修** | `game_start`＋`execute_code`＋`input_simulate`＋`runtime_screenshot`＋`debugger_get_log` 讓 Claude 能像玩家一樣操作並檢查畫面，很多問題在作者看到之前就修好了 |
| **建場景與節點** | 7 個區域、所有色塊換成 Sprite、燈光、shader 疊層，全部用 Toolkit 完成，很少手改 `.tscn` |
| **精確的像素繪圖** | 造型用程式設計，Pixelorama 照格畫，逐像素比對保證「設計＝成品」；改一個嘴巴只要 3 格 |
| **資料驅動的格式＋檢查工具** | 劇本、區域、條件、結局都在 JSON；劇本檢查窮舉所有路線，任何改動都能馬上知道結局還走不走得到 |
| **自動遊玩測試** | 77 項測試（Lv4 24、Lv5 29、Lv6 24）用真正的按鍵玩三條路線、三個 Bad End、鍵盤與衝動機制，約 40 秒跑完 |
| **把經驗寫成規則** | 每個踩過的坑（另存的陷阱、截圖舊畫面、有損匯入、掉像素、半透明）都寫進 `CLAUDE.md`，之後不再犯 |

## 3. 仍然需要人的地方

| 地方 | 例子 |
|---|---|
| **好不好看、好不好玩** | 背景太黑、婦人沒照原圖、女兒全身站在窗前很怪、感染者太小、出口要有門把、燈管閃太快——全部是作者看出來的 |
| **聽聲音** | BGM 換曲、心跳聲、音效好不好聽，Claude 聽不到 |
| **劇本** | Claude 可以起草，但定稿一定是作者 |
| **方向與取捨** | 改走可移動的新路線、Lv5 拆成 Lv5／Lv6、背景已有字的色塊要保留、這一版先到這裡 |
| **環境與安全** | 安裝 MCP 與外掛、匯出模板、在真正的瀏覽器試玩、關掉沒有驗證機制的 Pixelorama 連線 |
| **提醒 AI 的習慣** | 回答語言、參考原圖——作者提醒一次後寫進記憶 |

## 4. 給下一版的建議

1. **素材流程已經成熟**：Python 設計 → 預覽給作者 → Pixelorama 畫 → 逐像素比對 → Toolkit 換上 → 截圖確認。會動的像素可以沿用 Lv3 的「複製相近的格＋只送差異」。
2. **音效需要作者準備或挑選**：`sound_generate` 只適合暫用；腳步、環境音、互動音請作者決定風格。
3. **新的互動方式先寫進資料格式**：照 Lv4～Lv6 的做法擴充 JSON 欄位，同時讓劇本檢查和遊玩測試認得它。
4. **網頁版的大小**：`index.pck` 約 48MB（音樂占大部分），公開發布前再處理。

---
---

# A＋ A1：分層背景

- 日期：2026-10-08～2026-10-13
- MCP：**godot-mcp-toolkit**（建節點、排版、匯入、執行與截圖驗證）＋ **pixelorama**（74 張像素素材）
- 成果：7 個區域都從「一張插畫＋色塊」變成五層：遠景 0.3、中景 0.7、遊戲層 1.0（含像素地面）、近景（依前後排序）、前景 1.3。停車場遠景的重複拼接接縫修掉；燈管加上遊戲層的吊架；街道、診所、設施走廊、廢墟、舊家各有一個**放在路中間、不能穿過的障礙物**；牆前的灰色色塊換成灰泥牆面。
- 狀態：**A1 完成**。測試 98 項通過（劇本檢查＋Lv4 24、Lv5 29、Lv6 24、A1.5 21）；Web 版 `index.pck` 48.0MB（A1 全部素材只多約 0.1MB）；作者在編輯器試玩確認。

## 1. 各步驟使用的工具

| 步驟 | 內容 | MCP 工具 | 繞過 MCP 的部分（原因） |
|---|---|---|---|
| A1-0 | 讀現況、規劃五層 | `game_start`、`execute_code`（讀各層位置）、`runtime_screenshot` | 寫規劃 |
| A1-1 停車場 | 中景柱、天花板條、遠處的車、前景柱、地面、血泊、燈管吊架、近景 4 種 | pixelorama `import_image`、`draw_pixels`、`save_project`、`export_image`；Toolkit `scene_delete_node`、`scene_create_node`、`node_set_property`（`batch`）、`node_manage`（`reorder`）、`editor_refresh` | Python 設計圖＋ImageMagick 合成預覽與逐像素比對；`.import` 改無損 |
| A1-2 街道 | 店面×2、電線桿、公車亭、停著的車、地面、近景、前景；燒毀的車放到路中間 | 同上＋Toolkit `scene_create_node`（`StaticBody2D` 阻擋）、`input_simulate`（實測擋住的位置） | 屬性清單用 Python 產生 JSON 再一次送出（避免手打錯） |
| A1-3～A1-6 | 診所、設施走廊、廢墟、舊家 | 同上；pixelorama `draw_rect`（補整排掉的像素） | 同上 |
| A1-7 牆前 | 灰泥牆面取代色塊（英文字保留 Label）、極簡的中景與前景 | 同上 | 同上 |
| 收尾 | 測試、匯出、紀錄 | — | headless 測試與匯出（專案副本） |

## 2. 作者回饋與調整

| 項目 | 作者的回饋 | 調整 |
|---|---|---|
| 前景柱 | 用 B（像素剪影＋邊緣細節） | 「2D 與 2.5D 素材需求本來就不一樣，視情況調整」寫進記憶，Lv6 的畫面決定在 A＋ 只當參考 |
| 燈管 | 換素材後像飄在天上 | 遊戲層短梁＋吊鏈（中景的梁移動速度不同，不能掛在中景） |
| 人物移動 | 想要像《小朋友齊打交 2》那樣上下左右走 | 插入 A1.5（見下一節），排在其他 6 區之前，避免地面與近景重做 |
| 燒毀的車 | 看 A／B 截圖後選 B（放到路中間） | 加 `Block`（StaticBody2D），從車前或車後繞過去都能調查 |
| 障礙物 | 診所、設施走廊、廢墟、舊家都要 | 擔架床、翻倒的實驗推車、拒馬、倒下的衣櫃 |
| 流程 | 「素材製作完成後就直接放到場景上」 | 只在設計圖與最後成果兩處請作者看（寫進記憶）；A1-4 起「現況＋規劃＋設計圖」一次給 |
| 牆前 | 同意把色塊換成灰泥牆面 | 英文字仍用 Label，保持清楚 |

## 3. Claude 自己發現並修好的問題

| # | 問題 | 怎麼發現 | 解法 |
|---|---|---|---|
| 1 | 停車場遠景用**重複拼接**，走到出口有接縫、翻倒的車出現兩次 | A1-0 截圖 | 改等比例蓋滿、寬 1500（其他區早就是） |
| 2 | 設計圖預覽每一區第一版都有問題：中景太亮搶戲、店面像紙盒、牆板擋掉背景、倒塌的樓像完整方塊、斷牆變鋸齒、牆面像告示板 | 給作者看之前先疊在實際截圖上看 | 調暗、透空（觀察窗、破洞）、改不規則輪廓後才交給作者 |
| 3 | 預覽合成時 `-resize` 沒用括號，套用到整張圖 | 預覽尺寸變成 2304 | 每個疊圖都加括號 |
| 4 | Pixelorama `import_image` 每一區都會掉像素（停車場 4 格 → 牆前 167 格，舊家沙發整排 102 格） | 每張都逐像素比對 | `patch.py` 算出差異，`draw_pixels`／`draw_rect` 補回，全部 0 差異 |
| 5 | 前景剪影可能擋住主角或互動物件 | 擺放前用「前景 x − 1.3 × 鏡頭位置」算每個互動點 | 每一區都先算再放，實際截圖確認 |
| 6 | 暫存區被系統清空，繪圖工具不見 | A1-6 開始時找不到檔案 | 工具改放專案的 `art/tools/`（`.gdignore`，不匯出） |
| 7 | runtime 連線時好時壞 | `GAME_NOT_RUNNING` | 「停止重開」或「等 5 秒再輪詢兩次」，都記進路線圖 |
| 8 | 作者自己按 F5 試玩時，Claude 的指令送進同一個遊戲 | `game_start` 回報已經在執行 | 先停止再重開，並請作者試玩時先說一聲 |

## 4. 自動驗證

| 層級 | 內容 | 結果 |
|---|---|---|
| 像素圖 | 74 張設計圖與匯出圖逐格比對 | 全部 0 差異（補回共 651 格） |
| 視差 | 讀各層畫面位置，對照鏡頭位移 | 0.3／0.7／1.0／1.3 正確 |
| 阻擋 | `input_simulate` 按住方向鍵，讀主角停下的位置 | 車 738、擔架床 873、推車 868、拒馬 1123、衣櫃 793，都等於物件邊緣減去腳寬的一半 |
| 遊玩測試 | 換完 7 區畫面後全部重跑 | 98 項通過 |
| FPS | 每一區 | 60（編輯器內） |
| Web 匯出 | `.pck` 有 67 張圖層素材、道具、影子、劇本與 7 個區域資料；沒有外掛、測試、`art/` | 通過 |

## 5. MCP 的特性（A1 新發現）

| 觀察 | 說明 |
|---|---|
| `node_set_property` 的 `batch` 很適合大量排版 | 一區 20～30 個 Sprite 的貼圖、位置、縮放、翻轉一次送出；用 Python 產生 JSON 可以避免手打錯 |
| `NewResource` 可以直接建碰撞形狀 | 阻擋範圍、觸發範圍都不用另外建 `.tres` |
| `TextureRect` 的 `stretch_mode = 1` 加 `scale 2` 就是可拼接的像素地面 | 天花板管線條也一樣 |
| Pixelorama 的錯誤有規律 | 常是某一欄或某一列整條跑掉；`draw_rect` 一次補整排最快 |
| 截圖的顏色要讀數值判斷 | 圖片看起來偏亮，實際像素值很暗；用 `magick` 讀像素才知道 |

## 6. A1 結論

1. **「疊在實際截圖上預覽」比單看素材有用**：每一區第一版的問題都是放進畫面才看得出來（太亮、太方、擋背景），所以先合成預覽、自己修一輪再給作者。
2. **前景要先算再放**：前景移動得比主角快，擺錯位置會剛好擋住互動物件；用公式算每個互動點的螢幕位置，比放完再截圖找問題快。
3. **流程可以越來越短**：從「規劃 → 確認 → 設計 → 確認 → 製作 → 確認」縮成「規劃＋設計 → 確認 → 製作並放進場景 → 確認」，一區的往返從 4 次變 2 次。
4. **背景插畫仍是最大的落差**：7 張遠景都還是原本的第一人稱插畫（翻倒的車、拿筆記本的手、牆上的大字），要等作者用生圖 AI 產生 P1～P7 才會和側面視角一致。

---

# A＋ A1.5：上下左右移動（縱深帶）

- 日期：2026-10-08
- MCP：**godot-mcp-toolkit**（`input_map`、場景排序與觸發範圍、執行驗證）＋ **pixelorama**（影子）
- 成果：主角可以在縱深帶（腳的 y 650～735）上下左右走，上下 0.6 倍速；腳下有影子；人物、互動物件、近景依腳的位置前後遮擋；互動提示浮在頭上；互動要走到物件前面才觸發；婦人、科學家、警衛站到路中間。
- 狀態：**A1.5 完成**，作者試玩確認手感。

## 1. 各步驟使用的工具

| 步驟 | 內容 | MCP 工具 | 繞過 MCP 的部分（原因） |
|---|---|---|---|
| A1.5-0 | 縱深帶範圍、要不要深度縮放 | `execute_code`（直接改主角的 y 與縮放）、`runtime_screenshot` | — |
| A1.5-1 | 上下移動、影子、頭上的提示 | **`input_map_action`／`input_map_event`**（新增 `move_up`／`move_down`，寫入實體按鍵）、pixelorama `create_canvas`＋`draw_pixels`（半透明影子）、`node_set_property`（提示標籤改成不錨定） | `player.gd`、`area.gd`、`main.gd`；影子由程式加到 7 個場景共用的 Player |
| A1.5-2＋3 | y 排序、腳底判定、27 個互動點的觸發範圍、人物站到路中間 | `node_set_property`（`y_sort_enabled`、`z_index`、`NewResource` 形狀）× 7 個場景 | 腳底判定在 `player.gd`；`spawns` 支援 `[x, y]` |
| A1.5-4 | 測試 | `lsp_project_diagnostics` | 新增 `tests/test_a15.gd` 21 項 |

## 2. 作者回饋與調整

| 項目 | 作者的回饋 | 調整 |
|---|---|---|
| 深度縮放 | 不縮放 | 0.92 倍會讓像素粗細不均；規則「像素圖只用整數倍放大」寫進 `CLAUDE.md` |
| 提示位置 | 浮在主角頭上 | 原本固定在畫面下方，往外側走會擋路 |
| 觸發範圍 | 「還沒靠近物品就有提示」 | 主角判定改成腳底 24×12；互動點寬度和物件差不多，只涵蓋物件前方的地面；人物事件涵蓋整個縱深帶，避免從外側繞過劇情 |
| 婦人 | 應該站在路中間 | y 692；之後科學家、警衛也移過去，妻子、女兒、感染者群照劇情留在原位 |
| 速度 | 「上下左右速率很好」 | 不變 |

## 3. 自動驗證（`tests/test_a15.gd`，21 項）

移動到縱深帶邊緣停住、上下速度比例 0.6、影子畫在角色下面；離物件 100 沒有提示、60 有提示、提示在頭上、站在外側不觸發、站到前面可以調查、從最外側走向婦人照樣觸發；區域／互動點／近景都依 y 排序、前景在最前面、婦人在路中間；`place_player(x, y)` 的 y 與邊界；`spawns` 寫 `[x, y]` 通過、故意寫錯兩種都報錯。

## 4. A1.5 結論

1. **玩法的改動要在畫素材之前決定**：上下移動會改變地面高度與近景規則，所以插在停車場之後、其他 6 區之前，其餘區域一次就做對。
2. **「截圖 A／B 給作者選」對手感一樣有效**：縱深帶範圍、要不要縮放、車子放哪裡，都是先在遊戲裡暫時改、截圖給作者看再決定，不用先寫程式。
3. **改判定方式要 7 區一起改**：主角判定改成腳底後，其他區的互動點不跟著改就會碰不到，所以 A1.5-2 和 A1.5-3 合併做，每一區改完都跑全部測試。

---

# A＋ A2：光影與空氣感

- 日期：2026-10-13
- MCP：**godot-mcp-toolkit**（建節點、材質與 shader 參數、執行時調整強度、截圖驗證）；A2 沒有用到 pixelorama（粒子用 2×2 方塊、霧與光束用 shader，都不需要貼圖）
- 成果：7 區的主要燈光都有陰影，主角與 6 個人物有法線貼圖；每一區至少一種空氣感（停車場灰塵＋霧、街道火星＋霧、診所灰塵＋光束、走廊火花＋霧、廢墟灰燼＋霧、舊家光束、牆前光束）；人物事件時鏡頭推近、撲上去與槍聲時震動、衝動強度高時晃動。
- 狀態：**A2 完成**。測試 98 項通過；Web 版 `index.pck` 48.05MB（A2 只多約 0.05MB）；作者在瀏覽器測試完成。

## 1. 各步驟使用的工具

| 步驟 | 內容 | MCP 工具 | 繞過 MCP 的部分（原因） |
|---|---|---|---|
| A2-0 | 7 區截圖、規劃每區的效果與效能風險 | `game_start`、`execute_code`（換區域、瞬移）、`runtime_screenshot` | — |
| A2-1 | 停車場陰影＋主角法線貼圖，匯出網頁版試效能；之後套到 7 區與 6 個人物 | `scene_create_node`（`LightOccluder2D`）、`node_set_property`（`NewResource` 建 `OccluderPolygon2D`、燈光的 `shadow_*`／`height`）、`editor_save_scene` | 遮光多邊形用 `art/tools/occluder_poly.py` 由貼圖算出（凸包，或歪斜的柱子用 `span` 逐列取左右邊）；法線貼圖用 `normal_map.py` 產生；網頁版匯出（專案副本 headless，MCP 沒有匯出工具） |
| A2-2 粒子 | 灰塵、火星、灰燼、診所灰塵、走廊火花 | `scene_create_node`（`CPUParticles2D`）、`node_set_property`（`NewResource` 建 `Gradient`、`CanvasItemMaterial`）；`execute_code` 在遊戲中直接改數量、大小拍 A／B | 比較圖用 ImageMagick 合成 |
| A2-3 霧與光束 | 霧 shader、光束 shader | `node_set_property`（`NewResource` 建 `ShaderMaterial`、`material:shader_parameter/…` 設參數）、`execute_code` 呼叫 `set_shader_parameter` 拍 A／B | shader、noise 貼圖、霧的共用材質 `.tres` 用檔案寫入（內容是程式碼／資源檔） |
| A2-4 鏡頭 | 推近、震動、晃動 | `scene_create_node`（`unique_name`）、`node_set_script`（回傳 `@export` 清單）、`script_check`、`input_simulate`（實際選「撲上去」測震動）、`execute_code`（讀 `zoom`／`offset`、暫時隱藏對話框重拍） | `scripts/camera_fx.gd`、`main.gd` 的掛勾；資料加 `"camera": "shake"` |
| A2-5 | 測試、匯出、紀錄 | — | headless 測試與匯出（專案副本） |

## 2. 作者回饋與調整

| 項目 | 作者的回饋 | 調整 |
|---|---|---|
| 網頁版效能 | 陰影＋法線貼圖在瀏覽器流暢 | 法線貼圖不縮小範圍，套到所有人物 |
| 出口門 | 被自己的遮光體壓暗，可以接受 | 其他區的門不加遮光體；可以看穿的圍籬也不加 |
| 粒子 | 選 B，「A 的顆粒太小」 | 大小 2～4、數量多（灰塵 150、火星 45、灰燼 140） |
| 霧與光束 | 選 A，「B 有點太多」 | 霧 0.3、光束 0.35；霧也加到街道、廢墟、走廊 |
| 鏡頭推近 | 第一次比較圖「文字擋住人物，看不出差別」 | 暫時隱藏對話框重拍；選 B（1.12），「壓迫感好一點」，震動、晃動一起用 B |
| 進度紀錄 | 「A＋ 的進度沒有做紀錄」 | 每一步都在路線圖加一列（寫進記憶） |
| 語言 | 報告變成英文時提醒「台灣繁體中文回答」 | 記憶補上：系統提醒之後的短句與長報告特別容易切回英文 |

## 3. Claude 自己發現並修好的問題

| # | 問題 | 怎麼發現 | 解法 |
|---|---|---|---|
| 1 | 主角自己的遮光體讓主角變暗 | A2-1 截圖 | 拿掉主角的遮光體；物件的遮光體一律放在 Sprite 底下、不放在燈光裡 |
| 2 | 手電筒 `height` 0 時法線貼圖照不亮正面 | 截圖人物整個變暗 | 手電筒 80、區域燈 60；`area.gd` 新增 `flashlight_height` |
| 3 | 燈桿的凸包變成大三角形，影子形狀錯 | 截圖影子和柱子對不上 | `occluder_poly.py` 加 `span` 模式；共線的點去掉，多邊形更小 |
| 4 | 粒子 A 幾乎看不見 | 第一次截圖 | 灰塵被 `CanvasModulate` 壓暗 → 調高數量與不透明度；灰燼改成不受燈光影響 |
| 5 | 火花截圖都剛好拍在兩次噴發之間 | 放大截圖什麼都沒有 | 在遊戲中暫時改成連續噴發確認位置與亮度，場景保留一陣一陣的設定 |
| 6 | 霧第一版像灰色雲塊貼在暗處 | 截圖 | 改成受燈光影響（暗處看不見），透明度分 24 階 |
| 7 | 光束第一版太寬，像一塊方形的光 | 截圖＋差異圖 | 改窄、加長、頂端淡入、條紋加強 |
| 8 | 差異圖整張白色 | 截圖 PNG 有 alpha 通道 | `magick` 比較前先 `-alpha off` |
| 9 | 推近時畫面底部露出灰帶 | 隱藏對話框重拍時看到 | 鏡頭的下緣限制會隨倍率放寬、鏡頭自己會往主角靠，額外往下移是重複計算 → 拿掉 |
| 10 | 震動、晃動貼邊時也會露出灰邊 | 讀 `get_screen_center_position` 算出來 | Camera2D 的 `offset` 不受 `limit` 限制，自己限制在區域內 |
| 11 | 測試步驟：開始遊戲後馬上換區域會當掉；重新進入同一區後節點名稱變成 `@Node2D@8` | `execute_code` 回傳錯誤 | 開始後等 2.5 秒再換區域；重新進入後用 `World.get_child(0)` 找區域 |

## 4. 自動驗證

| 層級 | 內容 | 結果 |
|---|---|---|
| 截圖 | 每一項效果在每一區截圖；粒子、霧、光束、推近都做 A／B 比較圖 | 作者依比較圖選擇 |
| 數值 | `execute_code` 讀鏡頭的 `zoom`、`offset`、畫面中心，讀背景圖的位置 | 推近 1.06／1.12 正確、震動中 offset 會動、限制函式擋住往外的位移 |
| 實際操作 | `input_simulate` 在婦人事件選「撲上去」；`leave_area(21)` 進入槍聲 | 鏡頭震動、背景圖震動都正常 |
| 遊玩測試 | 每一步改完都重跑 | 98 項通過 |
| log | 每次截圖後讀 `debugger_get_log` | 沒有錯誤 |
| Web 匯出 | `.pck` 有霧與光束的 shader、noise 貼圖、霧材質、`camera_fx.gd`、劇本與 7 區資料（含 5 個 `"camera": "shake"`）；沒有外掛、測試、`art/`、劇本檢查工具 | 通過 |

## 5. MCP 的特性（A2 新發現）

| 觀察 | 說明 |
|---|---|
| `NewResource` 可以一路建到底 | `OccluderPolygon2D`、`Gradient`、`CanvasItemMaterial`、`ShaderMaterial`（裡面再放 `Resource` 指向 shader）都能直接建，不用另外寫 `.tres` |
| `material:shader_parameter/…` 可以直接設 shader 參數 | 每個場景的強度、大小、顏色都用 batch 一次送出 |
| A／B 不用存兩份場景 | 遊戲執行中用 `execute_code` 改 `amount`、`set_shader_parameter`、`event_zoom`，同一個畫面拍兩張；作者選好再寫回場景或預設值 |
| `node_set_script` 會回傳 `@export` 清單 | 掛上腳本後馬上知道屬性面板會出現哪些可調參數 |
| 動態效果很難用截圖判斷 | 粒子、火花、震動、晃動在靜態截圖裡看不出差別；要靠讀數值（offset、`_shake_left`）或暫時改成連續效果 |
| UI 會擋住要比較的東西 | 對話框蓋住人物時，比較圖沒有意義；拍之前先想作者要看哪裡，必要時暫時隱藏 UI |
| runtime 連線仍然不穩 | `GAME_NOT_RUNNING` 時等 10～15 秒再輪詢；開始遊戲後要等一下才能換區域 |

## 6. A2 結論

1. **效能先試**：A2-1 先在一區做最重的兩項（陰影、法線貼圖）匯出給作者在瀏覽器看，確定流暢後才全部套用，之後的粒子、霧、光束都很輕（`.pck` 只多約 0.05MB）。
2. **A／B 在遊戲裡直接改最快**：同一個執行中的遊戲改參數、拍兩張，不用存兩份場景；作者每一項都很快就能決定（粒子 B、霧與光束 A、鏡頭 B）。
3. **比較圖要讓作者看得到差別**：第一次推近的比較圖被對話框擋住，等於白拍；拍之前先確認要比較的東西在畫面上，動態效果要另外說明或請作者實際試玩。
4. **重拍會抓到自己的錯**：為了讓作者看清楚而重拍，才發現推近時底部露出灰帶，以及震動可能露出區域外。只看數值或只拍一次都抓不到。
5. **背景插畫仍是最大的落差**：舊家的遠景沒有畫屋頂破洞，光束只能假設破洞在畫面外；等作者用生圖 AI 換成側面視角的遠景（P1～P7）後，光束與霧的位置可以再調。
