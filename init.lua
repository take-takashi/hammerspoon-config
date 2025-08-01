clipboardMenu = hs.menubar.new()
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
        clipboardMenu:setTitle("📋✅")
        clipboardMenu:setMenu({
            { title = "停止（📋日付変換）", fn = function()
                stopClipboardWatcher()
                updateClipboardMenu()
                hs.alert("📋 日付変換ウォッチャー：停止")
            end }
        })
    else
        clipboardMenu:setTitle("📋❌")
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

-- ファイルの監視を実施する
function triggerTailscale(hs)
    -- iCloudの特定のフォルダを監視する
    local dirpath = os.getenv("HOME") .. "/Library/Mobile Documents/com~apple~CloudDocs/TriggerTailscale"
    local watcher = hs.pathwatcher.new(dirpath, function(files)
        for _, file_path in ipairs(files) do
            local file_name = file_path:match("([^/]+)$") -- フルパスからファイル名を取得
            if file_name == "on.txt" then
                hs.notify.new({title="Tailscale トリガー", informativeText="on.txt を検知しました。tailscaled を起動します。"}):send()
                print("Change: on.txt detected")
                hs.execute("tailscale up")
            elseif file_name == "off.txt" then
                hs.notify.new({title="Tailscale トリガー", informativeText="off.txt を検知しました。tailscaled を停止します。"}):send()
                print("Change: off.txt detected")
                hs.execute("tailscale down")
            end
        end
    end):start()
end
triggerTailscale(hs)