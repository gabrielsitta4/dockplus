import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import qs.Commons
import "Logic.js" as Logic

Rectangle {
  id: stack

  property var dock
  property string path: ""

  readonly property int maxFiles: 12
  readonly property int cellWidth: 92
  readonly property int iconSize: 48
  readonly property int shown: Math.min(files.count, maxFiles)

  signal finished()

  function iconSource(name, isDir) {
    var names = Logic.fileIcons(name, isDir)
    for (var i = 0; i < names.length; i++) {
      var found = Quickshell.iconPath(names[i], true)
      if (found) return found
    }
    return ""
  }

  function openFile(filePath) {
    Quickshell.execDetached(["gio", "open", filePath])
    finished()
  }

  width: Math.max(grid.implicitWidth, openRow.implicitWidth) + 16
  height: grid.implicitHeight + openRow.height + 24
  radius: Style.cornerRadius
  color: Color.popups.background
  border.width: Math.max(1, Style.space(2))
  border.color: Color.popups.border

  FolderListModel {
    id: files
    folder: stack.path ? "file://" + stack.path : ""
    sortField: FolderListModel.Time
    showDirsFirst: false
    showDotAndDotDot: false
  }

  Grid {
    id: grid
    x: 8
    y: 8
    columns: Math.max(1, Math.min(4, stack.shown))
    spacing: 4

    Text {
      textFormat: Text.PlainText
      visible: stack.shown === 0
      width: 200
      text: stack.dock.tr("emptyFolder")
      color: Util.alpha(Color.popups.text, 0.6)
      font.family: Style.fontFamily
      font.pixelSize: Style.fontPx(1)
      horizontalAlignment: Text.AlignHCenter
    }

    Repeater {
      model: stack.shown

      Rectangle {
        id: cell
        required property int index
        readonly property string fileName: files.get(index, "fileName") || ""
        readonly property string filePath: files.get(index, "filePath") || ""
        readonly property bool isDir: files.get(index, "fileIsDir") === true
        readonly property bool isImage: !isDir && Logic.isImage(fileName)

        width: stack.cellWidth
        height: stack.iconSize + cellLabel.implicitHeight + 16
        radius: Style.cornerRadius
        color: cellMouse.containsMouse ? Util.alpha(Color.popups.text, 0.1) : "transparent"

        Image {
          x: Math.round((parent.width - stack.iconSize) / 2)
          y: 6
          width: stack.iconSize
          height: stack.iconSize
          sourceSize: Qt.size(stack.iconSize * 2, stack.iconSize * 2)
          fillMode: Image.PreserveAspectFit
          asynchronous: true
          smooth: true
          source: cell.isImage ? "file://" + cell.filePath : stack.iconSource(cell.fileName, cell.isDir)
        }

        Text {
          id: cellLabel
          textFormat: Text.PlainText
          x: 4
          y: stack.iconSize + 10
          width: parent.width - 8
          text: cell.fileName
          color: Color.popups.text
          font.family: Style.fontFamily
          font.pixelSize: Style.fontPx(0.85)
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideMiddle
          maximumLineCount: 1
        }

        MouseArea {
          id: cellMouse
          anchors.fill: parent
          hoverEnabled: true
          onClicked: stack.openFile(cell.filePath)
        }
      }
    }
  }

  Rectangle {
    id: openRow
    x: 8
    y: grid.y + grid.implicitHeight + 8
    width: parent.width - 16
    height: openLabel.implicitHeight + 14
    implicitWidth: openLabel.implicitWidth + 28
    radius: Style.cornerRadius
    color: openMouse.containsMouse ? Util.alpha(Color.popups.text, 0.1) : "transparent"

    Text {
      id: openLabel
      textFormat: Text.PlainText
      anchors.centerIn: parent
      text: stack.dock.tr("openFolder")
      color: Color.popups.text
      font.family: Style.fontFamily
      font.pixelSize: Style.fontPx(1)
    }

    MouseArea {
      id: openMouse
      anchors.fill: parent
      hoverEnabled: true
      onClicked: stack.openFile(stack.path)
    }
  }
}
