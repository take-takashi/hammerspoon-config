clipboardMenu = hs.menubar.new()

-- メニューバーに表示する「ツールアイコン」を白で定義
local icon_tool = hs.styledtext.new("\u{F040}", {
    color = { red=1, green=1, blue=1 },
    font = { name = "Webdings", size = 16 }
})

-- メニューバーのアイコンに「ツールアイコン」を設定
clipboardMenu:setTitle(icon_tool)

clipboardTimer = nil
lastClipboard = nil

function startClipboardWatcher()
    if clipboardTimer then return end
    lastClipboard = hs.pasteboard.getContents()
    clipboardTimer = hs.timer.doEvery(2, function()
        local content = hs.pasteboard.getContents()
        if content ~= lastClipboard and content:match("^%d%d%d%d%d%d%d%d$") then
            local y = content:sub(1,4)
            local m = content:sub(5,6)
            local d = content:sub(7,8)
            local formatted = string.format("%s/%s/%s", y, m, d)
            hs.pasteboard.setContents(formatted)
            hs.alert(string.format("📋 日付変換: %s", formatted))
            lastClipboard = formatted
        elseif content ~= lastClipboard then
            lastClipboard = content
        end
    end)
end

function stopClipboardWatcher()
    if clipboardTimer then
        clipboardTimer:stop()
        clipboardTimer = nil
    end
end

function updateClipboardMenu()
    if clipboardTimer then
        -- clipboardMenu:setTitle("🔨")
        clipboardMenu:setMenu({
            { title = "停止（📋日付変換）", fn = function()
                stopClipboardWatcher()
                updateClipboardMenu()
                hs.alert("📋 日付変換ウォッチャー：停止")
            end }
        })
    else
        -- clipboardMenu:setTitle("🔨")
        clipboardMenu:setMenu({
            { title = "開始（📋日付変換）", fn = function()
                startClipboardWatcher()
                updateClipboardMenu()
                hs.alert("📋 日付変換ウォッチャー：開始")
            end }
        })
    end
end

updateClipboardMenu()

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

-- 「このLuaファイルのパス、フォルダ」を取得する
local currentFilePath = debug.getinfo(1, "S").source:sub(2)
local currentDir = currentFilePath:match("(.*/)")
print("currentFilePath = " .. currentFilePath)
print("currentDir = " .. currentDir)

-- iCloudドライブを監視してtailscaleを起動・停止を行う
dofile(currentDir .. "trigger-tailscale.lua")
triggerTailscale(hs)