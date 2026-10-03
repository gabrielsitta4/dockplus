import QtQuick
import Quickshell
import Quickshell.Io
import "Logic.js" as Logic

Item {
  id: root

  property var known: []
  property var map: ({})
  property int retries: 0
  property bool countNotifications: false
  property string focusedKey: ""
  property var resolve: null
  property var notified: ({})
  property int notifyRetries: 0

  readonly property int maxEntries: 64
  readonly property int maxRetries: 3
  readonly property int maxLine: 512
  readonly property string script: Qt.resolvedUrl("launcher-entry-watch.py").toString().replace("file://", "")
  readonly property string notifyScript: Qt.resolvedUrl("notify-watch.py").toString().replace("file://", "")

  function of(key) {
    if (map[key]) return map[key]
    return countNotifications && notified[key] ? { count: notified[key], progress: -1 } : null
  }

  function bump(update) {
    var key = typeof resolve === "function" ? resolve(Logic.notifyNames(update)) : ""
    if (!key || key === focusedKey || known.indexOf(key) === -1) return
    var next = Object.assign({}, notified)
    next[key] = Math.min(Logic.maxBadgeCount, (next[key] || 0) + 1)
    notified = next
  }

  function clear(key) {
    if (!notified[key]) return
    var next = Object.assign({}, notified)
    delete next[key]
    notified = next
  }

  function apply(update) {
    var parsed = Logic.badgeFrom(update)
    if (!parsed || known.indexOf(parsed.key) === -1) return
    var next = Object.assign({}, map)
    if (parsed.value === null) delete next[parsed.key]
    else if (next[parsed.key] !== undefined || Object.keys(next).length < maxEntries) next[parsed.key] = parsed.value
    else return
    map = next
  }

  function pruned(source) {
    var next = ({})
    for (var key in source) if (known.indexOf(key) !== -1) next[key] = source[key]
    return Object.keys(next).length === Object.keys(source).length ? source : next
  }

  onKnownChanged: {
    map = pruned(map)
    notified = pruned(notified)
  }
  onFocusedKeyChanged: clear(focusedKey)
  onCountNotificationsChanged: if (!countNotifications) notified = ({})

  Process {
    id: watch
    running: true
    command: ["python3", root.script]
    stdout: SplitParser {
      onRead: function(line) {
        if (line.length > root.maxLine) return
        var update = null
        try { update = JSON.parse(line) } catch (error) { return }
        root.apply(update)
      }
    }
    onExited: {
      if (root.retries >= root.maxRetries) return
      root.retries++
      watchRestart.restart()
    }
  }

  Timer {
    id: watchRestart
    interval: 5000
    onTriggered: watch.running = true
  }

  Process {
    id: notifyWatch
    running: root.countNotifications
    command: ["python3", root.notifyScript]
    onStarted: root.notifyRetries = 0
    stdout: SplitParser {
      onRead: function(line) {
        if (line.length > root.maxLine) return
        var update = null
        try { update = JSON.parse(line) } catch (error) { return }
        root.bump(update)
      }
    }
    onExited: {
      if (!root.countNotifications || root.notifyRetries >= root.maxRetries) return
      root.notifyRetries++
      notifyRestart.restart()
    }
  }

  Timer {
    id: notifyRestart
    interval: 5000
    onTriggered: notifyWatch.running = root.countNotifications
  }
}
