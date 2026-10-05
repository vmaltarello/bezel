// Concave fillet: a filled square with a quarter circle cut out.
// corner = which corner of the square stays filled: "tl" "tr" "bl" "br".
import QtQuick
import QtQuick.Shapes
import qs.config

Shape {
    id: root
    property string corner: "tl"
    property real r: Theme.size.fillet
    property color color: Theme.c.frame

    width: r; height: r
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        fillColor: root.color
        strokeColor: "transparent"
        strokeWidth: 0
        PathSvg {
            readonly property real r: root.r
            path: ({
                tl: `M0,0 L${r},0 A${r},${r} 0 0 0 0,${r} Z`,
                tr: `M${r},0 L0,0 A${r},${r} 0 0 1 ${r},${r} Z`,
                bl: `M0,${r} L0,0 A${r},${r} 0 0 0 ${r},${r} Z`,
                br: `M${r},${r} L${r},0 A${r},${r} 0 0 1 0,${r} Z`
            })[root.corner]
        }
    }
}
