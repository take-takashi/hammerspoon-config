# 選択文字列ショートカット起動 設計書

## 1. ゴール
- macOS 上で任意アプリ内の文字列をユーザーが選択し終えたタイミングで、自動的に Shortcuts.app の所定ショートカットを実行する。
- ショートカットへ選択文字列を入力として渡し、テキスト処理・連携（例: 翻訳、Issue 作成、メモ登録）を即時に行えるようにする。

## 2. 想定ユースケース
- ブラウザや IDE で文章・コードをマウスドラッグ／Shift+矢印で選択 → 気に入ったショートカットでまとめて翻訳。
- メール本文の一節を選択 → そのまま Shortcuts 経由でタスク管理アプリに送信。
- ログを選択 → ショートカットで Slack 投稿や Issue テンプレ生成。

## 3. 監視とトリガー条件
1. `hs.eventtap` で `leftMouseUp` / `rightMouseUp` / `flagsChanged`（Shift 押下によるキーボード選択）を常時監視。
2. マウスボタン or Shift キーが離された時点を「選択完了」の候補とみなす。
3. 直前 500ms 以内にドラッグまたは Shift+矢印操作が行われていた場合のみ処理続行。
4. 連続トリガー抑制のため、最後に処理した選択文字列と比較し、同一ならスキップ（デフォルト 2 秒のクールダウンタイマ併用）。

## 4. 選択文字列の取得フロー
### 4.1 優先パス: アクセシビリティ API（AXSelectedText）
1. `hs.application.frontmostApplication()` から `hs.axuielement.applicationElement(app)` を取得し、`AXFocusedUIElement` → `AXSelectedText` を辿る。
2. Safari / Mail / TextEdit 等の AX 対応アプリではコピー操作なしで文字列を直接取得できる。Safari の WebArea は `AXSelectedText` を返す前提で実装。
3. 取得結果が空、もしくは AX 属性が未対応のアプリ（Electron, 独自 UI 等）では nil となるため、即座にフォールバックへ切り替える。
4. 文字列長が閾値（例: 200KB）を超える場合は Shortcuts CLI 呼び出し前にトリム + 警告。

### 4.2 フォールバック: 一時的なコピー方式
1. `hs.eventtap.keyStroke({"cmd"}, "c", 0)` を発火し、現在の選択範囲をクリップボードへコピー。
2. `hs.timer.doAfter(0.15, fn)` で少し待機し、`hs.pasteboard.getContents()` を取得。
3. 取得済みのプレーンテキストへ `hs.styledtext.getString()` を適用して完全な UTF-8 文字列へ変換。
4. トリム後に空文字列なら中断。
5. クリップボード保護設定が有効な場合は、操作前に `hs.pasteboard.getContents()` を退避し、処理後に `hs.pasteboard.setContents(prev)` で復元。

## 5. Shortcuts.app 実行仕様
- 実行方法: `hs.task.new("/bin/sh", ...)` で `cat <<'HS' | shortcuts run "${shortcutName}"` 形式のシェルスクリプトを生成し、取得文字列をヒアドキュメントにそのまま埋め込んでパイプ（`--input*` オプションは使わない）。
- `shortcutName` は設定ファイル or メニュー UI で差し替え可。
- 出力は stdout/stderr をロガーへ集約し、失敗時は `hs.notify` でユーザーへ通知。
- 文字列長が Shortcuts CLI の制限（約 200KB）を超える場合は先頭/末尾を省略し、警告を表示。

## 6. クラス設計案
| クラス | 役割 |
| --- | --- |
| `ClassSelectionShortcutTrigger` | 監視・選択検知のエントリーポイント。`start/stop` を公開し、`MenuManager` に登録する。 |
| `SelectionWatcher` | `hs.eventtap` と状態管理（最後のドラッグ時刻、クールダウン）を行う内部モジュール。 |
| `ShortcutRunner` | Shortcuts CLI 呼び出し、リトライ、ログ記録を担当。 |

### 6.1 ライフサイクルとメニュー連動
- 初期化時は `start()` を呼ばず、メニューの「選択ショートカット監視 ON」をユーザーが押した時に `SelectionWatcher:start()` と `MenuManager:register()` を起動。
- `stop()` では `hs.eventtap`/`hs.timer` をすべて停止し、メニュー項目を OFF 状態へ書き換える。省電力のため無操作時は完全に監視を外せる。
- 既存クラスと同じくメニュー操作からのトグル操作だけで状態が一元管理されるよう、`MenuManager` へ `checked = true/false` を渡す。

### 6.2 init.lua との責務分担
- `init.lua` からは他クラス同様に `ClassSelectionShortcutTrigger:new(AppMenu)` を呼ぶだけに留め、監視ロジックや `start/stop` 状態はクラス内部に閉じ込める。
- 将来的にグローバル eventtap を統合管理する場合でも、`SelectionWatcher` 側は「自前で eventtap を持つ」モードを基本とし、必要なら外部提供の eventtap へハンドラ登録するだけで動くよう API を分離しておく。
- `AppMenu` の登録名は `selection_shortcut` とし、既存メニュー構造と干渉しないよう owner 名を一意にする。

主要メソッド案:
```lua
function ClassSelectionShortcutTrigger:new(opts)
    self.shortcutName = opts.shortcutName or "SendSelection"
    self.cooldownSec = opts.cooldownSec or 2
    self.restoreClipboard = hs.settings.get("selectionShortcut.restoreClipboard", true)
    self.preferAXSelection = hs.settings.get("selectionShortcut.preferAX", true)
end

function ClassSelectionShortcutTrigger:handleSelectionFinished(eventMeta)
    local text = self.selectionWatcher:fetchSelectionText({preferAX = self.preferAXSelection})
    if not text then return end
    self.shortcutRunner:run(text)
end

function ClassSelectionShortcutTrigger:start()
    if self.running then return end
    self.selectionWatcher:start()
    self.running = true
    self.menuManager:register("selection_shortcut", {
        {title = "選択ショートカット監視", checked = true, fn = function() self:stop() end}
    })
end

function ClassSelectionShortcutTrigger:stop()
    if not self.running then return end
    self.selectionWatcher:stop()
    self.running = false
    self.menuManager:register("selection_shortcut", {
        {title = "選択ショートカット監視", checked = false, fn = function() self:start() end}
    })
end
```

## 7. 設定値と UI
- `shortcutName`: デフォルト値 + `hs.settings` 保存。メニュー/コンソールから変更可能。
- `cooldownSec`: クールダウン秒数。
- `watchAppsWhitelist` / `watchAppsBlacklist`: `hs.application.frontmostApplication()` ベースでフィルタ。
- `preferAXSelection`: AX 取得を優先するかどうか。特定アプリで不具合がある場合は OFF にして常にコピー方式へ。
- メニュー（`MenuManager`）に「選択ショートカット監視 ON/OFF」トグルと情報行（`ショートカット: SendSelection`）を追加。OFF の間はイベントタップとタイマーを止めることで CPU/バッテリー負荷をゼロにする。

## 8. 失敗時ハンドリング
- ショートカット実行が exit code ≠ 0 の場合 → 通知 + ロガー出力（stderr）。
- クリップボード復元に失敗した場合 → ログ + 状態フラグ。
- イベントタップがエラーを吐いた際は自動リスタート（`hs.timer.doAfter(1, self:startWatcher)`）。
- `hs.axuielement` が nil を返した場合はアクセシビリティ権限未付与の可能性を通知し、System Settings > Privacy & Security > Accessibility への誘導ボタンを表示。

## 9. テスト観点
- 代表アプリ（Safari, Mail, VSCode）で左ドラッグ・Shift+矢印でテキストを選択し、ショートカットが一度だけ走るか。
- クリップボード復元が有効な際、元データが破壊されないか。
- AX 取得が成功する代表アプリ（Safari, Mail, TextEdit）でコピーを伴わずに文字列が取得できるか。
- AX 非対応アプリ（Electron ベース等）でフォールバックが確実に動作するか。
- クールダウン中に同一文字列を再度選択した場合にトリガーしないか。
- Shortcuts CLI が見つからない環境で通知が出るか。
- 長文コピー（> 30KB）でも処理が完了するか。

## 10. 今後の拡張アイデア
- 選択文字列の MIME 推定（URL, JSON, Markdown）を行い、ショートカットへメタデータを追加で渡す。
- 選択結果をステータスバーアイコンに一時表示してユーザーにフィードバック。
- AppleScript 経由で frontmost app のウィンドウタイトル・URL もショートカットに渡す。
- 選択後に専用ポップアップでショートカットを選択できるクイックパレット機能。
