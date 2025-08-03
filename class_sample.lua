local ClassSample = {}
ClassSample.__index = ClassSample

function ClassSample:new()
    -- 呼び出し元のLuaでpackage.pathがちゃんとしていれば問題なく呼べるらしい
    local appMenu = require("menu_manager"):new()

    appMenu:register("sample_app", {
        { title = "sample!", fn = function() hs.alert.show("sample!") end }
    })
end

return ClassSample