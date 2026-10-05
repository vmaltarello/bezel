pragma Singleton
// Media players (MPRIS): spotifyd, Zen, mpv...
// "player" = the one playing, otherwise the last used.
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    // playerctld is a proxy that mirrors the real player: skip it
    readonly property var players: Mpris.players.values.filter(p => !(p.dbusName ?? "").includes("playerctld"))
    readonly property MprisPlayer playingNow: players.find(p => p.isPlaying) ?? null
    // last player that was playing: only written from playingNow, so `player` never feeds back into itself
    property MprisPlayer last: null
    onPlayingNowChanged: if (playingNow) last = playingNow
    readonly property MprisPlayer player: playingNow ?? (players.includes(last) ? last : players[0] ?? null)
    readonly property bool active: player != null && player.playbackState !== MprisPlaybackState.Stopped && title !== ""
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string art: player?.trackArtUrl ?? ""

    function toggle() { if (player?.canTogglePlaying) player.togglePlaying(); }
    function next() { if (player?.canGoNext) player.next(); }
    function previous() { if (player?.canGoPrevious) player.previous(); }
}
