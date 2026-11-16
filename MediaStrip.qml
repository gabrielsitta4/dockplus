import QtQuick
import qs.Commons

Item {
  id: strip

  property var dock
  property var host

  readonly property var media: dock.media
  readonly property bool wide: !host.vertical
  readonly property int coverSize: host.iconSize
  readonly property int textWidth: Math.round(host.iconSize * 3.4)
  readonly property int glyphSize: Math.round(host.iconSize * 0.4)
  readonly property string coverSource: media.cover || dock.playerIcon(media.player)

  function playersMenu() {
    return media.players.map(function(player) {
      return {
        label: String.fromCodePoint(player.isPlaying ? 0xF03E4 : 0xF040A) + "  " + String(player.trackTitle || player.identity || ""),
        run: function() { strip.media.select(player) }
      }
    })
  }

  visible: dock.config.mediaItem && media.player !== null
  width: wide ? coverSize + 10 + textWidth + host.itemPadding * 2 : coverSize + host.itemPadding * 2 + host.indicatorSpace
  height: wide ? coverSize + host.itemPadding * 2 + host.indicatorSpace : coverSize + host.itemPadding * 2

  component Glyph: Item {
    id: glyph
    property int code: 0
    property bool active: true
    signal triggered()

    width: strip.glyphSize + 10
    height: strip.glyphSize

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: glyphMouse.containsMouse && glyph.active ? Util.alpha(Color.bar.text, 0.12) : "transparent"
    }

    Text {
      textFormat: Text.PlainText
      anchors.centerIn: parent
      text: String.fromCodePoint(glyph.code)
      color: Util.alpha(Color.bar.text, glyph.active ? 1 : 0.35)
      font.family: Style.fontFamily
      font.pixelSize: Math.round(strip.glyphSize * 0.8)
    }

    MouseArea {
      id: glyphMouse
      anchors.fill: parent
      hoverEnabled: true
      enabled: glyph.active
      onClicked: glyph.triggered()
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onClicked: function(event) {
      if (event.button === Qt.MiddleButton) strip.media.run("playPause")
      else if (event.button === Qt.RightButton) {
        if (strip.media.players.length > 1) strip.host.openMenu(strip, strip.playersMenu())
      } else if (!strip.wide) strip.host.toggleMedia(strip)
    }
    onWheel: function(wheel) {
      var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
      if (delta !== 0) strip.media.run(delta < 0 ? "next" : "previous")
    }
  }

  Rectangle {
    id: cover
    x: strip.host.itemPadding + (strip.host.position === "left" ? strip.host.indicatorSpace : 0)
    y: strip.host.itemPadding
    width: strip.coverSize
    height: strip.coverSize
    radius: Style.cornerRadius
    color: Util.alpha(Color.bar.text, 0.08)
    clip: true

    Image {
      anchors.fill: parent
      visible: strip.coverSource !== ""
      sourceSize: Qt.size(strip.coverSize * 2, strip.coverSize * 2)
      fillMode: Image.PreserveAspectCrop
      source: strip.coverSource
      asynchronous: true
      smooth: true
    }

    Text {
      textFormat: Text.PlainText
      anchors.centerIn: parent
      visible: strip.coverSource === ""
      text: String.fromCodePoint(0xF075A)
      color: Color.bar.text
      font.family: Style.fontFamily
      font.pixelSize: Math.round(strip.coverSize * 0.6)
    }
  }

  Column {
    visible: strip.wide
    x: cover.x + cover.width + 10
    anchors.verticalCenter: cover.verticalCenter
    spacing: 2

    Text {
      textFormat: Text.PlainText
      width: strip.textWidth
      text: strip.media.title
      color: Color.bar.text
      font.family: Style.fontFamily
      font.pixelSize: Style.fontPx(0.95)
      font.bold: true
      elide: Text.ElideRight
    }

    Row {
      x: -5

      Glyph {
        code: strip.media.playing ? 0xF03E4 : 0xF040A
        active: !!strip.media.player && strip.media.player.canTogglePlaying
        onTriggered: strip.media.run("playPause")
      }

      Glyph {
        code: 0xF04AD
        active: !!strip.media.player && strip.media.player.canGoNext
        onTriggered: strip.media.run("next")
      }
    }
  }
}
