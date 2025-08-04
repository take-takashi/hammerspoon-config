-- 「このLuaファイルのパス、フォルダ」を取得・パス設定
local currentFilePath = debug.getinfo(1, "S").source:sub(2)
local currentDir = currentFilePath:match("(.*/)")
package.path = currentDir .. "?.lua;" .. package.path
-- print("currentFilePath = " .. currentFilePath)
-- print("currentDir = " .. currentDir)

-- MenuManagerを初期化し、グローバルにアクセスできるようにする
local MenuManager = require("menu_manager")
AppMenu = MenuManager:new() -- アイコンは後から各モジュールで設定可能

--
local ClassClipboardWatcher = require("class_clipboard_watcher"):new()

-- ロード完了後に一度だけメニューを更新（ID=core）
AppMenu:register("core", {
    { title = "⚙️リロード", fn = function() hs.reload() end },
    { title = "⚙️コンソール", fn = function() hs.openConsole() end },
    { title = "⚙️設定", fn = function() hs.openPreferences() end },
})

-- ロードしたモジュール一覧を表示する
function showLoadedModules(hs)
    print("----- loaded modules begin -----")
    for k, v in pairs(hs) do
        if type(v) == "table" then
            print(k)
        end
    end
    print("----- loaded modules end -----")
end
showLoadedModules(hs)

-- iCloudドライブを監視してtailscaleを起動・停止を行う
dofile(currentDir .. "trigger-tailscale.lua")
triggerTailscale(hs)

local classSample = require("class_sample"):new()