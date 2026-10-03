.pragma library

var maxBadgeKey = 128
var maxBadgeCount = 9999

function cycleDecision(windowCount, openCount, focusedIndex) {
  if (windowCount <= 0) return "launch"
  if (openCount <= 0) return "restore"
  if (focusedIndex < 0) return "focus"
  if (openCount === 1) return "minimize"
  return "cycle"
}

function nextIndex(count, current, step) {
  if (count <= 0) return -1
  if (current < 0 || current >= count) return step < 0 ? count - 1 : 0
  return ((current + step) % count + count) % count
}

function mprisName(busName) {
  var prefix = "org.mpris.MediaPlayer2."
  var name = String(busName || "")
  if (name.indexOf(prefix) !== 0) return ""
  return name.substring(prefix.length).split(".")[0]
}

function trackLabel(title, artist) {
  var parts = [String(title || ""), String(artist || "")].filter(function(part) { return part !== "" })
  return parts.join(" · ")
}

function programName(command) {
  if (!command || command.length === 0) return ""
  var parts = String(command[0]).split("/")
  return parts[parts.length - 1]
}

function recentFor(map, names, limit) {
  var out = []
  names.forEach(function(name) {
    var files = name && map ? map[name] || [] : []
    files.forEach(function(file) {
      if (out.length < limit && !out.some(function(other) { return other.uri === file.uri })) out.push(file)
    })
  })
  return out
}

var imageSuffixes = ["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg"]
var suffixIcons = [
  { icon: "video-x-generic", suffixes: ["mp4", "mkv", "webm", "avi", "mov"] },
  { icon: "audio-x-generic", suffixes: ["mp3", "flac", "ogg", "opus", "wav", "m4a"] },
  { icon: "application-pdf", suffixes: ["pdf"] },
  { icon: "package-x-generic", suffixes: ["zip", "rar", "7z", "tar", "gz", "xz", "zst"] },
  { icon: "x-office-document", suffixes: ["doc", "docx", "odt"] },
  { icon: "x-office-spreadsheet", suffixes: ["xls", "xlsx", "ods", "csv"] }
]

function suffixOf(name) {
  var dot = String(name).lastIndexOf(".")
  return dot > 0 ? String(name).substring(dot + 1).toLowerCase() : ""
}

function isImage(name) { return imageSuffixes.indexOf(suffixOf(name)) !== -1 }

function fileIcons(name, isDir) {
  if (isDir) return ["folder", "inode-directory"]
  var suffix = suffixOf(name)
  for (var i = 0; i < suffixIcons.length; i++)
    if (suffixIcons[i].suffixes.indexOf(suffix) !== -1) return [suffixIcons[i].icon, "text-x-generic"]
  return ["text-x-generic", "unknown"]
}

function workspaceTargets(ids, current) {
  var used = ids.filter(function(id) { return id > 0 }).sort(function(a, b) { return a - b })
  var free = 1
  while (used.indexOf(free) !== -1) free++
  return {
    existing: used.filter(function(id) { return id !== current }),
    fresh: free
  }
}

function folderName(path) {
  var parts = String(path).split("/").filter(function(part) { return part !== "" })
  return parts.length > 0 ? parts[parts.length - 1] : String(path)
}

function folderIcons(path) {
  var known = {
    Downloads: "folder-download",
    Documents: "folder-documents",
    Pictures: "folder-pictures",
    Music: "folder-music",
    Videos: "folder-videos",
    Desktop: "user-desktop",
    Public: "folder-publicshare"
  }
  var name = folderName(path)
  var icons = known[name] ? [known[name]] : []
  return icons.concat(["folder", "inode-directory"])
}

function folderToken(prefix, path) {
  return prefix + String(path).replace(/\/+$/, "")
}

function notifyNames(update) {
  if (!update) return []
  return [update.entry, update.app].map(function(name) { return String(name || "") })
    .filter(function(name) { return name !== "" && name.length <= maxBadgeKey })
}

function badgeFrom(update) {
  var key = String(update.appId || "")
  if (!key || key.length > maxBadgeKey) return null
  var count = update.countVisible ? Math.min(maxBadgeCount, Math.max(0, Math.round(Number(update.count) || 0))) : 0
  var progress = update.progressVisible ? Math.max(0, Math.min(1, Number(update.progress) || 0)) : -1
  if (count === 0 && progress < 0) return { key: key, value: null }
  return { key: key, value: { count: count, progress: progress } }
}
