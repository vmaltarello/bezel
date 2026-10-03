-- Environment: cursor, Qt theme, editor.
return function(o)
    hl.env("XCURSOR_THEME", "capitaine-cursors-light")
    hl.env("XCURSOR_SIZE", "32")
    hl.env("HYPRCURSOR_THEME", "capitaine-cursors-light")
    hl.env("HYPRCURSOR_SIZE", "32")

    -- Qt apps (hyprpolkitagent, hyprpwcenter…): qt6ct + Kvantum
    hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
    hl.env("QT_STYLE_OVERRIDE", "kvantum")

    -- editor for apps launched by Hyprland (yazi, git…): shells set it only inside terminals
    if o.editor then
        hl.env("EDITOR", o.editor)
        hl.env("VISUAL", o.editor)
    end
end
