-- Keybindings. Every bind has a description: SUPER+H lists them in the launcher (Keys mode).
return function(o)
    local mainMod = "SUPER" -- Sets "Windows" key as main modifier

    local function bind(keys, action, desc, opts)
        opts = opts or {}
        opts.description = desc
        return hl.bind(keys, action, opts)
    end

    -- Apps and session
    bind(mainMod .. " + T", hl.dsp.exec_cmd(o.terminal),    "Terminal")
    bind(mainMod .. " + E", hl.dsp.exec_cmd(o.fileManager), "File manager")
    bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("quickshell ipc call shell launcher apps"),    "App launcher")
    -- SUPER pressed and released alone = peek at the desktop (SUPER+key combos are unaffected)
    bind("SUPER + SUPER_L", hl.dsp.exec_cmd("quickshell ipc call shell toggle"), "Peek at desktop (SUPER alone)", { release = true })
    bind(mainMod .. " + B", hl.dsp.exec_cmd(o.browser or "gtk-launch \"$(xdg-settings get default-web-browser)\""), "Browser")
    bind(mainMod .. " + TAB", hl.dsp.exec_cmd("quickshell ipc call shell overview toggle"), "Workspace overview")
    bind(mainMod .. " + H", hl.dsp.exec_cmd("quickshell ipc call shell launcher keys"), "Show this shortcut list")
    bind(mainMod .. " + C", hl.dsp.exec_cmd("quickshell ipc call shell search ="), "Calculator")
    bind(mainMod .. " + V", hl.dsp.exec_cmd("quickshell ipc call shell launcher clipboard"), "Clipboard history")
    bind(mainMod .. " + N", hl.dsp.exec_cmd("quickshell ipc call shell dnd"), "Toggle do not disturb")
    bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"), "Lock screen")
    bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"), "Exit Hyprland")

    -- Windows
    bind(mainMod .. " + Q", hl.dsp.window.close(), "Close window")
    bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")

    -- Focus mode (SUPER+Z): the active window floats, becomes 80%×90% of the screen,
    -- moves to the center and the rest is dimmed ("focus-mode" rule in rules.lua). Press again: back as it was.
    local focusWasFloating = {}   -- address -> was it already floating before focus mode?
    local function hasTag(w, tag)
        local t = w.tags
        if type(t) == "string" then return t:find(tag, 1, true) ~= nil end
        for _, v in ipairs(t or {}) do if v == tag then return true end end
        return false
    end
    local function focusMode()
        local w = hl.get_active_window()
        if not w then return end
        local sel = "address:" .. w.address
        if hasTag(w, "focusmode") then
            hl.dispatch(hl.dsp.window.tag({ tag = "-focusmode", window = sel }))
            if not focusWasFloating[w.address] then
                hl.dispatch(hl.dsp.window.float({ action = "disable", window = sel }))
            end
            focusWasFloating[w.address] = nil
            return
        end
        focusWasFloating[w.address] = w.floating
        local m = hl.get_active_monitor()
        local mw, mh = m.width / m.scale, m.height / m.scale
        hl.dispatch(hl.dsp.window.float({ action = "enable", window = sel }))
        hl.dispatch(hl.dsp.window.tag({ tag = "+focusmode", window = sel }))
        hl.dispatch(hl.dsp.window.resize({ x = math.floor(mw * 0.80), y = math.floor(mh * 0.90), window = sel }))
        hl.dispatch(hl.dsp.window.center({ window = sel }))
    end
    bind(mainMod .. " + Z", focusMode, "Toggle focus mode (large centered window)")
    bind(mainMod .. " + P", hl.dsp.window.pseudo(), "Pseudo-tiling")
    bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), "Toggle split direction")    -- dwindle only
    bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }), "Maximize (bar visible)")
    bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Fullscreen")

    -- Resize the active window with mainMod + CTRL + arrow keys
    bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -50, y = 0,   relative = true }), "Resize window", { repeating = true })
    bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 50,  y = 0,   relative = true }), "Resize window", { repeating = true })
    bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), "Resize window", { repeating = true })
    bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), "Resize window", { repeating = true })

    -- Move focus with mainMod + arrow keys
    bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }),  "Move focus")
    bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), "Move focus")
    bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }),    "Move focus")
    bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }),  "Move focus")

    -- Move the active window in a direction (swaps with its neighbour)
    bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }),  "Move window")
    bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }), "Move window")
    bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }),    "Move window")
    bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }),  "Move window")

    -- persistent workspaces (shown even when empty): SUPER + [1-n] go, SUPER + SHIFT + [1-n] move window
    -- (Quickshell: Config.persistentWorkspaces, keep them equal)
    for i = 1, o.workspaces do
        hl.workspace_rule({ workspace = tostring(i), persistent = true })
        bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }),       "Go to workspace")
        bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }), "Move window to workspace")
    end

    -- Special workspace (scratchpad)
    bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"),              "Toggle scratchpad")
    bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), "Move window to scratchpad")
    -- empty scratchpad? SUPER+S opens a drop-down terminal (own class, not the shared instance)
    hl.workspace_rule({ workspace = "special:magic", on_created_empty = "kitty -1 --class kitty-scratch" })

    -- Scroll through existing workspaces with mainMod + scroll
    bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Next/previous workspace")
    bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), "Next/previous workspace")

    -- Move/resize windows with mainMod + LMB/RMB and dragging
    bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   "Drag window",    { mouse = true })
    bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), "Resize with mouse", { mouse = true })

    -- Wallpaper (scripts/wallpaper.sh, awww): circle growing from the cursor
    bind(mainMod .. " + W",         hl.dsp.exec_cmd("quickshell ipc call shell launcher wallpapers"), "Choose wallpaper")
    bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper.sh next"), "Next wallpaper")

    -- Screenshot (Quickshell): freezes the screen, then area / window / full screen -> clipboard + ~/Pictures/Screenshots
    bind("Print",                  hl.dsp.exec_cmd("quickshell ipc call shell screenshot"), "Screenshot")
    bind(mainMod .. " + ALT + S",  hl.dsp.exec_cmd("quickshell ipc call shell screenshot"), "Screenshot")

    -- Laptop multimedia keys for volume and LCD brightness
    bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/osd.sh vol-up"), "Volume", { locked = true, repeating = true })
    bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/osd.sh vol-down"),      "Volume", { locked = true, repeating = true })
    bind("XF86AudioMute",        hl.dsp.exec_cmd("~/.config/hypr/scripts/osd.sh vol-mute"),     "Mute", { locked = true })
    bind("XF86AudioMicMute",     hl.dsp.exec_cmd("~/.config/hypr/scripts/osd.sh mic-mute"),   "Mute microphone", { locked = true })
    bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("~/.config/hypr/scripts/osd.sh br-up"),                  "Brightness", { locked = true, repeating = true })
    bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("~/.config/hypr/scripts/osd.sh br-down"),                  "Brightness", { locked = true, repeating = true })

    -- Media keys: handled by Quickshell (quickshell ipc call shell media next|prev|toggle)
    bind("XF86AudioNext",  hl.dsp.exec_cmd("quickshell ipc call shell media next"),       "Next track", { locked = true })
    bind("XF86AudioPause", hl.dsp.exec_cmd("quickshell ipc call shell media toggle"), "Play/pause", { locked = true })
    bind("XF86AudioPlay",  hl.dsp.exec_cmd("quickshell ipc call shell media toggle"), "Play/pause", { locked = true })
    bind("XF86AudioPrev",  hl.dsp.exec_cmd("quickshell ipc call shell media prev"),   "Previous track", { locked = true })
end
