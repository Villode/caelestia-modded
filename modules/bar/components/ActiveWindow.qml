pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell.Services.Mpris
import QtQuick

Item {
    id: root

    required property var bar
    required property Brightness.Monitor monitor
    property color colour: Colours.palette.m3primary

    // true = lyrics mode, false = active window mode
    // Auto-switch to lyrics when music is playing, back to window when stopped
    readonly property bool hasPlayer: Players.active !== null && Players.active.isPlaying
    readonly property bool showLyrics: Config.bar.activeWindow.lyricsMode && hasPlayer && Lyrics.available
    readonly property string displayText: {
        if (showLyrics)
            return Lyrics.currentLine || Players.active?.trackTitle || "";
        return Hypr.activeToplevel?.title ?? qsTr("桌面");
    }
    readonly property string displayIcon: {
        if (showLyrics)
            return "music_note";
        return Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows");
    }

    readonly property int maxHeight: {
        const otherModules = bar.children.filter(c => c.id && c.item !== this && c.id !== "spacer");
        const otherHeight = otherModules.reduce((acc, curr) => acc + (curr.item.nonAnimHeight ?? curr.height), 0);
        return bar.height - otherHeight - bar.spacing * (bar.children.length - 1) - bar.vPadding * 2;
    }
    property Title current: text1

    clip: true
    implicitWidth: Math.max(icon.implicitWidth, current.implicitHeight)
    implicitHeight: icon.implicitHeight + current.implicitWidth + current.anchors.topMargin

    // Fetch lyrics when track changes
    Connections {
        target: Players.active

        function onPostTrackChanged(): void {
            const url = Players.active?.metadata?.["xesam:url"] ?? "";
            Lyrics.fetchForTrack(url);
        }
    }

    // Update current lyric line based on playback position
    Timer {
        running: root.showLyrics && Players.active?.isPlaying
        interval: 200
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            Players.active?.positionChanged();
            Lyrics.updateCurrentLine(Players.active?.position ?? 0);
        }
    }

    // Fetch lyrics on component load if player is already active
    Component.onCompleted: {
        if (Players.active) {
            const url = Players.active?.metadata?.["xesam:url"] ?? "";
            Lyrics.fetchForTrack(url);
        }
    }

    MaterialIcon {
        id: icon

        anchors.horizontalCenter: parent.horizontalCenter

        animate: true
        text: root.displayIcon
        color: root.showLyrics ? Colours.palette.m3tertiary : root.colour
    }

    Title {
        id: text1
    }

    Title {
        id: text2
    }

    TextMetrics {
        id: metrics

        text: root.displayText
        font.pointSize: Appearance.font.size.smaller
        font.family: Appearance.font.family.mono
        elide: Qt.ElideRight
        elideWidth: root.maxHeight - icon.height

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: root.current.text = elidedText
    }

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    component Title: StyledText {
        id: text

        anchors.horizontalCenter: icon.horizontalCenter
        anchors.top: icon.bottom
        anchors.topMargin: Appearance.spacing.small

        font.pointSize: metrics.font.pointSize
        font.family: metrics.font.family
        color: root.showLyrics ? Colours.palette.m3tertiary : root.colour
        opacity: root.current === this ? 1 : 0

        transform: [
            Translate {
                x: Config.bar.activeWindow.inverted ? -implicitWidth + text.implicitHeight : 0
            },
            Rotation {
                angle: Config.bar.activeWindow.inverted ? 270 : 90
                origin.x: text.implicitHeight / 2
                origin.y: text.implicitHeight / 2
            }
        ]

        width: implicitHeight
        height: implicitWidth

        Behavior on opacity {
            Anim {}
        }
    }
}
