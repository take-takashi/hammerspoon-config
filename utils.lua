local Utils = {}

--- 指定されたモジュールを安全にロードして初期化する
-- @param module_name string モジュール名
function Utils.safe_init(module_name)
    local ok, module = pcall(require, module_name)
    if not ok then
        local msg = "Error loading module: " .. module_name .. "\n" .. tostring(module)
        print(msg)
        hs.alert.show(msg)
        return
    end

    -- モジュールにnewメソッドがあるか確認してから呼び出す
    if module and type(module.new) == "function" then
        local ok_init, instance = pcall(function() return module:new() end)
        if not not_init then
            local msg = "Error initializing module: " .. module_name .. "\n" .. tostring(instance)
            print(msg)
            hs.alert.show(msg)
            return
        end
    end
end

return Utils
