// Desktop shell: vertical bar, screen frame, panels growing out of the edges.
//@ pragma UseQApplication
// software rendering: for a shell made of simple shapes it looks the same and saves ~150 MB of RAM
// (no GPU driver loaded). Remove this line to render on the GPU again.
//@ pragma Env QT_QUICK_BACKEND=software
import QtQuick
import Quickshell
import "modules/shell"

ShellRoot {
    Shell {}
}
