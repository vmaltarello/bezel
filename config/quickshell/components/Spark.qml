// Small line chart (recent values) with a filled area below.
import QtQuick
import qs.config
import qs.services

Canvas {
    id: root
    property var values: []
    property real max: 100
    property color color: Theme.c.blue

    renderStrategy: Canvas.Immediate
    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        const w = width, h = height, v = values, n = v.length;
        ctx.reset();
        if (n < 2) return;
        // newest value on the right; with less than 2 minutes of history the line starts further right
        const step = w / (System.histLength - 1), x0 = w - (n - 1) * step;
        const y = i => h - 1 - Math.min(v[i], root.max) / root.max * (h - 2);
        ctx.beginPath();
        ctx.moveTo(x0, y(0));
        for (let i = 1; i < n; i++) ctx.lineTo(x0 + i * step, y(i));
        ctx.lineWidth = 1.5;
        ctx.lineJoin = "round";
        ctx.strokeStyle = root.color;
        ctx.stroke();
        ctx.lineTo(w, h); ctx.lineTo(x0, h); ctx.closePath();
        ctx.globalAlpha = 0.18;
        ctx.fillStyle = root.color;
        ctx.fill();
    }
}
