-- Processes started with the session.
return function(o)
    hl.on("hyprland.start", function()
        hl.exec_cmd("quickshell")    -- desktop shell: bar, frame, panels, lock screen (~/.config/quickshell)
        -- wallpaper: awww restores the last one; on the first login pick a default
        hl.exec_cmd("awww-daemon")
        hl.exec_cmd(o.scripts .. "/wallpaper.sh init")
        hl.exec_cmd("hypridle")
        -- clipboard history: text and images (cliphist, ~2 MB of RAM)
        hl.exec_cmd("wl-paste --type text --watch cliphist -max-items 200 store")
        hl.exec_cmd("wl-paste --type image --watch cliphist -max-items 200 store")
    end)
end
