local MenuManager = require("menu_manager")

local ClassTailscaleTrigger = {}
ClassTailscaleTrigger.__index = ClassTailscaleTrigger

---
-- @description このクラスのインスタンスを生成する
-- @return ClassTailscaleTrigger インスタンス
--
function ClassTailscaleTrigger:new()
    -- インスタンス化
    local self = setmetatable({}, ClassTailscaleTrigger)

    -- iCloudの特定のフォルダを監視する
    self.dirpath = os.getenv("HOME") .. "/Library/Mobile Documents/com~apple~CloudDocs/TriggerTailscale"

    -- ファイル監視のウォッチャーを作成
    self.watcher = hs.pathwatcher.new(self.dirpath, function(paths, flagTables)
        self:callbackBase(paths, flagTables)
    end)

    -- メニューの登録（最初はONからスタート）
    self.AppMenu = MenuManager:new()
    self:start()

    return self
end

---
-- @description ファイルの監視を開始する
--
function ClassTailscaleTrigger:start()
    self.watcher:start()

    -- 通知を表示
    hs.notify.new({title="Tailscale トリガー監視", informativeText="✅監視を開始しました。"}):send()

    -- メニュー更新
    self.AppMenu:register("tailscale_trigger", {
        { title = "Tailscale トリガー監視", fn = function() self:stop() end, checked = true }
    })
end

---
-- @description ファイルの監視を停止する
--
function ClassTailscaleTrigger:stop()
    self.watcher:stop()

    -- 通知を表示
    hs.notify.new({title="Tailscale トリガー", informativeText="⛔️監視を停止しました。"}):send()

    -- メニュー更新
    self.AppMenu:register("tailscale_trigger", {
        { title = "Tailscale トリガー", fn = function() self:start() end, checked = false }
    })
end

---
-- @description ファイルの変更を検知したときのコールバック関数
-- @param paths table 変更があったファイルのパスのテーブル
-- @param flagTables table イベントフラグのテーブル
--
function ClassTailscaleTrigger:callbackBase(paths, flagTables)
    for index, path in ipairs(paths) do
        local file_name = path:match("([^/]+)$") -- フルパスからファイル名を取得
        local event_flags = flagTables[index]

        -- print("----- DEBUG -----")
        -- print("file_name = " .. file_name)
        -- print("event_flags = " .. hs.inspect(event_flags))
        -- print("----- DEBUG -----")

        -- ファイルのイベントを確認（ファイル作成、もしくはiCloud経由でファイル作成（リネーム、改変））
        if not (event_flags.itemCreated or (event_flags.itemRenamed and event_flags.itemModified)) then
            goto continue
        end

        -- on.txtかつファイル作成イベントの場合
        if file_name == "on.txt" then
            hs.notify.new({title="Tailscale トリガー", informativeText="on.txt を検知しました。tailscaled を起動します。"}):send()
            print("Change: on.txt detected")
            hs.execute("screen -dmS tailscale_session tailscale up", true)
            os.remove(path) -- 処理後にファイルを削除
        end

        -- off.txtかつファイル作成イベントの場合
        if file_name == "off.txt" then
            hs.notify.new({title="Tailscale トリガー", informativeText="off.txt を検知しました。tailscaled を停止します。"}):send()
            print("Change: off.txt detected")
            hs.execute("tailscale down", true)
            os.remove(path) -- 処理後にファイルを削除
        end

        ::continue::
    end
end

return ClassTailscaleTrigger
