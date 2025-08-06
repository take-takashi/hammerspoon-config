-- KeyVisualizer
-- hs.eventtapでキーボード入力を監視し、hs.canvasで画面に表示する
local KeyVisualizer = {
    name = "KeyVisualizer",
    version = "0.1",
    author = "Your Name",
    license = "MIT - https://opensource.org/licenses/MIT"
}
KeyVisualizer.__index = KeyVisualizer

-- logger
local logger = require("logger")
local log = logger.new(KeyVisualizer.name)

-- private
local canvas
local eventtap
local display_timer

--- コンストラクタ
function KeyVisualizer:new()
    local obj = setmetatable({}, self)
    obj:init()
    return obj
end

--- 初期化
function KeyVisualizer:init()
    log:d("init")
    self:initCanvas()
    self:initEventTap()
end

--- hs.canvasの初期化
function KeyVisualizer:initCanvas()
    log:d("initCanvas")
    local mainScreen = hs.screen.mainScreen()
    local screenGeom = mainScreen:fullFrame()
    canvas = hs.canvas.new(screenGeom)
    canvas:level(hs.canvas.windowLevels.floating)
end

--- hs.eventtapの初期化
function KeyVisualizer:initEventTap()
    log:d("initEventTap")
    eventtap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
        local chars = e:getCharacters()
        log:d("keyDown: " .. chars)
        self:showKey(chars)
    end)
    eventtap:start()
end

--- キー表示を更新
function KeyVisualizer:showKey(key)
    canvas:deleteElements()

    local mainScreen = hs.screen.mainScreen()
    local screenGeom = mainScreen:fullFrame()
    local w = 200
    local h = 200
    local x = (screenGeom.w - w) / 2
    local y = (screenGeom.h - h) / 2

    canvas:appendElements({
        type = "text",
        text = key,
        textColor = {white = 1, alpha = 1},
        textSize = 100,
        frame = {x = x, y = y, w = w, h = h},
        textAlignment = "center",
    })

    canvas:show()

    -- 既存のタイマーがあればキャンセル
    if display_timer then
        display_timer:stop()
    end

    -- 1秒後に非表示にする
    display_timer = hs.timer.doAfter(1, function()
        canvas:hide()
    end)
end

return KeyVisualizer
