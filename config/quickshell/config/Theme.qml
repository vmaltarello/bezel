pragma Singleton
// Theme: the single place for colors, fonts, sizes and animations.
// To change the look, change this file.
import QtQuick
import Quickshell

Singleton {
    // ---- colors: "Vetta" palette (night blue, lavender, snow-sand). Old names kept so every module follows ----
    readonly property QtObject c: QtObject {
        readonly property color ink:    Qt.rgba(15 / 255, 22 / 255, 40 / 255, 0.88) // translucent surface
        readonly property color pill:   Qt.rgba(42 / 255, 55 / 255, 86 / 255, 0.70) // inner pills
        readonly property color ink0:   "#0a0f1c"   // deepest
        readonly property color ink1:   "#18223a"   // hover on surface
        readonly property color ink4:   "#2a3756"   // tracks, borders, selected rows
        readonly property color ink5:   "#34436a"   // selection / hover on containers
        readonly property color fg:     "#f4f2ec"
        readonly property color fg2:    "#c4c7d1"
        readonly property color muted:  "#8b91a3"
        readonly property color dim:    "#4a5675"
        readonly property color blue:   "#a99cf0"   // was the primary: now the lavender accent
        readonly property color violet: "#f0d9b5"   // old name: the second tone, snow-sand
        readonly property color aqua:   "#f0d9b5"   // old name: snow-sand
        readonly property color warm:   "#a99cf0"   // lavender accent
        readonly property color green:  "#9bd48a"   // success, same green as GTK, kitty and yazi
        readonly property color orange: "#ffb46b"
        readonly property color red:    "#ff5a5f"
        readonly property color frame:  "#0f1628"   // frame, bar and panels: one solid color, they read as one piece
        readonly property color panel:  "#0f1628"
        readonly property color cell:   "#18223a"   // cards inside panels
        readonly property color shade:  "#05080f"   // screen dim behind overlays
    }

    // ---- "Vetta" palette (role names from Material 3) ----
    readonly property QtObject m: QtObject {
        readonly property color surface:      "#0f1628"   // frame, bar and panels
        readonly property color container:    "#18223a"   // groups inside the bar, cards
        readonly property color containerHigh: "#202c48"  // hover
        readonly property color containerHighest: "#2a3756"
        readonly property color fg:    "#f4f2ec"
        readonly property color fgVariant: "#c4c7d1"
        readonly property color outline:      "#8b91a3"
        readonly property color outlineVariant: "#2a3756"
        readonly property color primary:      "#a99cf0"   // lavender: active workspace, clock, selection
        readonly property color fgPrimary:    "#160f33"
        readonly property color primaryContainer: "#29244d"
        readonly property color fgPrimaryContainer: "#d2cbfb"
        // selected rows (lists, launcher): tonal, not solid. The solid accent is for small marks only
        readonly property color selection:    primaryContainer
        readonly property color fgSelection:  fg
        readonly property color secondaryContainer: "#2a3756" // open menu, toggles on
        readonly property color fgSecondaryContainer: "#f4f2ec"
        readonly property color tertiary:     "#f0d9b5"   // the second tone, snow-sand: secondary readings, battery ok
        readonly property color error:        "#ff5a5f"
        readonly property color success:      "#9bd48a"
        readonly property color warning:      "#ffb46b"
        readonly property color barGroup:     container   // tonal groups inside the bar
        // bar, frame and the panels attached to them: solid and darker than the windows (monitor-bezel look).
        // Not translucent: a thin frame and a wide bar over different parts of the wallpaper never match.
        readonly property color barGlass:     "#0f1628"
        readonly property color glass:        Qt.rgba(15 / 255, 22 / 255, 40 / 255, 0.6) // desktop widgets: surface you can see through
    }

    // ---- fonts ----
    readonly property QtObject font: QtObject {
        readonly property string family: "IBM Plex Sans"             // the interface: technical but warm, pairs with JetBrains Mono
        readonly property string mono: "JetBrainsMono Nerd Font"     // only digits that change (clocks, percentages): they don't jump
        readonly property string heavy: "Inter Display"              // big heavy numbers (weight Black)
        readonly property string icons: "JetBrainsMono Nerd Font Propo"
        readonly property string symbols: "Material Symbols Rounded" // icons by ligature name, FILL axis = state
        readonly property int small:  13
        readonly property int normal: 15
        readonly property int large:  17
    }

    // ---- sizes ----
    readonly property QtObject size: QtObject {
        readonly property int barHeight: 36
        readonly property int barMargin: 8      // distance from the screen edge
        readonly property int sideMargin: 10
        readonly property int radius: 12        // groups
        readonly property int cut: 9            // the 45° cut on the top-left corner: bezel's signature
        readonly property int pillHeight: 24
        readonly property int spacing: 6
        readonly property int frame: 8          // frame thickness top/right/bottom (0 = no frame; keep it even: scale 1.5)
        readonly property bool hasFrame: frame > 0
        readonly property int frameRadius: 12   // inner frame corners (they round the outer window corners)
        readonly property int barWidth: 52      // vertical bar on the left (even)
        readonly property int fillet: 12        // concave fillets of panels coming out of the edges (even)
        readonly property int islandHeight: 26
        // edge panels
        readonly property int sheetWidth: 1120
        readonly property int topHeight: 150     // same as the bottom one: symmetric panels
        readonly property int bottomHeight: 150
        readonly property int sheetPad: 14
        readonly property int sheetGap: 10
        readonly property int sheetRadius: 22
        readonly property int cellRadius: 12
        readonly property int eventHeight: 38
        // width of n columns of the 12-column grid (same top and bottom: cells line up)
        function span(n) {
            const col = (sheetWidth - 2 * sheetPad - 11 * sheetGap) / 12;
            return n * col + (n - 1) * sheetGap;
        }
    }

    // ---- animations ----
    readonly property QtObject anim: QtObject {
        readonly property int fast: 150
        readonly property int normal: 250
        readonly property int slow: 450
    }
}
