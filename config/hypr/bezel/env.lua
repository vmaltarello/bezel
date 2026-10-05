-- Environment: cursor, Qt theme, accessibility bus, editor.
return function(o)
    hl.env("XCURSOR_THEME", "capitaine-cursors-light")
    hl.env("XCURSOR_SIZE", "32")
    hl.env("HYPRCURSOR_THEME", "capitaine-cursors-light")
    hl.env("HYPRCURSOR_SIZE", "32")

    -- Qt apps (hyprpwcenter, Dolphin…): qt6ct + Kvantum
    hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
    hl.env("QT_STYLE_OVERRIDE", "kvantum")

    -- no accessibility bus (at-spi, ~15 MB in 3 processes): GTK 4 and GTK 3 apps don't start it.
    -- Remove these two lines if you use a screen reader.
    -- `true` exports them to systemd/D-Bus too: portals are activated there and would start at-spi otherwise.
    hl.env("GTK_A11Y", "none", true)
    hl.env("NO_AT_BRIDGE", "1", true)

    -- editor for apps launched by Hyprland (yazi, git…): shells set it only inside terminals
    if o.editor then
        hl.env("EDITOR", o.editor)
        hl.env("VISUAL", o.editor)
    end
end
