-- ファイルの監視を実施する
function triggerTailscale(hs)
    -- iCloudの特定のフォルダを監視する
    local dirpath = os.getenv("HOME") .. "/Library/Mobile Documents/com~apple~CloudDocs/TriggerTailscale"

    -- ファイル監視
    local watcher = hs.pathwatcher.new(dirpath, function(paths, flagTables)
        for index, path in ipairs(paths) do
            local file_name = path:match("([^/]+)$") -- フルパスからファイル名を取得
            local event_flags = flagTables[index]

            print("----- DEBUG -----")
            print("file_name = " .. file_name)
            print("event_flags = " .. hs.inspect(event_flags))
            print("----- DEBUG -----")

            -- ファイルのイベントを確認（ファイル作成、もしくはiCloud経由でファイル作成（リネーム、改変））
            if event_flags.itemCreated or (event_flags.itemRenamed and event_flags.itemModified) then
            else
                goto continue
            end

            -- on.txtかつファイル作成イベントの場合
            if file_name == "on.txt" then
                hs.notify.new({title="Tailscale トリガー", informativeText="on.txt を検知しました。tailscaled を起動します。"}):send()
                print("Change: on.txt detected")
                local output, status, typ, rc = hs.execute("screen -dmS tailscale_session tailscale up", true)
                print("commad output = " .. output)
                print("commad status = " .. hs.inspect(status))
                os.remove(path) -- 処理後にファイルを削除（フルパスの方を指定すること）
            end

            -- off.txtかつファイル作成イベントの場合
            if file_name == "off.txt" then
                hs.notify.new({title="Tailscale トリガー", informativeText="off.txt を検知しました。tailscaled を停止します。"}):send()
                print("Change: off.txt detected")
                local output, status, typ, rc = hs.execute("tailscale down", true)
                print("commad output = " .. output)
                print("commad status = " .. hs.inspect(status))
                os.remove(path) -- 処理後にファイルを削除（フルパスの方を指定すること）
            end

            ::continue::
        end
    end)
    watcher:start()
end