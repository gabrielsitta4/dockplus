import QtQuick
import Quickshell
import Quickshell.Io
import "Logic.js" as Logic

Item {
  id: root

  property bool active: true
  property var map: ({})

  readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")
  readonly property string script: Qt.resolvedUrl("recent-files.py").toString().replace("file://", "")

  function filesFor(entry) {
    if (!entry) return []
    return Logic.recentFor(map, [entry.id, Logic.programName(entry.command)], 5)
  }

  FileView {
    path: root.active ? root.dataHome + "/recently-used.xbel" : ""
    preload: false
    watchChanges: true
    printErrors: false
    onFileChanged: refresh.restart()
  }

  Timer {
    id: refresh
    interval: 1000
    onTriggered: reader.running = root.active
  }

  Process {
    id: reader
    command: ["python3", root.script, root.dataHome + "/recently-used.xbel"]
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.map = JSON.parse(text) || ({}) } catch (error) { root.map = ({}) }
      }
    }
  }

  onActiveChanged: {
    if (active) reader.running = true
    else map = ({})
  }

  Component.onCompleted: reader.running = active
}
