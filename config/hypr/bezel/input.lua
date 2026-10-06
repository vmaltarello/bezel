-- Input: touchpad behaviour and gestures. The keyboard layout is set in your hyprland.lua.
return function(o)
    hl.config({
        input = {
            follow_mouse = 1,
            touchpad = { natural_scroll = true },
        },
    })

    hl.gesture({
        fingers = 3,
        direction = "horizontal",
        action = "workspace"
    })
    -- long swipe = skip several workspaces
    -- swiping doesn't create workspaces beyond 5
    hl.config({ gestures = { workspace_swipe_forever = true, workspace_swipe_create_new = false } })
    -- 3 fingers up/down: Mission Control style overview (Quickshell)
    hl.gesture({ fingers = 3, direction = "up",   action = function() hl.exec_cmd("quickshell ipc call shell overview open") end })
    hl.gesture({ fingers = 3, direction = "down", action = function() hl.exec_cmd("quickshell ipc call shell overview close") end })
    -- SUPER + pinch: zoom at the cursor (without SUPER the pinch goes to the app, e.g. the browser)
    hl.gesture({ fingers = 2, direction = "pinch", mods = "SUPER", action = "cursor_zoom", zoom_level = 1, mode = "live" })
end
