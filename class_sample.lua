local ClassSample = {}
ClassSample.__index = ClassSample

function ClassSample:new()
    -- 呼び出し元のLuaでpackage.pathがちゃんとしていれば問題なく呼べるらしい
    local appMenu = require("menu_manager"):new()

    appMenu:register("sample_app", {
        { title = "sample1", fn = function() hs.alert.show("sample!") end },
        { title = "sample2", fn = function() hs.alert.show("sample2!") end },
    })
end

return ClassSample