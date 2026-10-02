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
