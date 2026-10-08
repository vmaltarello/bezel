// A rectangle with corners cut at 45° (like a mountain slope): bezel's signature shape.
// Free-standing things (rows, buttons, tiles) cut only the top-left corner (the default).
// Panels attached to the frame cut the two corners away from it instead (set them per corner).
import QtQuick
import QtQuick.Shapes
import qs.config

Item {
    id: root
    property color color: Theme.m.container
    property real cut: Theme.size.cut
    property real cutTL: cut
    property real cutTR: 0
    property real cutBL: 0
    property real cutBR: 0
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: -1
            PathSvg {
                readonly property real m: Math.min(root.width, root.height) / 2
                readonly property real tl: Math.min(root.cutTL, m)
                readonly property real tr: Math.min(root.cutTR, m)
                readonly property real bl: Math.min(root.cutBL, m)
                readonly property real br: Math.min(root.cutBR, m)
                readonly property real w: root.width
                readonly property real h: root.height
                path: `M${tl},0 H${w - tr} L${w},${tr} V${h - br} L${w - br},${h} H${bl} L0,${h - bl} V${tl} Z`
            }
        }
    }
}
