import QtQuick
import Quickshell
import Quickshell.Io
import "Logic.js" as Logic

Item {
  id: root

  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string configDir: configHome + "/dockplus"
  readonly property string configPath: configDir + "/config.json"

  readonly property var defaults: ({
    autohide: true,
    iconSize: 48,
    monitor: "",
    position: "bottom",
    showAppsButton: true,
    showTrash: true,
    showDrives: true,
    showPinned: true,
    notificationBadges: true,
    appBadges: true,
    showMedia: true,
    showRecent: true,
    folderClick: "stack",
    middleClick: "newWindow",
    scrollAction: "cycle",
    previewDelay: 500,
    clickAction: "smart",
    isolateMonitors: false,
    animations: true,
    animationSpeed: 100,
    hoverZoom: 10,
    launchBounce: true,
    urgentWiggle: true,
    revealStyle: "slide",
    showDelay: 120,
    hideDelay: 450,
    superNumbers: false,
    previewOnHover: false,
    indicatorStyle: "default",
    backgroundOpacity: 100,
    panelMode: false,
    blur: false,
    hideWhileRecording: true,
    isolateWorkspaces: false
  })

  readonly property int minIconSize: 24
  readonly property int maxIconSize: 96

  readonly property bool autohide: adapter.autohide
  readonly property int iconSize: Math.max(minIconSize, Math.min(maxIconSize, adapter.iconSize))
  readonly property string monitor: adapter.monitor
  readonly property var positions: ["bottom", "left", "right"]
  readonly property string position: positions.indexOf(adapter.position) !== -1 ? adapter.position : defaults.position
  readonly property bool showAppsButton: adapter.showAppsButton
  readonly property bool showTrash: adapter.showTrash
  readonly property bool showDrives: adapter.showDrives
  readonly property bool showPinned: adapter.showPinned
  readonly property bool notificationBadges: adapter.notificationBadges
  readonly property int minOpacity: 15
  readonly property var indicatorStyles: ["default", "dots", "dashes", "segments"]
  readonly property string indicatorStyle: indicatorStyles.indexOf(adapter.indicatorStyle) !== -1 ? adapter.indicatorStyle : defaults.indicatorStyle
  readonly property int backgroundOpacity: Math.max(minOpacity, Math.min(100, adapter.backgroundOpacity))
  readonly property bool panelMode: adapter.panelMode
  readonly property bool blur: adapter.blur
  readonly property bool hideWhileRecording: adapter.hideWhileRecording
  readonly property bool animations: adapter.animations
  readonly property int animationSpeed: Math.max(50, Math.min(200, adapter.animationSpeed))
  readonly property int hoverZoom: Math.max(0, Math.min(30, adapter.hoverZoom))
  readonly property bool launchBounce: adapter.launchBounce
  readonly property bool urgentWiggle: adapter.urgentWiggle
  readonly property var revealStyles: ["slide", "fade", "none"]
  readonly property string revealStyle: revealStyles.indexOf(adapter.revealStyle) !== -1 ? adapter.revealStyle : defaults.revealStyle
  readonly property int showDelay: Math.max(0, Math.min(500, adapter.showDelay))
  readonly property int hideDelay: Math.max(200, Math.min(2000, adapter.hideDelay))
  readonly property bool isolateMonitors: adapter.isolateMonitors
  readonly property bool superNumbers: adapter.superNumbers
  readonly property bool previewOnHover: adapter.previewOnHover
  readonly property bool isolateWorkspaces: adapter.isolateWorkspaces
  readonly property var clickActions: ["smart", "cycle", "launch"]
  readonly property string clickAction: clickActions.indexOf(adapter.clickAction) !== -1 ? adapter.clickAction : defaults.clickAction
  readonly property bool appBadges: adapter.appBadges
  readonly property bool showMedia: adapter.showMedia
  readonly property bool showRecent: adapter.showRecent
  readonly property var folderClicks: ["stack", "open"]
  readonly property string folderClick: folderClicks.indexOf(adapter.folderClick) !== -1 ? adapter.folderClick : defaults.folderClick
  readonly property var middleClicks: ["newWindow", "close", "minimize"]
  readonly property string middleClick: middleClicks.indexOf(adapter.middleClick) !== -1 ? adapter.middleClick : defaults.middleClick
  readonly property var scrollActions: ["cycle", "none"]
  readonly property string scrollAction: scrollActions.indexOf(adapter.scrollAction) !== -1 ? adapter.scrollAction : defaults.scrollAction
  readonly property int previewDelay: Math.max(100, Math.min(1500, adapter.previewDelay))

  readonly property string folderPrefix: "@folder:"
  readonly property var specials: ["@drives", "@trash", "@apps"]
  readonly property var order: {
    var out = []
    for (var i = 0; i < adapter.pinned.length; i++) {
      var token = String(adapter.pinned[i])
      if (token && out.indexOf(token) === -1) out.push(token)
    }
    for (var j = 0; j < specials.length; j++)
      if (out.indexOf(specials[j]) === -1) out.push(specials[j])
    return out
  }
  readonly property var pinned: order.filter(function(token) { return !root.isSpecial(token) })
  readonly property var folders: order.filter(function(token) { return root.isFolder(token) })

  function setAutohide(value) { adapter.autohide = value === true }
  function setIconSize(value) { adapter.iconSize = Math.max(minIconSize, Math.min(maxIconSize, Math.round(value))) }
  function setMonitor(name) { adapter.monitor = String(name || "") }
  function setPosition(value) { if (positions.indexOf(value) !== -1) adapter.position = value }

  function setShowAppsButton(value) { adapter.showAppsButton = value === true }
  function setShowTrash(value) { adapter.showTrash = value === true }
  function setShowDrives(value) { adapter.showDrives = value === true }
  function setShowPinned(value) { adapter.showPinned = value === true }
  function setNotificationBadges(value) { adapter.notificationBadges = value === true }
  function setIndicatorStyle(value) { if (indicatorStyles.indexOf(value) !== -1) adapter.indicatorStyle = value }
  function setBackgroundOpacity(value) { adapter.backgroundOpacity = Math.max(minOpacity, Math.min(100, Math.round(value))) }
  function setPanelMode(value) { adapter.panelMode = value === true }
  function setBlur(value) { adapter.blur = value === true }
  function setHideWhileRecording(value) { adapter.hideWhileRecording = value === true }
  function setPreviewOnHover(value) { adapter.previewOnHover = value === true }
  function setSuperNumbers(value) { adapter.superNumbers = value === true }
  function setAnimations(value) { adapter.animations = value === true }
  function setAnimationSpeed(value) { adapter.animationSpeed = Math.max(50, Math.min(200, Math.round(value))) }
  function setHoverZoom(value) { adapter.hoverZoom = Math.max(0, Math.min(30, Math.round(value))) }
  function setLaunchBounce(value) { adapter.launchBounce = value === true }
  function setUrgentWiggle(value) { adapter.urgentWiggle = value === true }
  function setRevealStyle(value) { if (revealStyles.indexOf(value) !== -1) adapter.revealStyle = value }
  function setShowDelay(value) { adapter.showDelay = Math.max(0, Math.min(500, Math.round(value))) }
  function setHideDelay(value) { adapter.hideDelay = Math.max(200, Math.min(2000, Math.round(value))) }
  function setIsolateMonitors(value) { adapter.isolateMonitors = value === true }
  function setIsolateWorkspaces(value) { adapter.isolateWorkspaces = value === true }
  function setClickAction(value) { if (clickActions.indexOf(value) !== -1) adapter.clickAction = value }
  function setAppBadges(value) { adapter.appBadges = value === true }
  function setShowMedia(value) { adapter.showMedia = value === true }
  function setShowRecent(value) { adapter.showRecent = value === true }
  function setFolderClick(value) { if (folderClicks.indexOf(value) !== -1) adapter.folderClick = value }
  function setMiddleClick(value) { if (middleClicks.indexOf(value) !== -1) adapter.middleClick = value }
  function setScrollAction(value) { if (scrollActions.indexOf(value) !== -1) adapter.scrollAction = value }
  function setPreviewDelay(value) { adapter.previewDelay = Math.max(100, Math.min(1500, Math.round(value))) }

  function resetDefaults() {
    for (var key in defaults) adapter[key] = defaults[key]
  }

  function isSpecial(token) { return String(token).charAt(0) === "@" }

  function isFolder(token) { return String(token).indexOf(folderPrefix) === 0 }

  function folderPath(token) { return String(token).substring(folderPrefix.length) }

  function folderToken(path) { return Logic.folderToken(folderPrefix, path) }

  function addFolder(path) {
    var token = folderToken(path)
    if (!path || order.indexOf(token) !== -1) return
    setOrder(order.concat([token]))
  }

  function removeToken(token) {
    if (specials.indexOf(token) !== -1) return
    setOrder(order.filter(function(other) { return other !== token }))
  }

  function isPinned(key) { return pinned.indexOf(key) !== -1 }

  function setOrder(tokens) { adapter.pinned = tokens }

  function pin(key) {
    if (!key || isSpecial(key) || isPinned(key)) return
    var next = order.slice()
    var lastApp = -1
    for (var i = 0; i < next.length; i++) if (!isSpecial(next[i])) lastApp = i
    next.splice(lastApp + 1, 0, key)
    setOrder(next)
  }

  function unpin(key) {
    if (isSpecial(key)) return
    setOrder(order.filter(function(token) { return token !== key }))
  }

  function moveEntry(token, toIndex) {
    if (!token || (isSpecial(token) && specials.indexOf(token) === -1 && !isFolder(token))) return
    var next = order.filter(function(other) { return other !== token })
    var target = Math.max(0, Math.min(next.length, Math.round(toIndex)))
    next.splice(target, 0, token)
    setOrder(next)
  }

  FileView {
    id: file
    path: root.configPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoadFailed: function(error) {
      if (error === FileViewError.FileNotFound) bootstrap.running = true
    }

    JsonAdapter {
      id: adapter
      property bool autohide: root.defaults.autohide
      property int iconSize: root.defaults.iconSize
      property string monitor: root.defaults.monitor
      property string position: root.defaults.position
      property bool showAppsButton: root.defaults.showAppsButton
      property bool showTrash: root.defaults.showTrash
      property bool showDrives: root.defaults.showDrives
      property bool showPinned: root.defaults.showPinned
      property bool notificationBadges: root.defaults.notificationBadges
      property bool appBadges: root.defaults.appBadges
      property bool showMedia: root.defaults.showMedia
      property bool showRecent: root.defaults.showRecent
      property string folderClick: root.defaults.folderClick
      property string middleClick: root.defaults.middleClick
      property string scrollAction: root.defaults.scrollAction
      property int previewDelay: root.defaults.previewDelay
      property string clickAction: root.defaults.clickAction
      property bool isolateMonitors: root.defaults.isolateMonitors
      property bool animations: root.defaults.animations
      property int animationSpeed: root.defaults.animationSpeed
      property int hoverZoom: root.defaults.hoverZoom
      property bool launchBounce: root.defaults.launchBounce
      property bool urgentWiggle: root.defaults.urgentWiggle
      property string revealStyle: root.defaults.revealStyle
      property int showDelay: root.defaults.showDelay
      property int hideDelay: root.defaults.hideDelay
      property bool superNumbers: root.defaults.superNumbers
      property bool previewOnHover: root.defaults.previewOnHover
      property string indicatorStyle: root.defaults.indicatorStyle
      property int backgroundOpacity: root.defaults.backgroundOpacity
      property bool panelMode: root.defaults.panelMode
      property bool blur: root.defaults.blur
      property bool hideWhileRecording: root.defaults.hideWhileRecording
      property bool isolateWorkspaces: root.defaults.isolateWorkspaces
      property list<string> pinned: []
    }
  }

  Process {
    id: bootstrap
    command: ["sh", "-c",
      "mkdir -p \"$1\"; cat \"${XDG_CONFIG_HOME:-$HOME/.config}/xdg-terminals.list\" /usr/share/xdg-terminal-exec/xdg-terminals.list 2>/dev/null"
      + " | sed -n 's/^\\([^#[:space:]][^[:space:]]*\\)\\.desktop.*/\\1/p' | head -n1",
      "sh", root.configDir]
    stdout: StdioCollector {
      onStreamFinished: {
        var terminal = String(text || "").trim()
        if (terminal) adapter.pinned = [terminal]
        file.writeAdapter()
      }
    }
  }
}
