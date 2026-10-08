// Rectangle drawn as a vector shape, in bezel's "Vetta" style: only the top-left corner is cut at
// 45° (its size follows the radius given), the other corners are square. cutCorner: false brings back
// plain rounded corners where a round shape is really needed.
// Used like Rectangle (color, radius, per-corner radii, border.width/border.color), but curved edges
// stay smooth with the software renderer, which makes them jagged at scale 1.5.
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property color color: "white"
    property real radius: 0
    property bool cutCorner: true
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomLeftRadius: radius
    property real bottomRightRadius: radius
    component Border: QtObject {
        property real width: 0
        property color color: "transparent"
    }
    readonly property Border border: Border {}

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            id: sp
            readonly property real bw: root.border.width
            fillColor: root.color
            strokeColor: bw > 0 ? root.border.color : "transparent"
            strokeWidth: bw > 0 ? bw : -1
            // hand-written path (like the frame fillets): PathRectangle isn't drawn by the software renderer
            PathSvg {
                readonly property real b: sp.bw / 2
                readonly property real w: Math.max(0, root.width - sp.bw)
                readonly property real h: Math.max(0, root.height - sp.bw)
                readonly property real m: Math.min(w, h) / 2
                readonly property real tl: Math.min(root.topLeftRadius, m)
                readonly property real tr: Math.min(root.topRightRadius, m)
                readonly property real bl: Math.min(root.bottomLeftRadius, m)
                readonly property real br: Math.min(root.bottomRightRadius, m)
                readonly property real c: Math.min(Math.max(root.topLeftRadius, root.topRightRadius, root.bottomLeftRadius, root.bottomRightRadius), m)
                path: root.cutCorner
                    ? `M${b + c},${b} H${b + w} V${b + h} H${b} V${b + c} Z`
                    : `M${b + tl},${b} H${b + w - tr} A${tr},${tr} 0 0 1 ${b + w},${b + tr} V${b + h - br} A${br},${br} 0 0 1 ${b + w - br},${b + h} H${b + bl} A${bl},${bl} 0 0 1 ${b},${b + h - bl} V${b + tl} A${tl},${tl} 0 0 1 ${b + tl},${b} Z`
            }
        }
    }
}
