-- 「このLuaファイルのパス、フォルダ」を取得・パス設定
local currentFilePath = debug.getinfo(1, "S").source:sub(2)
local currentDir = currentFilePath:match("(.*/)")
package.path = currentDir .. "?.lua;" .. package.path
-- print("currentFilePath = " .. currentFilePath)
-- print("currentDir = " .. currentDir)

-- モジュールを安全にロードして初期化するヘルパー関数
local function safe_init(module_name)
    local ok, module = pcall(require, module_name)
    if not ok then
        local msg = "Error loading module: " .. module_name .. "\n" .. tostring(module)
        print(msg)
        hs.alert.show(msg)
        return
    end

    local ok_init, instance = pcall(function() return module:new() end)
    if not ok_init then
        local msg = "Error initializing module: " .. module_name .. "\n" .. tostring(instance)
        print(msg)
        hs.alert.show(msg)
        return
    end
end

-- MenuManagerを初期化し、グローバルにアクセスできるようにする
-- MenuManagerは必須コンポーネントなので、失敗した場合はアラートを出して後続処理を行わない
local ok, MenuManager = pcall(require, "menu_manager")
if not ok then
    hs.alert.show("Fatal: Failed to load MenuManager. Halting init.")
    return
end
AppMenu = MenuManager:new() -- アイコンは後から各モジュールで設定可能

-- クリップボード監視（8桁数字を日付に変換する）
safe_init("class_clipboard_watcher")

-- iCloudドライブを監視してtailscaleを起動・停止を行う
safe_init("class_tailscale_trigger")

-- Sampleモジュールをロード
safe_init("class_sample")

-- メニューを更新（ID=core）
AppMenu:register("core", {
    { title = "リロード", fn = function() hs.reload() end },
    { title = "コンソール", fn = function() hs.openConsole() end },
    { title = "設定", fn = function() hs.openPreferences() end }
})
