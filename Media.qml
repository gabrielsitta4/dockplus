import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
  id: root

  property string selectedName: ""
  property string cover: ""

  readonly property string coverDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/dockplus/covers"
  readonly property string coverScript: Qt.resolvedUrl("safe-image.py").toString().replace("file://", "")

  readonly property var players: Mpris.players.values.filter(function(player) {
    return player && String(player.dbusName).indexOf("playerctld") === -1 && player.playbackState !== MprisPlaybackState.Stopped
  })
  readonly property var player: {
    for (var i = 0; i < players.length; i++) if (players[i].dbusName === selectedName) return players[i]
    for (var j = 0; j < players.length; j++) if (players[j].isPlaying) return players[j]
    return players.length > 0 ? players[0] : null
  }
  readonly property bool playing: player ? player.isPlaying : false
  readonly property string title: player ? String(player.trackTitle || player.identity || "") : ""
  readonly property string artist: player ? String(player.trackArtist || "") : ""
  readonly property string artUrl: player ? String(player.trackArtUrl || "") : ""

  onArtUrlChanged: loadCover()

  function loadCover() {
    cover = ""
    if (!artUrl || coverReader.running) return
    coverReader.command = ["python3", coverScript, "cover", artUrl, coverDir]
    coverReader.running = true
  }

  function run(action) {
    if (!player) return
    if (action === "previous" && player.canGoPrevious) player.previous()
    else if (action === "next" && player.canGoNext) player.next()
    else if (action === "playPause" && player.canTogglePlaying) player.togglePlaying()
  }

  function select(other) { if (other) selectedName = other.dbusName }

  Process {
    id: coverReader
    stdout: StdioCollector {
      onStreamFinished: {
        var path = String(text || "").trim()
        if (root.artUrl && path === root.coverDir + "/cover-" + Qt.md5(root.artUrl) + ".png") root.cover = "file://" + path
      }
    }
    onExited: if (coverReader.command[3] !== root.artUrl) root.loadCover()
  }
}
