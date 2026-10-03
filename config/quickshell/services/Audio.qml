pragma Singleton
// Volume and microphone (PipeWire).
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool ready: sink?.audio != null
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property int percent: Math.round(volume * 100)
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false
    // bluetooth / jack headphones -> headphones icon
    readonly property bool headphones: {
        const n = (sink?.name ?? "") + " " + (sink?.description ?? "");
        return /bluez|headphone|headset|airpods/i.test(n);
    }

    function setVolume(v) {
        if (sink?.audio) { sink.audio.muted = false; sink.audio.volume = Math.max(0, Math.min(1, v)); }
    }
    function step(delta) { setVolume(volume + delta); }
    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted; }
    function toggleMicMute() { if (source?.audio) source.audio.muted = !source.audio.muted; }

    // without a tracker PipeWire doesn't send volume values
    PwObjectTracker { objects: [sink, source] }
}
