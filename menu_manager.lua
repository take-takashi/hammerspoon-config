local MenuManager = {}
MenuManager.__index = MenuManager
MenuManager._instance = nil  -- インスタンスの保持場所（シングルトン用）

--- MenuManagerクラスの生成（シングルトン的に使う）
-- @param icon styledtext（オプション）menubar に表示するアイコン
function MenuManager:new(icon)
    -- 初期化は一回のみ行う
    if MenuManager._instance then return MenuManager._instance end

    local obj = setmetatable({}, MenuManager)

    -- iconが指定されてなければデフォルトのiconを設定
    local menuIcon = icon or hs.styledtext.new("\u{F040}", {
        color = { red=1, green=1, blue=1 },
        font = { name = "Webdings", size = 16 }
    })

    obj.menu = hs.menubar.new()
    obj.menu:setTitle(menuIcon)

    -- 各モジュールから登録されたメニュー項目を保持する
    -- key = 登録者(owner), value = 項目のtable
    obj.sources = {}
    -- メニューの順序を担保するために、ownerの登録順を保持する
    obj.owners = {}

    MenuManager._instance = obj
    return obj
end

--- 指定されたownerのメニュー項目を登録（または上書き）し、メニューを再描画する
-- @param owner string 登録者の識別子 (例: "clipboard_watcher", "sample_app")
-- @param items table メニュー項目のテーブル
function MenuManager:register(owner, items)
    if not owner or owner == "" then
        hs.alert.show("MenuManager: owner is required for registration.")
        return
    end

    -- 初めて登録されるownerの場合は、順序リストの末尾に追加
    if not self.sources[owner] then
        table.insert(self.owners, owner)
    end

    self.sources[owner] = items
    self:update()
end

--- 登録されているすべての項目からメニューを再構築する
function MenuManager:update()
    local allItems = {}
    -- 登録順（self.owners）に従ってメニュー項目を構築する
    for _, owner in ipairs(self.owners) do
        local items = self.sources[owner]
        if items and #items > 0 then
            for _, item in ipairs(items) do
                table.insert(allItems, item)
            end
            -- モジュールごとに区切り線を入れると分かりやすい
            table.insert(allItems, { title = "-" })
        end
    end

    -- 最後の区切り線は不要なので削除
    if #allItems > 0 and allItems[#allItems].title == "-" then
        table.remove(allItems)
    end

    self.menu:setMenu(allItems)
end

return MenuManager
