# itch.io 上傳步驟（網頁版）

> 2026-10-07 建立，第一次打包的是 Lv6 完成版（暫用素材保留，例如 `assets/sfx/heartbeat.wav`）。
> 註冊帳號、上傳、公開都由作者自己操作。

## 1. 匯出與打包

1. **匯出網頁版**：照 `CLAUDE.md` 的做法，在拿掉外掛的副本上匯出，不要直接對本專案跑 headless。

   ```sh
   zsh tests/run_tests.sh      # 建立／更新副本 $TMPDIR/shiyuzhe_test_copy，順便跑測試
   /Applications/Godot.app/Contents/MacOS/Godot --headless \
     --path "$TMPDIR/shiyuzhe_test_copy" \
     --export-release "Web" "$PWD/build/web/index.html"
   ```

2. **先在瀏覽器試玩**，確認可以玩、有聲音。

3. **打包成 zip**：
   - `index.html` 必須在 zip 的**最外層**，不能包在資料夾裡。
   - 不要放 `.import` 檔。

   ```sh
   cd build/web
   rm -f ../shiyuzhe_web_itch.zip
   zip -X ../shiyuzhe_web_itch.zip index.* -x '*.import'
   unzip -l ../shiyuzhe_web_itch.zip    # 應該有 9 個檔案
   ```

4. 第一次打包（Lv6）的結果：
   - 檔案：`build/shiyuzhe_web_itch.zip`，壓縮後 55.9MB，解壓後 87.8MB。
   - 內容共 9 個檔案：`index.html`、`index.js`、`index.wasm`、`index.pck`、`index.audio.worklet.js`、`index.audio.position.worklet.js`、`index.png`、`index.icon.png`、`index.apple-touch-icon.png`。
   - `build/` 在 `.gitignore` 裡，zip 不會被 commit。

5. **A＋ 完成版（A6，2026-10-16）**：
   - 壓縮後 **39.2MB**、解壓後 **69.3MB**（`index.pck` 31.3MB＋`index.wasm` 37.7MB），一樣 9 個檔案。
   - 瘦身：沒用到的 8 首 BGM 不匯出、字型只留用到的字（`art/tools/font_subset.py`）。
   - 打包時另外排除各平台的系統檔（`.DS_Store`、`._*`、`__MACOSX`、`Thumbs.db`、`Desktop.ini`）：

     ```sh
     cd build/web
     rm -f ../shiyuzhe_web_itch.zip
     zip -X ../shiyuzhe_web_itch.zip index.* -x '*.import' -x "**/.DS_Store" -x "**/__MACOSX/**" -x "**/._*" -x "**/Thumbs.db" -x "**/Desktop.ini"
     ```

## 2. 上傳到 itch.io

1. 登入 itch.io，從右上角選單選 **Upload new project**。
2. 填基本資料：
   - **Title**：失語者
   - **Kind of project**：選 **HTML**
   - **Pricing**：選 **No payments**。只有在 `docs/素材來源.md` 裡**沒有任何非商業授權素材**時，才可以選 Donations（贊助可能被當成商業用途）
3. 在 **Uploads** 上傳 `shiyuzhe_web_itch.zip`，然後勾選 **This file will be played in the browser**。
4. 設定 **Embed options**：

   | 設定 | 值 | 原因 |
   |---|---|---|
   | Viewport dimensions | **1152 × 768** | 遊戲的基準解析度 |
   | Fullscreen button | 勾選 | 方便放大玩 |
   | Mobile friendly | **不要勾** | 目前不支援手機操作 |
   | SharedArrayBuffer support | **不要勾** | 匯出設定 `thread_support` 是 false，沒有用多執行緒 |

5. 填 **Details**：
   - 描述裡寫操作方式（A＋ 完成版）：
     - 方向鍵／A、D 移動（↑↓ 往畫面裡外走）
     - E／空白鍵：調查、互動；靠近掩護按 E 躲起來
     - G：比出手勢
     - 方向鍵＋Enter：選選項
     - 空白鍵：抵抗衝動（目前是按住；正式版是連打，見下方）
     - 標題畫面有「設定」（音量、打字聲）與「製作群」
   - 封面圖用遊戲截圖，建議尺寸 630×500。
6. 選 **Visibility & access**：
   - **Draft**：只有自己看得到，適合先預覽。
   - **Restricted**：設密碼，只給特定的人玩。
   - **Public**：公開。選之前先看下方的「公開前確認」。
7. 按 **Save**，再點 **View page**，在 itch.io 的頁面上完整玩一次。

## 3. 公開前確認

- [ ] 背景圖、BGM、字型（Noto Sans TC，OFL 授權）可以公開散布。字型是精簡版（只留用到的字），OFL 允許修改後散布；Noto 沒有保留字型名稱，不用改名。
- [ ] **Pricing 選 No payments**：BGM 是 Suno 產生的（免費方案為非商業使用），不能收費或開贊助。
- [ ] CC BY 素材的作者（cosmicembers、pfranzen、Metris）已列在遊戲的「製作群」；也可以在 itch.io 頁面再列一次。
- [ ] Godot Engine 的授權聲明已在「製作群」裡（引擎提供的 MIT 全文與第三方元件清單）。
- [ ] ~~暫用的心跳聲~~：A4 已換成 `heartbeat.ogg`（`heartbeat.wav` 留在專案裡沒有用到）。
- [ ] **壓抑衝動目前是按住的測試版**（`main.gd` 的 `RESIST_HOLD = true`）。公開前決定要不要改回連打（正式版）。
- [ ] 第一次載入要下載約 69MB（A6 瘦身後），網路慢的人會等比較久。
- [ ] 不支援手機（Embed options 不要勾 Mobile friendly）。

## 4. 之後更新版本

1. 照第 1 節重新匯出、試玩、打包。
2. 到 itch.io 的專案頁按 **Edit game**，在 Uploads 用新的 zip **取代**舊檔，確認新檔仍勾著 **This file will be played in the browser**。
3. Save 之後，在頁面上重新玩一次確認。
