# 給 Claude Code 的分步指令

照順序一次貼一段。每一步做完，先自己在 Godot 裡看看結果（或請 Claude 用 MCP 執行並截圖），再進下一步。
規格寫在 `CLAUDE.md`，Claude Code 會自動讀取，所以這裡的指令可以寫得很短。

> MCP 使用 **Godot MCP Toolkit**（編輯器外掛）。每次開始前，先用 Godot 編輯器打開這個專案並保持開啟，
> 再到專案資料夾啟動 `claude`。安裝方式見 `README.md`。

---

### 步驟 0：確認 MCP 連線

```
先讀 CLAUDE.md。用 godot-mcp-toolkit 讀取專案設定（project_get_settings）和主場景的節點樹（scene_get_tree），
並分析這個專案的結構，告訴我你看到哪些素材和設定。先不要修改任何檔案。
```

✅ 預期結果：Claude 回報專案設定，列出 20 張背景、20 首 BGM 和 story.json。

---

### 步驟 1：讀取劇本，顯示第一個場景

```
建立 scripts/story_data.gd，然後用 MCP 建立 scenes/Main.tscn（依 CLAUDE.md 的節點樹，先只做 Background 和 DialogPanel 這兩部分），
並設為主場景。先讓它顯示場景 1 的背景、標題和主文字（還不需要打字機效果和選項）。
用 MCP 執行遊戲、截圖並讀 log，確認沒有錯誤。
```

✅ 預期結果：截圖裡看到停車場背景，下方對話框有中文字。

---

### 步驟 2：選項與跳轉

```
加入 Choices 按鈕：依 choices 動態產生按鈕，點擊後前往 next_id。
同時處理 next_id 等於目前場景 id 的情況。執行遊戲，用 input_simulate 點幾個選項並截圖確認。
```

✅ 預期結果：可以一路點到結局。

---

### 步驟 3：顯示回應文字

```
依 CLAUDE.md 的「選擇流程」：點選項後先在對話框顯示 response，出現「▼ 點擊繼續」，點擊後才前往下一個場景。
留在原地的選項，回到同一場景時要變成半透明。
```

✅ 預期結果：選「停留不動」會先看到回應，再回到同一場景，該選項變暗。

---

### 步驟 4：打字機效果與換場淡入淡出

```
主文字和 response 加上打字機效果（打字中點擊就直接顯示全部），並在換場時讓背景淡出淡入。
```

---

### 步驟 5：標題畫面、音樂與音效

```
加入標題畫面（第一次點擊後才開始播放音樂），BGM 用 BgmA/BgmB 交替做淡入淡出、相同曲目不要重播，點選項時播放 click 音效。
```

---

### 步驟 6：結局

```
結局場景顯示「— 結局 —」，選「重新開始」時回到標題畫面。然後逐條對照 CLAUDE.md 的「完成標準」自我檢查，並回報結果。
```

---

### 步驟 7：網頁版匯出

```
用 export_presets.cfg 裡的 "Web" 設定匯出到 build/web/（記得排除 addons/*）。如果還沒安裝匯出模板，告訴我要怎麼安裝。
匯出後告訴我怎麼在本機的瀏覽器裡測試。
```

---

### 之後：劇本調整後

> 劇本之後可能再調整。作者改完 `data/story.json` 後，可以貼這段：

```
劇本 data/story.json 已更新。請不要改寫劇情，只做：跑劇本檢查、確認格式與跳轉、
用 MCP 從標題玩到每個結局並截圖確認版面（文字太長或選項太多要回報），最後重新匯出 Web 版。
```

---

# Lv1 分步指令：停車場可走動

> 階段 1 已完成。以下是新路線 Lv1 的指令，規格在 `docs/Lv製作流程.md` 的「Lv1」一節。
> 開始前：用 Godot 編輯器打開專案並保持開啟，再到專案資料夾啟動 `claude`。
> 每一步做完，先自己在 Godot 裡玩一下確認，再貼下一段。

---

### Lv1-0：開工前的小修正（選做）

```
讀 docs/Lv製作流程.md 的「Lv1 開始前的小修正」。把對話框加高到 anchor_top 0.62（Choices 同步調整），
用 execute_code 跳到場景 14 截圖確認沒有捲軸；再加上直式畫面時的「請將裝置橫向持握」提示。
```

✅ 預期結果：場景 14 的文字完整顯示，沒有捲軸。

---

### Lv1-1：讀規格、規劃（不改檔案）

```
讀 docs/開發路線圖.md 和 docs/Lv製作流程.md 的「0. 共通流程」與「Lv1」。
先不要修改任何檔案。告訴我你的實作計畫：要新增或修改哪些檔案與節點、會用哪些 MCP 工具、
哪些地方預計要繞過 MCP，以及你打算怎麼驗證。
```

✅ 預期結果：Claude 列出計畫。有不同意的地方，在這一步先講清楚。

---

### Lv1-2：UI 搬進 CanvasLayer（先確保階段 1 不壞）

```
依 Lv1 的「架構」：用 MCP 新增 BgLayer（layer -10）、World（Node2D）、UILayer（layer 10），
把 Background 移進 BgLayer，Fade、TitleLayer、StoryLayer 移進 UILayer，並同步修改 main.gd 的節點路徑。
這一步不要加任何新功能。用 MCP 從標題玩到場景 3、再到一個結局，截圖確認版面和階段 1 完全一樣。
```

✅ 預期結果：遊戲看起來和之前一模一樣，沒有錯誤。

---

### Lv1-3：輸入設定與區域資料

```
新增輸入動作 move_left、move_right、interact（按鍵見 Lv1 的「輸入設定」）。
寫 scripts/area_data.gd（讀 data/areas/*.json、解析 from 引用、提供「場景 id → 區域」查詢），
並擴充 tools/validate_story.gd 檢查區域資料的引用與 exit_to。
用 script_check 檢查，並對專案副本跑劇本檢查。
```

✅ 預期結果：劇本檢查顯示區域資料通過。

---

### Lv1-4：停車場場景與主角移動

```
用 MCP 建立 scenes/areas/ParkingLot.tscn（依 Lv1 的「架構」與「區域設計」，先不要互動點），
寫 scripts/area.gd 和 scripts/player.gd。暫時用 execute_code 把區域實例化到 World 裡測試。
用 input_simulate 按住方向鍵、runtime_get_node_state 讀 Player 座標，驗證移動、邊界、鏡頭跟隨，
並截圖確認 UI 沒有跟著鏡頭移動。
```

✅ 預期結果：色塊主角可以左右走，鏡頭跟著走，對話框區域固定不動。

---

### Lv1-5：互動點

```
用 MCP 在 ParkingLot 的 Points 底下放 Light、Debris、Woman、Exit 四個互動點，寫 scripts/interact_point.gd，
並在 UILayer 加上 PromptLabel。互動時沿用現有的對話框與打字機效果（區域文字狀態）。
逐一驗證：提示出現、文字正確、婦人事件只觸發一次、對話中不能移動。
```

✅ 預期結果：四個互動點都會顯示正確的文字。

---

### Lv1-6：接上主流程

```
修改 main.gd：show_scene() 遇到被區域接管的場景時進入區域，出口離開後前往 exit_to。
從標題開始實際玩：停車場 → 出口 → 場景 3 → 一路到結局 → 回標題 → 第二輪再進停車場。
逐條對照 Lv1 的「完成標準」與「驗證方式」自我檢查，並回報結果。
```

✅ 預期結果：Claude 回報完成標準的檢查結果。

---

### Lv1-7：試玩、匯出、紀錄

先由你自己在 Godot 裡玩，把感想（走路速度、互動點距離、切換是否突兀）告訴 Claude 修正。滿意之後：

```
匯出 Web 版（排除 addons/*）。在 MCP實驗紀錄.md 新增「Lv1」一節：用了哪些 MCP 工具、哪些繞過 MCP、
Claude 自己發現了哪些問題、哪些問題是我試玩才發現的。並更新 docs/開發路線圖.md 的進度紀錄。
```

---

# Lv2 分步指令：景深分層與光影

> 規格在 `docs/Lv製作流程.md` 的「Lv2」一節。玩法不變，只改視覺。
> 開始前：Godot 編輯器開著，**Claude 測試時請不要操作遊戲視窗**。

---

### Lv2-2：三層視差

```
依 Lv2 的「場景結構」，用 MCP 在 ParkingLot 加 FarLayer、MidLayer、FrontLayer（Parallax2D），
Backdrop 搬進 FarLayer，中景與前景用暗色柱子剪影。在起點、中段、出口截圖並讀各層位移，確認視差有作用。
```

✅ 預期結果：走動時遠景慢、前景快，看得出前後景深。

---

### Lv2-3：黑暗與手電筒

```
加上 Darkness（CanvasModulate）與主角的 Flashlight（PointLight2D，圓形光暈）。
把亮度與光暈參數做成 area.gd 的 @export。截圖確認光暈跟著主角，且對話框、提示文字沒有變暗。
```

---

### Lv2-4：紅色警示燈

```
在出口附近加 RedLight（PointLight2D），寫閃爍腳本，參數做成 @export。讀 energy 確認有在閃爍。
```

---

### Lv2-5：標題畫面

```
處理「失語者」壓在牆上 HERE 的問題：做 2～3 種版本，各截一張圖給我挑。
```

---

### Lv2-6：調整、匯出、紀錄

先由你在 Godot 裡試玩並調整（太暗、光暈太小等），把感想告訴 Claude。滿意之後：

```
回報 debug 版的 FPS，匯出 Web 版（排除 addons/*）。在 MCP實驗紀錄.md 新增「Lv2」一節：
調整了幾輪、哪些描述方式對 AI 最有效、哪些只能靠人判斷。並更新 docs/開發路線圖.md 的進度紀錄。
```

---

# Lv3 分步指令：用 Pixelorama MCP 畫主角

> 規格在 `docs/Lv製作流程.md` 的「Lv3」一節：32×48、放大 2 倍、感染者特徵明顯。
> 開始前：**Godot 編輯器和 Pixelorama 都要開著**；Claude 測試時請不要操作遊戲視窗與 Pixelorama。

---

### Lv3-2：待機第一格

```
用 pixelorama MCP 建立 32×48 的畫布與 12～16 色的調色盤，依 Lv3 的造型規格畫待機第一格。
用 capture_canvas_image 自我檢查後，存成 art/player.pxo。再把這一格放進遊戲的停車場（放大 2 倍）截圖給我看。
```

✅ 預期結果：看到主角的造型。**造型、比例、配色由你確認**，不滿意就描述哪裡要改（例如「頭太大」「看不出是感染者」）。

---

### Lv3-3：待機 4 格

```
以第一格為基礎完成待機 4 格（輕微搖晃、喘息），用 onion skinning 比對前後格，截圖或匯出 GIF 給我看動態。
```

---

### Lv3-4：行走 6 格

```
完成行走 6 格（拖著腳、步履蹣跚），截圖或匯出 GIF 給我看動態。
```

---

### Lv3-4b：面向左的一套

```
以面向右的 10 格為基礎，畫出面向左的待機 4 格與行走 6 格（不是單純鏡像：靠近鏡頭的是乾淨的左手，
有血跡的右手只露出一點；光源維持在左上）。截圖或匯出 GIF 給我看。
```

---

### Lv3-5：放進遊戲

```
匯出 spritesheet 到 assets/sprites/player.png，用 godot-mcp-toolkit 在 Player 底下建立 AnimatedSprite2D
（Nearest、放大 2 倍、腳底對齊），建立 idle_right／walk_right／idle_left／walk_left 四個動畫，修改 player.gd（依移動與面向播放對應動畫），
隱藏原本的色塊、移除暫時的 PreviewSprite。art/* 加進 Web 匯出的 exclude_filter。
```

---

### Lv3-6：驗證、試玩、匯出、紀錄

```
用 MCP 驗證動畫切換、左右翻轉、像素清晰、手電筒下的亮度。我試玩確認後匯出 Web 版，
在 MCP實驗紀錄.md 新增「Lv3」一節（Pixelorama MCP 的穩定度、繪圖品質、畫了幾次、兩個 MCP 的配合），並更新路線圖。
```

---

# Lv4 分步指令：多區域、物品與旗標

> 規格、資料格式、步驟表在 `docs/Lv製作流程.md` 的「Lv4」一節；劇本文字在 `docs/story_v1.5_draft.md`（定稿）。
> 範圍：停車場（改成 v1.5）、街道、診所。離開診所後接回 1.0 的場景 6。數值只記錄，Lv5 才使用。
> 開始前：Godot 編輯器要開著（Lv4-6 畫道具時 Pixelorama 也要開）；Claude 測試時請不要操作遊戲視窗。

---

### Lv4-1：全域狀態與資料格式

```
依 Lv4 的資料格式，新增 GameState autoload（用 autoload_manage 加入），讓 AreaData 能讀 v1.5 區域格式
（inline 文字、item／choice、require／variants、effects、多個出口、spawns），並擴充 validate_story.gd 的檢查。
story.json 加上 stats。舊的停車場資料要照常運作；用 script_check、劇本檢查（專案副本）、MCP 執行確認沒有壞掉。
```

✅ 預期結果：遊戲和之前完全一樣（這一步只是打地基）。

---

### Lv4-2：區域切換

```
讓出口可以通往另一個區域：多個出口、to.area、spawns、換區域淡出淡入、開場同一輪只顯示一次。
先用兩個暫時的測試區域驗證來回走、出現位置正確，驗證完刪掉測試區域。
```

---

### Lv4-3：新的互動點類型＋停車場換成 v1.5

```
實作 choice（對話框＋選項）、item、require／variants、effects、hide_on_done。
把停車場換成 v1.5（docs/story_v1.5_draft.md 的「① 停車場」）：新增「醒來的地方」互動點，婦人改成兩個選項。
用 execute_code 讀 GameState 確認數值與旗標，截圖給我看。
```

✅ 預期結果：在停車場試玩，婦人出現時可以選「強行壓制自己／撲上去」。

---

### Lv4-4：街道

```
用 godot-mcp-toolkit 建立街道區域（背景暫用 scene_03，有新背景就換上），寫入「② 街道」的文字。
停車場出口改成通往街道；街道有「回到停車場」與「走向診所」兩個出口。
```

---

### Lv4-5：診所

```
建立診所區域，寫入「③ 診所」的文字：藥櫃（得到錄音筆）、治療室、診療椅（拿到錄音筆前後內容不同）。
離開診所接回 1.0 的場景 6。用 MCP 走一遍「先坐診療椅 → 拿錄音筆 → 再坐」確認變化。
```

✅ 預期結果：停車場 → 街道 → 診所可以來回走，最後接到搜捕隊。

---

### Lv4-6：像素道具

```
用 pixelorama MCP 畫錄音筆、照片、尋人啟事、治療室字卡、診療椅（規格同主角：放大 2 倍、光源左上），
放大後給我看；確認後放進區域取代色塊。
```

✅ 預期結果：**造型由你確認**。

---

### Lv4-7：驗證、試玩、匯出、紀錄

```
寫 headless 測試（專案副本）：有／沒有拿錄音筆的路線、數值與旗標是否正確、回標題後狀態重設再玩一輪。
我試玩確認後匯出 Web 版，在 MCP實驗紀錄.md 新增「Lv4」一節，並更新路線圖。
```

---

## 實驗時可以觀察的重點

- 哪些步驟 Claude **真的用了 MCP 工具**（scene_create_node、node_set_property、theme_edit、game_start、runtime_screenshot、input_simulate、debugger_get_log），哪些是直接改檔案？
- 截圖和模擬點擊有沒有讓 Claude 自己發現版面或流程的問題並修好？
- `script_check`／`lsp_project_diagnostics` 有沒有在執行前就抓到腳本錯誤？
- 哪些地方 Claude 做不到、需要你在 Godot 編輯器裡手動調整（例如版面細節、顏色）？

這些觀察可以幫你判斷：之後做階段 3（可走動的地圖）時，MCP 能幫上多少忙。

> 實驗紀錄：一開始用的是 Coding-Solo/godot-mcp（headless CLI 型），步驟 1～3 時發現它不能修改根節點、刪除節點、
> 設定 StyleBox 和專案設定，也不能截圖或模擬輸入，所以換成 Godot MCP Toolkit。

## 卡住時

- 把 Godot 的錯誤訊息或截圖貼給 Claude Code。
- 叫它「先停下來，用 script_check 和 debugger_get_log 讀錯誤，截圖看畫面，再修正」。
- MCP 連不上時，確認 Godot 編輯器有開著這個專案，且下方 MCP 面板顯示 listening。
- 也可以把 log 帶回這個對話，我可以幫你看。
