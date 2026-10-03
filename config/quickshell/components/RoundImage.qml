// Round image that works with the software renderer.
// Draws the image, then covers the corners with the background color (smooth edges, unlike clipping).
import QtQuick
import qs.config

Canvas {
    id: root
    property url source
    property color background: Theme.c.cell     // color of what is behind (to cover the corners)
    property color fallback: Theme.c.ink4
    property real cornerRadius: -1             // -1 = circle; otherwise a rounded square with this radius

    renderStrategy: Canvas.Immediate
    onSourceChanged: { if (source != "") loadImage(source); requestPaint(); }
    onImageLoaded: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        const w = width, h = height, r = Math.min(w, h) / 2;
        ctx.reset();
        // the image is a bit larger than the circle: its edges end up outside and get covered
        if (source != "" && isImageLoaded(source)) ctx.drawImage(source, -3, -3, w + 6, h + 6);
        else { ctx.fillStyle = fallback; ctx.fillRect(0, 0, w, h); }
        // covers everything outside the circle (evenodd: rectangle minus circle)
        ctx.beginPath();
        ctx.rect(-1, -1, w + 2, h + 2);
        if (cornerRadius < 0) ctx.arc(w / 2, h / 2, r - 0.5, 0, 2 * Math.PI, true);
        else {
            // rounded square, drawn counter-clockwise so evenodd keeps the inside
            const k = Math.min(cornerRadius, r), a = 0.5, b = w - 0.5, c = h - 0.5;
            ctx.moveTo(a + k, a);
            ctx.arcTo(a, a, a, a + k, k); ctx.lineTo(a, c - k);
            ctx.arcTo(a, c, a + k, c, k); ctx.lineTo(b - k, c);
            ctx.arcTo(b, c, b, c - k, k); ctx.lineTo(b, a + k);
            ctx.arcTo(b, a, b - k, a, k); ctx.lineTo(a + k, a);
        }
        ctx.closePath();
        ctx.fillStyle = background;
        ctx.fill();
    }
}
