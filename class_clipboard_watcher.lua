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