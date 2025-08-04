-- # TODO: クラス化
local ClassClipboardWatcher = {}
ClassClipboardWatcher.__index = ClassClipboardWatcher

function ClassClipboardWatcher:new(num)
    -- 一応タイマーのデフォルト値は2.0秒とする
    self.timer_interval = num or 2.0
    hs.pasteboard.watcher.interval(self.timer_interval)

    -- watcher
    self.pasteboardWatcher = hs.pasteboard.watcher.new(function(str)
        self:callbackBase(str)
    end)

    -- メニューの登録（最初はOFFからスタート）
    self.AppMenu = require("menu_manager"):new()
    self:stop()

    return self
end

function ClassClipboardWatcher:start()
    self.pasteboardWatcher:start()

    -- メニュー更新
    self.AppMenu:register("clipboard_watcher", {
        { title = "日付自動変換", fn = self:stop(), checked = true}
    })
end

function ClassClipboardWatcher:stop()
    self.pasteboardWatcher:stop()

    -- メニュー更新
    self.AppMenu:register("clipboard_watcher", {
        { title = "日付自動変換", fn = self:start(), checked = false}
    })
end

function ClassClipboardWatcher:callbackBase(str)
    -- コピーされたものが文字列でなければ何もしない
    if not str then return end

    -- 8桁数字の場合は、日付変換を行う
    if str:match("^%d%d%d%d%d%d%d%d$") then
        ClassClipboardWatcher:callbackDateChage(str)
    end

end

return ClassClipboardWatcher