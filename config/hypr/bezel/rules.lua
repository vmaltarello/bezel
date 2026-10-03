-- Window and layer rules.
return function(o)
    hl.window_rule({
        -- Ignore maximize requests from all apps. You'll probably like this.
        name  = "suppress-maximize-events",
        match = { class = ".*" },

        suppress_event = "maximize",
    })

    -- floating windows don't touch the frame: they keep their own rounded corners
    hl.window_rule({
        name     = "floating-rounded",
        match    = { float = true },
        rounding = 12,
    })

    hl.window_rule({
        name      = "single-window-plain",
        match     = { workspace = "w[tv1]" },
        no_shadow = true,   -- a single tiled window needs no shadow; only the shadow: decorate = false would also drop the rounded corners
    })

    hl.window_rule({
        -- Fix some dragging issues with XWayland
        name  = "fix-xwayland-drags",
        match = {
            class      = "^$",
            title      = "^$",
            xwayland   = true,
            float      = true,
            fullscreen = false,
            pin        = false,
        },

        no_focus = true,
    })

    -- Hyprland-run windowrule
    hl.window_rule({
        name  = "move-hyprland-run",
        match = { class = "hyprland-run" },

        move  = "20 monitor_h-120",
        float = true,
    })

    -- Quickshell layers: the shell animates them itself
    hl.layer_rule({ name = "quickshell-noanim", match = { namespace = "^quickshell" }, no_anim = true })

    -- utility windows (btop, nmtui, mixer...): floating, centered, fixed size
    hl.window_rule({
        name   = "utility-float",
        match  = { class = "^(kitty-float|nm-connection-editor|hyprpolkitagent|hyprpwcenter)$" },
        float  = true,
        center = true,
        size   = "1100 720",
    })

    -- focus mode (SUPER+Z): everything else is dimmed behind the front window
    hl.window_rule({
        name       = "focus-mode",
        match      = { tag = "focusmode" },
        dim_around = true,
    })

    -- screenshot editor (satty): floating and centered, doesn't break the layout
    hl.window_rule({
        name   = "satty-float",
        match  = { class = "^com.gabm.satty$" },
        float  = true,
        center = true,
        size   = "monitor_w*0.8 monitor_h*0.8",
    })
end
