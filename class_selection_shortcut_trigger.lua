local MenuManager = require("menu_manager")
local logger = require("logger")

local SelectionWatcher = {}
SelectionWatcher.__index = SelectionWatcher

local ShortcutRunner = {}
ShortcutRunner.__index = ShortcutRunner

local ClassSelectionShortcutTrigger = {}
ClassSelectionShortcutTrigger.__index = ClassSelectionShortcutTrigger

local SHORTCUTS_BIN = "/usr/bin/shortcuts"
local SHORTCUT_BYTE_LIMIT = 200 * 1024 -- 200KB 目安

local arrowKeyCodes = {
    [hs.keycodes.map.left] = true,
    [hs.keycodes.map.right] = true,
    [hs.keycodes.map.up] = true,
    [hs.keycodes.map.down] = true,
}

local function shellQuote(str)
    local s = tostring(str or "")
    if s == "" then
        return "''"
    end
    return "'" .. s:gsub("'", "'\"'\"'") .. "'"
end

local function buildPipeScript(shortcutName, text)
    local token = "HS_SELECTION_" .. hs.hash.SHA1(tostring(hs.timer.absoluteTime()))
    local commandLine = string.format("cat <<'%s' | %s run %s", token, SHORTCUTS_BIN, shellQuote(shortcutName))
    return table.concat({commandLine, text, token, ""}, "\n")
end

-- SelectionWatcher: マウスドラッグやShift+矢印での選択完了を検知
function SelectionWatcher:new(opts)
    opts = opts or {}
    local obj = setmetatable({}, self)
    obj.onSelection = opts.onSelection
    obj.activityWindow = opts.activityWindow or 0.5
    obj.eventtap = nil
    obj.isDragging = false
    obj.shiftHeld = false
    obj.shiftSelecting = false
    obj.lastActivityAt = 0
    return obj
end

function SelectionWatcher:start()
    if self.eventtap then
        self.eventtap:start()
        return
    end

    local events = {
        hs.eventtap.event.types.leftMouseDown,
        hs.eventtap.event.types.leftMouseDragged,
        hs.eventtap.event.types.leftMouseUp,
        hs.eventtap.event.types.rightMouseDown,
        hs.eventtap.event.types.rightMouseDragged,
        hs.eventtap.event.types.rightMouseUp,
        hs.eventtap.event.types.flagsChanged,
        hs.eventtap.event.types.keyDown,
    }

    self.eventtap = hs.eventtap.new(events, function(event)
        return self:_handleEvent(event)
    end)
    self.eventtap:start()
end

function SelectionWatcher:stop()
    if self.eventtap then
        self.eventtap:stop()
    end
    self.isDragging = false
    self.shiftSelecting = false
    self.shiftHeld = false
end

function SelectionWatcher:_handleEvent(event)
    local eventType = event:getType()
    local now = hs.timer.secondsSinceEpoch()

    if eventType == hs.eventtap.event.types.leftMouseDragged or eventType == hs.eventtap.event.types.rightMouseDragged then
        self.isDragging = true
        self.lastActivityAt = now
    elseif eventType == hs.eventtap.event.types.leftMouseUp or eventType == hs.eventtap.event.types.rightMouseUp then
        if self.isDragging then
            self.isDragging = false
            self.lastActivityAt = now
            self:_fire("mouse")
        elseif self.shiftSelecting and (now - self.lastActivityAt) <= self.activityWindow then
            self.shiftSelecting = false
            self:_fire("keyboard")
        else
            self.isDragging = false
            self.shiftSelecting = false
        end
    elseif eventType == hs.eventtap.event.types.flagsChanged then
        local flags = event:getFlags()
        local shiftNow = flags.shift == true
        if not shiftNow and self.shiftHeld and self.shiftSelecting and (now - self.lastActivityAt) <= self.activityWindow then
            self.shiftSelecting = false
            self:_fire("keyboard")
        end
        self.shiftHeld = shiftNow
        if not shiftNow then
            self.shiftSelecting = false
        end
    elseif eventType == hs.eventtap.event.types.keyDown then
        local keyCode = event:getKeyCode()
        if self.shiftHeld and arrowKeyCodes[keyCode] then
            self.shiftSelecting = true
            self.lastActivityAt = now
        end
    elseif eventType == hs.eventtap.event.types.leftMouseDown or eventType == hs.eventtap.event.types.rightMouseDown then
        self.isDragging = false
        self.shiftSelecting = false
    end

    return false
end

function SelectionWatcher:_fire(reason)
    if self.onSelection then
        self.onSelection({ reason = reason })
    end
end

-- ShortcutRunner: Shortcuts CLI 実行
function ShortcutRunner:new(opts)
    opts = opts or {}
    local obj = setmetatable({}, self)
    obj.shortcutName = opts.shortcutName or "テキストを日本語訳して表示"
    obj.log = opts.log
    return obj
end

function ShortcutRunner:setShortcutName(name)
    self.shortcutName = name
end

function ShortcutRunner:run(text, context)
    if not self.shortcutName or self.shortcutName == "" then
        if self.log then self.log:error("shortcutName が設定されていません") end
        return
    end

    if not hs.fs.attributes(SHORTCUTS_BIN) then
        if self.log then self.log:error("shortcuts CLI が見つかりません: " .. SHORTCUTS_BIN) end
        hs.notify.new({
            title = "選択ショートカット",
            informativeText = "shortcuts CLI が見つかりません",
        }):send()
        return
    end

    local script = buildPipeScript(self.shortcutName, text)
    local args = { "-c", script }
    local task = hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
        if exitCode ~= 0 then
            if self.log then
                self.log:error(string.format("Shortcuts failed (%d): %s", exitCode, stdErr or ""))
            end
            local message = (stdErr and #stdErr > 0) and stdErr or string.format("ショートカット実行に失敗しました (%d)", exitCode)
            hs.notify.new({
                title = "選択ショートカット",
                informativeText = message,
                hasActionButton = false
            }):send()
        else
            if self.log then
                local source = context and context.source or "unknown"
                local bytes = context and context.bytes or #text
                self.log:info(string.format("Shortcuts ok (%s, %d bytes)", source, bytes))
            end
        end
    end, args)

    if not task then
        if self.log then self.log:error("hs.task.new に失敗しました") end
        return
    end

    task:start()
end

-- ClassSelectionShortcutTrigger 本体
function ClassSelectionShortcutTrigger:new(opts)
    opts = opts or {}
    local self = setmetatable({}, ClassSelectionShortcutTrigger)

    self.log = logger.new("SelectionShortcut")
    self.menuManager = opts.menuManager or MenuManager:new()

    self.shortcutName = opts.shortcutName or hs.settings.get("selectionShortcut.shortcutName") or "SendSelection"
    self.cooldownSec = opts.cooldownSec or hs.settings.get("selectionShortcut.cooldownSec") or 2
    self.restoreClipboard = opts.restoreClipboard
    if self.restoreClipboard == nil then
        self.restoreClipboard = hs.settings.get("selectionShortcut.restoreClipboard")
        if self.restoreClipboard == nil then self.restoreClipboard = true end
    end
    self.preferAXSelection = opts.preferAXSelection
    if self.preferAXSelection == nil then
        local stored = hs.settings.get("selectionShortcut.preferAX")
        self.preferAXSelection = stored ~= false
    end
    self.copyDelayMicros = math.floor((opts.copyDelayMs or 150) * 1000)
    self.activityWindow = opts.activityWindow or 0.5

    self.selectionWatcher = SelectionWatcher:new({
        onSelection = function(meta) self:handleSelectionFinished(meta) end,
        activityWindow = self.activityWindow,
    })

    self.shortcutRunner = ShortcutRunner:new({
        shortcutName = self.shortcutName,
        log = self.log,
    })

    self.running = false
    self.lastSelectionText = nil
    self.lastTriggeredAt = 0
    self.accessibilityWarned = false

    self:stop({silent = true})

    return self
end

function ClassSelectionShortcutTrigger:start()
    if self.running then return end
    self.selectionWatcher:start()
    self.running = true
    hs.notify.new({title="選択ショートカット", informativeText="✅監視を開始しました。"}):send()
    self:updateMenu(true)
end

function ClassSelectionShortcutTrigger:stop(opts)
    opts = opts or {}
    if self.selectionWatcher then
        self.selectionWatcher:stop()
    end
    self.running = false
    if not opts.silent then
        hs.notify.new({title="選択ショートカット", informativeText="⛔️監視を停止しました。"}):send()
    end
    self:updateMenu(false)
end

function ClassSelectionShortcutTrigger:updateMenu(isRunning)
    if not self.menuManager then return end
    local toggleTitle = "選択ショートカット監視"
    local items = {
        {
            title = toggleTitle,
            checked = isRunning,
            fn = function()
                if self.running then
                    self:stop()
                else
                    self:start()
                end
            end
        },
        { title = string.format("ショートカット: %s", self.shortcutName), disabled = true }
    }
    self.menuManager:register("selection_shortcut", items)
end

function ClassSelectionShortcutTrigger:handleSelectionFinished(meta)
    if not self.running then return end

    local now = hs.timer.secondsSinceEpoch()
    if self.lastTriggeredAt > 0 and (now - self.lastTriggeredAt) < self.cooldownSec then
        if self.log then self.log:dev("cooldown中のためスキップ") end
        return
    end

    local text, source, err = self:fetchSelectionText({preferAX = self.preferAXSelection})
    if not text then
        if err and self.log then self.log:warn("文字列取得に失敗: " .. err) end
        return
    end

    if self.lastSelectionText and self.lastSelectionText == text and (now - self.lastTriggeredAt) < (self.cooldownSec * 2) then
        if self.log then self.log:dev("同一文字列の連続検出をスキップ") end
        return
    end

    local trimmed, truncated, byteLen = self:enforceShortcutLimit(text)
    if truncated then
        hs.notify.new({
            title = "選択ショートカット",
            informativeText = string.format("入力が長いため一部のみ送信します（%d bytes）", byteLen)
        }):send()
    end

    self.shortcutRunner:run(trimmed, {source = source, bytes = byteLen})
    self.lastSelectionText = text
    self.lastTriggeredAt = now
end

function ClassSelectionShortcutTrigger:fetchSelectionText(opts)
    opts = opts or {}
    local preferAX = opts.preferAX

    if preferAX then
        local text, err = self:getSelectionViaAX()
        if text then return text, "ax" end
        if err == "ax_permission" then
            self:notifyAccessibilityPermission()
        end
    end

    local textClipboard, errClipboard = self:getSelectionViaClipboard()
    if textClipboard then
        return textClipboard, "clipboard"
    end

    return nil, nil, errClipboard
end

function ClassSelectionShortcutTrigger:getSelectionViaAX()
    local frontApp = hs.application.frontmostApplication()
    if not frontApp then
        return nil, "no_front_app"
    end

    local ok, appElement = pcall(hs.axuielement.applicationElement, frontApp)
    if not ok or not appElement then
        return nil, "ax_permission"
    end

    local okFocused, focusedElement = pcall(function()
        return appElement:attributeValue("AXFocusedUIElement")
    end)
    if not okFocused or not focusedElement then
        return nil, "no_focus"
    end

    local okSelected, selectedText = pcall(function()
        return focusedElement:attributeValue("AXSelectedText")
    end)
    if not okSelected then
        return nil, "no_selected_text"
    end

    local normalized = self:normalizeText(selectedText)
    if not normalized or normalized == "" then
        return nil, "empty"
    end

    return normalized, nil
end

function ClassSelectionShortcutTrigger:getSelectionViaClipboard()
    local previousContents
    local hadPrevious = false

    if self.restoreClipboard then
        previousContents = hs.pasteboard.getContents()
        if previousContents then
            hadPrevious = true
        end
    end

    hs.eventtap.keyStroke({"cmd"}, "c", 0)
    hs.timer.usleep(self.copyDelayMicros)

    local contents = hs.pasteboard.getContents()

    if self.restoreClipboard then
        if hadPrevious then
            hs.pasteboard.setContents(previousContents)
        else
            hs.pasteboard.clearContents()
        end
    end

    local normalized = self:normalizeText(contents)
    if not normalized or normalized == "" then
        return nil, "clipboard_empty"
    end

    return normalized, nil
end

function ClassSelectionShortcutTrigger:normalizeText(text)
    if type(text) == "userdata" then
        local ok, converted = pcall(hs.styledtext.getString, text)
        if ok then
            text = converted
        end
    end

    if type(text) ~= "string" then return nil end

    local trimmed = text:gsub("^%s+", "")
    trimmed = trimmed:gsub("%s+$", "")
    if trimmed == "" then
        return nil
    end
    return trimmed
end

function ClassSelectionShortcutTrigger:enforceShortcutLimit(text)
    local byteLen = #text
    if byteLen <= SHORTCUT_BYTE_LIMIT then
        return text, false, byteLen
    end
    local half = math.floor(SHORTCUT_BYTE_LIMIT / 2) - 3
    if half < 1 then half = 1 end
    local prefix = text:sub(1, half)
    local suffix = text:sub(-half)
    local truncated = prefix .. "\n...\n" .. suffix
    return truncated, true, byteLen
end

function ClassSelectionShortcutTrigger:notifyAccessibilityPermission()
    if self.accessibilityWarned then return end
    self.accessibilityWarned = true

    local notification = hs.notify.new(function(notification)
        if notification:activationType() == hs.notify.activationTypes.actionButtonClicked then
            hs.execute([[open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"]], false)
        end
    end, {
        title = "選択ショートカット",
        informativeText = "アクセシビリティで Hammerspoon を許可してください",
        hasActionButton = true,
        actionButtonTitle = "設定を開く"
    })

    notification:send()
end

return ClassSelectionShortcutTrigger
