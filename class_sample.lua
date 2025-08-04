local MenuManager = require("menu_manager")

local ClassSample = {}
ClassSample.__index = ClassSample

function ClassSample:new()
    -- インスタンス化のおまじない
    local self = setmetatable({}, ClassSample)

    self.AppMenu = MenuManager:new()

    self.AppMenu:register("sample_app", {
        { title = "sample1", fn = function() hs.alert.show("sample!") end },
        { title = "sample2", fn = function() hs.alert.show("sample2!") end },
    })

    return self
end

return ClassSample