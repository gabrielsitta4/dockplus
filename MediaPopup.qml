import QtQuick
import qs.Commons

Rectangle {
  id: popup

  property var dock
  readonly property var media: dock.media
  readonly property int innerWidth: 300
  readonly property int coverSize: 72
  readonly property string coverSource: media.cover || dock.playerIcon(media.player)

  width: innerWidth + 24
  height: column.implicitHeight + 24
  radius: Style.cornerRadius
  color: Color.popups.background
  border.width: Math.max(1, Style.space(2))
  border.color: Color.popups.border

  component Glyph: Rectangle {
    id: glyphButton
    property int code: 0
    property bool active: true
    signal triggered()

    width: 44
    height: 36
    radius: Style.cornerRadius
    color: glyphMouse.containsMouse && active ? Util.alpha(Color.popups.text, 0.1) : "transparent"

    Text {
      textFormat: Text.PlainText
      anchors.centerIn: parent
      text: String.fromCodePoint(glyphButton.code)
      color: Util.alpha(Color.popups.text, glyphButton.active ? 1 : 0.35)
      font.family: Style.fontFamily
      font.pixelSize: Style.fontPx(1.6)
    }

    MouseArea {
      id: glyphMouse
      anchors.fill: parent
      hoverEnabled: true
      enabled: glyphButton.active
      onClicked: glyphButton.triggered()
    }
  }

  Column {
    id: column
    x: 12
    y: 12
    width: popup.innerWidth
    spacing: 10

    Row {
      width: parent.width
      spacing: 12

      Rectangle {
        id: cover
        width: popup.coverSize
        height: popup.coverSize
        radius: Style.cornerRadius
        color: Util.alpha(Color.popups.text, 0.08)
        clip: true

        Image {
          anchors.fill: parent
          sourceSize: Qt.size(popup.coverSize * 2, popup.coverSize * 2)
          fillMode: Image.PreserveAspectCrop
          source: popup.coverSource
          visible: source !== ""
          asynchronous: true
          smooth: true
        }

        Text {
          textFormat: Text.PlainText
          anchors.centerIn: parent
          visible: popup.coverSource === ""
          text: String.fromCodePoint(0xF075A)
          color: Color.popups.text
          font.family: Style.fontFamily
          font.pixelSize: Style.fontPx(2.4)
        }
      }

      Column {
        width: parent.width - cover.width - controls.width - parent.spacing * 2
        anchors.verticalCenter: cover.verticalCenter
        spacing: 3

        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: popup.media.title
          color: Color.popups.text
          font.family: Style.fontFamily
          font.pixelSize: Style.fontPx(1.1)
          font.bold: true
          elide: Text.ElideRight
        }

        Text {
          textFormat: Text.PlainText
          width: parent.width
          visible: text !== ""
          text: popup.media.artist
          color: Util.alpha(Color.popups.text, 0.7)
          font.family: Style.fontFamily
          font.pixelSize: Style.fontPx(0.95)
          elide: Text.ElideRight
        }
      }

      Row {
        id: controls
        anchors.verticalCenter: cover.verticalCenter

        Glyph {
          code: popup.media.playing ? 0xF03E4 : 0xF040A
          active: !!popup.media.player && popup.media.player.canTogglePlaying
          onTriggered: popup.media.run("playPause")
        }

        Glyph {
          code: 0xF04AD
          active: !!popup.media.player && popup.media.player.canGoNext
          onTriggered: popup.media.run("next")
        }
      }
    }

    Rectangle {
      visible: popup.media.players.length > 1
      width: parent.width
      height: 1
      color: Util.alpha(Color.popups.text, 0.15)
    }

    Column {
      width: parent.width
      visible: popup.media.players.length > 1

      Repeater {
        model: popup.media.players.length

        Rectangle {
          id: playerRow
          required property int index
          readonly property var player: popup.media.players[index]

          width: parent.width
          height: playerLabel.implicitHeight + 12
          radius: Style.cornerRadius
          color: player === popup.media.player ? Util.alpha(Color.accent, 0.2)
            : playerMouse.containsMouse ? Util.alpha(Color.popups.text, 0.1) : "transparent"

          Text {
            id: playerLabel
            textFormat: Text.PlainText
            anchors.verticalCenter: parent.verticalCenter
            x: 10
            width: parent.width - 20
            text: String.fromCodePoint(playerRow.player && playerRow.player.isPlaying ? 0xF03E4 : 0xF040A) + "  "
              + (playerRow.player ? String(playerRow.player.trackTitle || playerRow.player.identity || "") : "")
            color: Color.popups.text
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPx(0.95)
            elide: Text.ElideRight
          }

          MouseArea {
            id: playerMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: popup.media.select(playerRow.player)
          }
        }
      }
    }
  }
}
