-- Minimal Hyprland for the login screen ("greeter" user), started by greetd:
--   command = "start-hyprland -- -c /etc/quickshell-greeter/hyprland.lua"
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1.5,
})

hl.env("XCURSOR_THEME", "capitaine-cursors-light")
hl.env("XCURSOR_SIZE", "24")
-- the greeter user has no writable home: Quickshell cache and state go to /tmp
hl.env("XDG_CACHE_HOME", "/tmp/quickshell-greeter")
hl.env("XDG_STATE_HOME", "/tmp/quickshell-greeter")
hl.env("XDG_DATA_HOME", "/tmp/quickshell-greeter")

hl.config({
    input = {
        kb_layout          = "it",
        numlock_by_default = true,
    },
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },
    animations = {
        enabled = false,
    },
})

-- after login Quickshell exits and the greeter must quit
hl.on("hyprland.start", function ()
    hl.exec_cmd("sh -c \"quickshell -p /etc/quickshell-greeter; hyprctl dispatch 'hl.dsp.exit()'; pkill -u greeter -x Hyprland\"")
end)
