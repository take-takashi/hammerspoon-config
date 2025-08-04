local MenuManager = require("menu_manager")

local ClassSample = {}
ClassSample.__index = ClassSample

function ClassSample:new()
    -- インスタンス化のおまじない
    local self = setmetatable({}, ClassSample)

    self.AppMenu = MenuManager:new()

    self.AppMenu:register("sample_app", {
        { title = "ロードモジュール確認", fn = function() self:showLoadedModules() end },
        { title = "sample", fn = function() hs.alert.show("sample!") end },
    })

    return self
end

function ClassSample:showLoadedModules()
    print("----- loaded modules begin -----")
    for k, v in pairs(hs) do
        if type(v) == "table" then
            print(k)
        end
    end
    print("----- loaded modules end -----")
end

return ClassSample