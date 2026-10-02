# 失語者：Godot 起始包（階段 1 · MCP 實驗）

這個資料夾已經是一個可以打開的 Godot 專案，裡面放好了素材、劇本和專案設定，
場景和程式交給 Claude Code 透過 Godot MCP Toolkit（編輯器外掛型 MCP）建出來，這就是這次要實驗的部分。

## 起始包裡有什麼

| 項目 | 內容 |
|---|---|
| `data/story.json` | 由原本的 `zombie_interactive_story_fully_ready3.json` 轉換，**劇情文字一字未改**，只改了檔名路徑和欄位名稱 |
| `assets/bg/` | 20 張背景，從 1536×1024 縮成 1152×768 的 WebP（總共約 0.9 MB，原本約 50 MB） |
| `assets/bgm/` | 20 首 BGM 轉成 OGG（約 39 MB，原本約 90 MB）；缺的 `bgm_13` 用〈Escape Through the Chaos〉補上 |
| `assets/sfx/click.ogg` | 原本的點擊音效 |
| `assets/fonts/` | Noto Sans TC（開源授權，可以公開散布）。**沒有放微軟正黑體 msjh.ttf**，它通常不能隨遊戲散布 |
| `project.godot` | 解析度 1152×768、網頁用的渲染器、中文字型、圖片匯入成有損壓縮、BGM 匯入成循環播放 |
| `export_presets.cfg` | 已經有「Web」匯出設定 |
| `tools/validate_story.gd` | 劇本檢查工具，會檢查缺檔和斷掉的跳轉 |
| `addons/godot_mcp_toolkit/` | Godot MCP Toolkit v1.0.2（MIT），讓 Claude Code 透過 MCP 操作編輯器 |
| `.mcp.json` | Claude Code 的專案 MCP 設定，由外掛產生 |
| `CLAUDE.md` | 給 Claude Code 的專案規格，Claude Code 開啟這個資料夾時會自動讀取 |
| `PROMPTS.md` | 一步一步要貼給 Claude Code 的指令 |
| `MCP實驗紀錄.md` | 階段 1 的 MCP 實驗過程、問題與觀察 |
| `docs/v1.5_劇本調整規劃.md` | 1.5 版規劃：分歧、快速結局、隱藏數值（規劃中，尚未實作） |
| `scenes/`、`scripts/` | 階段 1 完成的遊戲（主場景 `Main.tscn`、`main.gd`、`story_data.gd`） |

標題畫面暫時用 `scene_16`（「I'm still here」那張牆）和 `bgm_15`，之後想換可以改 `story.json` 裡的 `title_screen`。

---

## 安裝步驟（Mac，一次性）

### 1. 安裝 Godot 4.5 以上

1. 到 <https://godotengine.org/download/macos/> 下載標準版（不是 .NET 版）。
2. 解壓縮後把 `Godot.app` 拖到「應用程式」資料夾。
3. 第一次開啟如果被 macOS 擋住，在 Finder 對 Godot 按右鍵 → 打開。
4. 用 Godot 打開這個資料夾的 `project.godot` 一次，讓它完成素材匯入（大約一分鐘），然後就可以關掉。

Godot 執行檔的路徑（後面會用到）：

```
/Applications/Godot.app/Contents/MacOS/Godot
```

### 2. 確認 Node.js 22 以上

```bash
node -v
```

如果版本太舊，用 nvm 安裝：`nvm install --lts`。

### 3. 啟用 Godot MCP Toolkit

外掛已經放在 `addons/godot_mcp_toolkit/`（來源：<https://github.com/NPGameDev/godot-mcp-toolkit> 的 v1.0.2 release）。

1. 用 Godot 編輯器打開這個專案。
2. 「專案 → 專案設定 → 外掛（Plugins）」→ 勾選 **Godot MCP Toolkit** 的「啟用」。
   下方會出現「MCP」面板，輸出視窗顯示 `[MCPServer] listening on 127.0.0.1:65xx`。
3. 如果專案根目錄還沒有 `.mcp.json`：「專案 → 工具 → MCP Toolkit → Write .mcp.json」。
4. 在專案資料夾啟動 `claude`，詢問是否使用專案 MCP 伺服器 `godot-mcp-toolkit` 時選同意。
   MCP 面板的連線數變成 1 就代表成功。

> 這個 MCP 是**連到正在開著的編輯器**，所以用 Claude Code 時 Godot 編輯器要一直開著。
> 它能建立／修改／刪除節點、設定主題樣式和專案設定、執行遊戲、截圖、模擬點擊、讀 log 和檢查腳本錯誤。
>
> 為什麼不用原本的 Coding-Solo/godot-mcp？它每次都另外開 headless Godot 執行單一操作，
> 不能修改根節點、刪除節點、設定 StyleBox 或專案設定，也不能截圖或模擬輸入，實驗到步驟 3 時就換掉了。

### 4. 先跑一次劇本檢查（選擇性）

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/validate_story.gd
```

應該會看到：`場景 20 個、結局 3 個` 和 `✓ 劇本檢查通過`。

---

## 開始實驗

```bash
cd 這個資料夾
claude
```

接著照 `PROMPTS.md` 的順序，一步一步把指令貼給 Claude Code。

## 網頁版匯出與測試

1. 安裝匯出模板（只需要做一次）：Godot 編輯器 →「編輯器 → 管理匯出模板」→ 下載來源保持「最佳可用鏡像」→「下載並安裝」。
   只做網頁版的話只需要 Web 模板；全部安裝也可以，只是比較大。
2. 「專案 → 匯出」→ 選「Web」→ 匯出專案，輸出到 `build/web/`。
   Web 設定的 `exclude_filter` 已經排除 `tools/*, addons/*`，MCP 外掛不會被打包進去。
3. 在本機測試：

   ```bash
   cd build/web && python3 -m http.server 8000
   ```

   然後打開 <http://localhost:8000>。直接雙擊 `index.html` **不能**執行，一定要透過伺服器開啟。
   瀏覽器規定要先點擊才有聲音，所以標題畫面要點一下才會開始播音樂。
4. 想公開分享，可以把 `build/web/` 整個資料夾上傳到 itch.io（選 HTML 類型）。

## 之後的開發（Lv1～5）

階段 1 已完成。之後改成橫向捲軸、可走動的 2.5D 版本，分成 Lv1～5 逐步進行：

- 路線與決策：`docs/開發路線圖.md`
- 每一級的規格與流程：`docs/Lv製作流程.md`
- 分步指令：`PROMPTS.md` 的「Lv1 分步指令」

Lv3 起會加入 Pixelorama MCP（像素繪圖），安裝方式寫在 `docs/Lv製作流程.md` 的 Lv3。

## 劇本調整（附註）

劇本 `data/story.json` 之後可能再調整（例如場景 5/11、7/12、8/13、10/14 劇情重複）。
調整方向已整理在 `docs/v1.5_劇本調整規劃.md`（1.5 版）。遊戲完全依劇本資料運作，
一般的文字、選項、跳轉、素材檔名修改都**不需要改程式**。改完請：

1. 執行劇本檢查（見上方「先跑一次劇本檢查」）。
2. 在 Godot 裡從標題玩到結局確認一次。
3. 重新匯出 Web 版。

注意事項（例如新增音效要關掉循環、文字太長會超出對話框）整理在 `CLAUDE.md` 的「劇本之後可能再調整」。

## 疑難排解

- **Claude Code 說找不到 godot-mcp-toolkit 工具**：確認是在專案資料夾裡啟動 `claude`，啟動時有同意使用 `.mcp.json` 的伺服器；也可以執行 `claude mcp list` 檢查。
- **MCP 連不上**：確認 Godot 編輯器開著這個專案、外掛已啟用，下方 MCP 面板顯示 listening。改過外掛設定後要重新啟動 `claude`。
- **`class_name` 找不到（例如 `StoryData not declared`）**：檢查子資料夾裡是不是多了一份 `project.godot`（例如 `scripts/project.godot`），有的話刪掉，Godot 會略過含有 `project.godot` 的資料夾。
- **網頁版沒有聲音**：瀏覽器規定使用者要先點擊才能播放聲音，標題畫面的「點擊開始」就是為了這個。
- **網頁版裡帶著外掛程式碼**：在 Web 匯出設定的 `exclude_filter` 加上 `addons/*`。
- **中文出現方塊**：確認 `project.godot` 裡 `gui/theme/custom_font` 的設定還在。
- **Pixelorama 的 Extensions 看不到 pix-MCP Bridge**：看 `~/Library/Application Support/Pixelorama/logs/godot.log`。出現 `Pack version unsupported: 4` 表示 `.pck` 格式太新，改用從原始碼打包的 `PixMcpBridge.zip`（見 `docs/Lv製作流程.md` 的 Lv3）。
- **pix-MCP Bridge 有出現但 7373 沒回應**：擴充功能預設是停用的，到 Preferences → Extensions 勾選啟用。確認：`curl -s http://127.0.0.1:7373/health`。
- **擴充功能資料夾出現 8MB 的 `Pixelorama.pck`**：那是 Pixelorama 自己的程式資料，不是擴充功能，刪掉即可（否則每次啟動會跳錯誤視窗）。
- **`claude mcp list` 有 pixelorama，`/mcp` 卻沒有**：改成 user 範圍註冊（`claude mcp add -s user pixelorama -- node ~/Tools/pixelorama-mcp/mcp-server/dist/index.js`），再重開 Claude Code。
- **想停用外掛**：在「專案設定 → 外掛」取消勾選（會詢問是否清掉 `.mcp.json`），不要手動改 `project.godot`。
