import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var pids: []
  property var info: ({})

  readonly property string script: Qt.resolvedUrl("window-process.py").toString().replace("file://", "")

  function of(pid) { return info[String(pid)] || null }

  function refresh() {
    var next = ({})
    var missing = []
    for (var i = 0; i < pids.length; i++) {
      var key = String(pids[i])
      if (info[key]) next[key] = info[key]
      else if (missing.indexOf(key) === -1) missing.push(key)
    }
    info = next
    if (missing.length > 0 && !reader.running) {
      reader.command = ["python3", script].concat(missing.slice(0, 64))
      reader.running = true
    }
  }

  onPidsChanged: refresh()

  Process {
    id: reader
    stdout: SplitParser {
      onRead: function(line) {
        var item = null
        try { item = JSON.parse(line) } catch (error) { return }
        if (!item || !item.pid) return
        var next = Object.assign({}, root.info)
        next[String(item.pid)] = { steam: String(item.steam || ""), agentIcon: String(item.agentIcon || "") }
        root.info = next
      }
    }
    onExited: {
      if (root.pids.some(function(pid) { return !root.info[String(pid)] })) root.refresh()
    }
  }
}
