local Utils = {}

--- 指定されたモジュールを安全にロードする
-- @param module_name string モジュール名
-- @return table | nil ロードされたモジュール、またはエラー時にnil
function Utils.safe_require(module_name)
    local ok, module = pcall(require, module_name)
    if not ok then
        local msg = "Error loading module: " .. module_name .. "\n" .. tostring(module)
        print(msg)
        hs.alert.show(msg)
        return nil
    end
    return module
end

--- 指定されたモジュールを安全にロードして初期化する
-- @param module_name string モジュール名
function Utils.safe_init(module_name)
    local module = Utils.safe_require(module_name)
    if not module then return end

    -- モジュールにnewメソッドがあるか確認してから呼び出す
    if module and type(module.new) == "function" then
        local ok_init, instance = pcall(function() return module:new() end)
        if not ok_init then
            local msg = "Error initializing module: " .. module_name .. "\n" .. tostring(instance)
            print(msg)
            hs.alert.show(msg)
            return
        end
    end
end

--- pcallをラップして関数を安全に呼び出す
-- @param func function 呼び出す関数
-- @param ... any 関数に渡す引数
-- @return boolean, ... 成功ステータスと、関数の返り値またはエラーメッセージ
function Utils.safe_call(func, ...)
    if type(func) ~= "function" then
        return false, "first argument must be a function"
    end
    return pcall(func, ...)
end

return Utils
