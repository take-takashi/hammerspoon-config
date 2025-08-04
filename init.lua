-- 「このLuaファイルのパス、フォルダ」を取得・パス設定
local currentFilePath = debug.getinfo(1, "S").source:sub(2)
local currentDir = currentFilePath:match("(.*/)")
package.path = currentDir .. "?.lua;" .. package.path
-- print("currentFilePath = " .. currentFilePath)
-- print("currentDir = " .. currentDir)

-- ユーティリティ関数をロード
local utils = require("utils")

-- MenuManagerを初期化し、グローバルにアクセスできるようにする
local MenuManager = utils.safe_require("menu_manager")
if MenuManager then
    AppMenu = MenuManager:new()
end

-- クリップボード監視（8桁数字を日付に変換する）
local ClassClipboardWatcher = utils.safe_require("class_clipboard_watcher")
if ClassClipboardWatcher then
    ClassClipboardWatcher:new()
end

-- iCloudドライブを監視してtailscaleを起動・停止を行う
local ClassTailscaleTrigger = utils.safe_require("class_tailscale_trigger")
if ClassTailscaleTrigger then
    ClassTailscaleTrigger:new()
end

-- Sampleモジュールをロード
local classSample = utils.safe_require("class_sample")
if classSample then
    classSample:new()
end

-- メニューを更新（ID=core）
if AppMenu then
    AppMenu:register("core", {
        { title = "リロード", fn = function() hs.reload() end },
        { title = "コンソール", fn = function() hs.openConsole() end },
        { title = "設定", fn = function() hs.openPreferences() end }
    })
end

