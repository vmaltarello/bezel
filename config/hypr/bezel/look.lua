-- Look and feel: gaps, dimming, shadows, blur, animations, layouts, misc.
-- Window corners: tiled windows are square and the shell frame rounds the ones in the screen corners.
return function(o)
    hl.config({
        general = {
            gaps_in  = 4,    -- 8 px between two windows: same as the Quickshell frame thickness
            gaps_out = 0,    -- windows reach the frame: its rounded corners round the outer window corners

            border_size = 0,   -- no border: the frame's rounded corners would cut it

            -- resize windows by dragging borders and gaps
            resize_on_border = true,

            -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
            allow_tearing = false,

            layout = "dwindle",
        },

        decoration = {
            rounding = 0,   -- tiled windows are square; the corners that sit in the frame corners are rounded by the
                            -- (solid) Quickshell frame fillets, so only corners touching the frame corners look rounded,
                            -- whatever the number of windows. Floating windows: see "floating-rounded" below.
            rounding_power = 2,  -- plain circular arc (no squircle needed with such a small radius)

            active_opacity   = 1.0,
            inactive_opacity = 1.0,
            dim_inactive     = true,
            dim_strength     = 0.28,   -- the focused window is the one that is not dimmed (no borders, no glow)
            dim_special      = 0.45,   -- scratchpad (SUPER+S): dimmed background, focus on the popup

            -- short, sharp shadow to lift windows off the wallpaper
            shadow = {
                enabled      = true,
                range        = 14,
                render_power = 3,
                offset       = "0 4",
                color        = "rgba(0b0d12aa)",
                color_inactive = "rgba(0b0d1266)",
            },

            -- faint amber glow around the focused window (off)
            glow = {
                enabled        = false,   -- the focused window is the one not dimmed
                range          = 12,
                render_power   = 3,
                color          = "rgba(e6b4502a)",
                color_inactive = "rgba(00000000)",
            },

            -- light blur: only where there is transparency (kitty).
            -- 1 pass halves the GPU cost of every terminal redraw; a bigger size keeps a similar look
            -- (size only spreads the samples, it costs nothing)
            blur = {
                enabled  = true,
                size     = 9,
                passes   = 1,
                noise    = 0.02,
                contrast = 1.1,
                vibrancy = 0.2,
                popups   = false,   -- popups/menus are opaque: nothing to blur
            },
        },

        animations = {
            enabled = true,
        },
    })

    -- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
    hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
    hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
    hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
    hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
    hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

    -- Default springs
    hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

    hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
    hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
    hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
    hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 95%" })
    hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 95%" })
    hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
    hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
    hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
    hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
    hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "popin 92%" })
    hl.animation({ leaf = "layersOut",     enabled = false,  speed = 1.5,  bezier = "linear",       style = "fade" })
    hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
    hl.animation({ leaf = "fadeLayersOut", enabled = false,  speed = 1.39, bezier = "almostLinear" })
    hl.animation({ leaf = "workspaces",    enabled = true,  speed = 3.5,  bezier = "easeOutQuint", style = "slidefade 15%" })
    hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 3.5,  bezier = "easeOutQuint", style = "slidefade 15%" })
    hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 3.5,  bezier = "easeOutQuint", style = "slidefade 15%" })
    hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3,  bezier = "easeOutQuint", style = "slidevert" })
    hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })



    -- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
    hl.config({
        dwindle = {
            preserve_split = true, -- You probably want this
        },
    })

    -- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
    hl.config({
        master = {
            new_status = "master",
        },
    })

    -- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
    hl.config({
        scrolling = {
            fullscreen_on_one_column = true,
        },
    })

    -- misc

    hl.config({
        misc = {
            force_default_wallpaper = 0,     -- no default wallpaper: awww draws it
            disable_hyprland_logo   = true,  -- don't load the logo/textures
            disable_splash_rendering = true, -- no joke subtitles on the background
            focus_on_activate       = true,  -- links clicked elsewhere bring the browser to the front
            -- swallowing: `imv photo.png` / `mpv video` from a terminal (or yazi) takes the terminal's place
            enable_swallow          = true,
            swallow_regex           = "^(kitty|yazi)$",
            -- if the lock screen crashes, another one can be started (from a TTY:
            -- hyprctl --instance 0 dispatch exec hyprlock) instead of being stuck
            allow_session_lock_restore = true,
        },
        -- XWayland apps at native resolution (no blurry upscale at 1.5):
        -- they scale themselves (e.g. JetBrains IDEs with -Dide.ui.scale)
        -- no "Hyprland updated" window after upgrades (release notes: github.com/hyprwm/Hyprland/releases)
        ecosystem = {
            no_update_news = true,
        },
        xwayland = {
            force_zero_scaling = true,
        },
    })
end
