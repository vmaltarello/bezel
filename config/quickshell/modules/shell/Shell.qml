// Shell layout: vertical bar on the left, thin frame around the screen,
// panels that grow out of the screen edges with concave fillets.
// Always present: bar + frame (+ desktop widgets). Everything else exists only while open.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import "../lock"

Scope {
    id: root
    // panels show up on the focused monitor
    readonly property var focused: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    Variants {
        model: Quickshell.screens
        Scope {
            id: perScreen
            required property var modelData
            LazyLoader { active: Theme.size.hasFrame; Frame { screen: perScreen.modelData } }
            Bar { screen: perScreen.modelData }
            Desktop { screen: perScreen.modelData }
        }
    }

    LazyLoader { active: Ui.panel !== "" && Ui.panel !== "launcher" && Ui.panel !== "overview"; ClickCatcher { screen: root.focused } }
    // always alive (see Launcher.qml): no map/unmap, so no stale frame when it closes
    Launcher { screen: root.focused }
    LazyLoader { active: Ui.shown === "overview"; Overview { screen: root.focused } }
    // one panel for all bar menus: it moves between icons instead of disappearing and reappearing
    LazyLoader { active: Ui.sidePanels.includes(Ui.shown); SideHost { screen: root.focused } }
    LazyLoader { active: Events.loaded; Osd { screen: root.focused } }
    LazyLoader { active: Shot.active; Screenshot { screen: root.focused } }
    Lock {}
    // password prompt for apps asking admin rights (polkit agent)
    LazyLoader { active: Polkit.active; PolkitDialog { screen: root.focused } }
    LazyLoader { active: Notifs.loaded; Notifications { screen: root.focused } }
}
