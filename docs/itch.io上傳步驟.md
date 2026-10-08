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
   - 描述裡寫操作方式：方向鍵移動、空白鍵／Enter 互動、方向鍵＋Enter 選選項。
   - 封面圖用遊戲截圖，建議尺寸 630×500。
6. 選 **Visibility & access**：
   - **Draft**：只有自己看得到，適合先預覽。
   - **Restricted**：設密碼，只給特定的人玩。
   - **Public**：公開。選之前先看下方的「公開前確認」。
7. 按 **Save**，再點 **View page**，在 itch.io 的頁面上完整玩一次。

## 3. 公開前確認

- [ ] 背景圖、BGM、字型（Noto Sans TC，OFL 授權）可以公開散布。
- [ ] 暫用素材（例如 Toolkit 產生的心跳聲）是不是要先換掉。
- [ ] 第一次載入要下載約 88MB，網路慢的人會等比較久。想縮短時，可以先壓縮 BGM（約能減一半）。

## 4. 之後更新版本

1. 照第 1 節重新匯出、試玩、打包。
2. 到 itch.io 的專案頁按 **Edit game**，在 Uploads 用新的 zip **取代**舊檔，確認新檔仍勾著 **This file will be played in the browser**。
3. Save 之後，在頁面上重新玩一次確認。
