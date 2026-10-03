pragma Singleton
// Theme: the single place for colors, fonts, sizes and animations.
// To change the look, change this file.
import QtQuick
import Quickshell

Singleton {
    // ---- colors: "Developer" palette. Old names kept so every module follows; values = the m palette below ----
    readonly property QtObject c: QtObject {
        readonly property color ink:    Qt.rgba(15 / 255, 20 / 255, 22 / 255, 0.88) // translucent surface
        readonly property color pill:   Qt.rgba(35 / 255, 44 / 255, 46 / 255, 0.70) // inner pills
        readonly property color ink0:   "#0b1012"   // deepest
        readonly property color ink1:   "#151c1e"   // hover on surface
        readonly property color ink4:   "#2e3739"   // tracks, borders, selected rows
        readonly property color ink5:   "#3a4446"   // selection / hover on containers
        readonly property color fg:     "#dfe4e5"
        readonly property color fg2:    "#b9c3c5"
        readonly property color muted:  "#899395"
        readonly property color dim:    "#4f5a5c"
        readonly property color blue:   "#e6b450"   // was the primary: now the amber accent
        readonly property color violet: "#9fd3dc"   // secondary: cyan
        readonly property color aqua:   "#95e6cb"
        readonly property color warm:   "#e6b450"   // amber accent
        readonly property color green:  "#9ece6a"
        readonly property color orange: "#ff9e64"
        readonly property color red:    "#f07178"
        readonly property color frame:  "#0f1416"   // frame, bar and panels: one solid color, they read as one piece
        readonly property color panel:  "#0f1416"
        readonly property color cell:   "#1a2224"   // cards inside panels
        readonly property color shade:  "#05080a"   // screen dim behind overlays
    }

    // ---- "Developer" palette (role names from Material 3; hand-made, independent of the wallpaper) ----
    readonly property QtObject m: QtObject {
        readonly property color surface:      "#0f1416"   // frame, bar and panels
        readonly property color container:    "#1a2224"   // groups inside the bar, cards
        readonly property color containerHigh: "#232c2e"  // hover
        readonly property color containerHighest: "#2e3739"
        readonly property color fg:    "#dfe4e5"
        readonly property color fgVariant: "#b9c3c5"
        readonly property color outline:      "#899395"
        readonly property color outlineVariant: "#3a4446"
        readonly property color primary:      "#e6b450"   // the one accent (terminal amber): active workspace, clock
        readonly property color fgPrimary:    "#1a1405"
        readonly property color primaryContainer: "#2b2616"
        readonly property color fgPrimaryContainer: "#e6b450"
        readonly property color secondaryContainer: "#1f3640" // open menu, toggles on
        readonly property color fgSecondaryContainer: "#9fd3dc"
        readonly property color tertiary:     "#9ece6a"   // battery ok (terminal green)
        readonly property color error:        "#f07178"
        readonly property color warning:      "#ff9e64"
        readonly property color barGroup:     container   // tonal groups inside the bar
        // bar, frame and the panels attached to them: solid and darker than the windows (monitor-bezel look).
        // Not translucent: a thin frame and a wide bar over different parts of the wallpaper never match.
        readonly property color barGlass:     "#080b0d"
        readonly property color glass:        Qt.rgba(15 / 255, 20 / 255, 22 / 255, 0.50) // desktop widgets: surface you can see through
        // 1px light on the inner frame edge: off. With a solid bar/frame it only made the right side of the bar
        // look narrower and left small seams where it met the window corners.
        readonly property color edge:         "transparent"
    }

    // ---- fonts ----
    readonly property QtObject font: QtObject {
        readonly property string family: "JetBrainsMono Nerd Font"
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
