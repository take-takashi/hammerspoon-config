local MenuManager = require("menu_manager")

local ClassClipboardWatcher = {}
ClassClipboardWatcher.__index = ClassClipboardWatcher

---
-- @description このクラスのインスタンスを生成する
-- @param num number pasteboard.watcherのインターバル（秒）
-- @return ClassClipboardWatcher インスタンス
--
function ClassClipboardWatcher:new(num)
    -- インスタンス化
    local self = setmetatable({}, ClassClipboardWatcher)
    -- 一応タイマーのデフォルト値は2.0秒とする
    self.timer_interval = num or 2.0
    hs.pasteboard.watcher.interval(self.timer_interval)

    -- クリップボード監視ウォッチャーを作成
    self.pasteboardWatcher = hs.pasteboard.watcher.new(function(str)
        self:callbackBase(str)
    end)

    -- メニューの登録（最初はOFFからスタート）
    self.AppMenu = MenuManager:new()
    self:stop()

    return self
end

---
-- @description クリップボードの監視を開始する
--
function ClassClipboardWatcher:start()
    self.pasteboardWatcher:start()

    -- メニュー更新
    hs.alert("✅日付自動変換")
    self.AppMenu:register("clipboard_watcher", {
        { title = "日付自動変換", fn = function() self:stop() end, checked = true }
    })
end

---
-- @description クリップボードの監視を停止する
--
function ClassClipboardWatcher:stop()
    self.pasteboardWatcher:stop()

    -- メニュー更新
    hs.alert("⛔️日付自動変換")
    self.AppMenu:register("clipboard_watcher", {
        { title = "日付自動変換", fn = function() self:start() end, checked = false }
    })
end

---
-- @description クリップボードの変更を検知したときのコールバック関数
-- @param str string クリップボードにコピーされた文字列
--
function ClassClipboardWatcher:callbackBase(str)
    -- コピーされたものが文字列でなければ何もしない
    if not str then return end

    -- 8桁数字の場合は、日付変換を行う
    if str:match("^%d%d%d%d%d%d%d%d$") then
        self:callbackDateChange(str)
    end

end

---
-- @description 8桁数字を日付形式に変換してクリップボードに書き込む
-- @param str string 8桁の数字文字列
--
function ClassClipboardWatcher:callbackDateChange(str)
    -- 8桁数字の場合は、「YYYY/MM/DD」形式に変換してコピーし直す
    if str:match("^%d%d%d%d%d%d%d%d$") then
        local y = str:sub(1,4)
        local m = str:sub(5,6)
        local d = str:sub(7,8)
        local formatted = string.format("%s/%s/%s", y, m, d)
        hs.alert(str .. " -> " .. formatted)
        -- クリップボードに書き込む
        hs.pasteboard.writeObjects(formatted)
    end
end

return ClassClipboardWatcher