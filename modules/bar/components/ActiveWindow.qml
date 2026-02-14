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
    readonly property real lyricsAreaHeight: maxHeight - icon.implicitHeight - Appearance.spacing.small
    property Title current: text1

    clip: true
    implicitWidth: Math.max(icon.implicitWidth, showLyrics ? lyricsLabel.implicitWidth : current.implicitHeight)
    implicitHeight: showLyrics
        ? icon.implicitHeight + Math.min(lyricsLabel.implicitHeight, lyricsAreaHeight) + Appearance.spacing.small
        : icon.implicitHeight + current.implicitWidth + current.anchors.topMargin

    Connections {
        target: Players.active
        function onPostTrackChanged(): void {
            const url = Players.active?.metadata?.["xesam:url"] ?? "";
            Lyrics.fetchForTrack(url);
        }
    }

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

    // --- Rotated title for active window mode ---
    Title { id: text1; visible: !root.showLyrics }
    Title { id: text2; visible: !root.showLyrics }

    TextMetrics {
        id: metrics
        text: root.showLyrics ? "" : root.displayText
        font.pointSize: Appearance.font.size.smaller
        font.family: Appearance.font.family.mono
        elide: Qt.ElideRight
        elideWidth: root.maxHeight - icon.height
        onTextChanged: {
            if (root.showLyrics) return;
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: {
            if (!root.showLyrics) root.current.text = elidedText;
        }
    }

    // --- Vertical lyrics with scroll ---
    Item {
        id: lyricsClip
        visible: root.showLyrics
        clip: true
        anchors.horizontalCenter: icon.horizontalCenter
        anchors.top: icon.bottom
        anchors.topMargin: Appearance.spacing.small
        width: lyricsLabel.implicitWidth
        height: Math.min(lyricsLabel.implicitHeight, root.lyricsAreaHeight)

        StyledText {
            id: lyricsLabel
            property real scrollY: 0

            y: -scrollY
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            color: Colours.palette.m3tertiary
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.1
        }

        // Scroll animation when text overflows
        NumberAnimation {
            id: scrollAnim
            target: lyricsLabel
            property: "scrollY"
            from: 0
            duration: 3000
            easing.type: Easing.Linear
        }
    }

    onDisplayTextChanged: {
        if (!showLyrics) return;
        // Vertical punctuation mapping (horizontal to vertical form)
        const vPunct = new Map([
            ["\uFF0C", "\uFE10"], // ， → ︐
            ["\u3002", "\uFE12"], // 。 → ︒
            ["\u3001", "\uFE11"], // 、 → ︑
            ["\uFF1A", "\uFE13"], // ： → ︓
            ["\uFF1B", "\uFE14"], // ； → ︔
            ["\uFF01", "\uFE15"], // ！ → ︕
            ["\uFF1F", "\uFE16"], // ？ → ︖
            ["\u2026", "\uFE19"], // … → ︙
            ["\u2014", "\uFE31"], // — → ︱
            ["\u201C", "\uFE41"], // " → ﹁
            ["\u201D", "\uFE42"], // " → ﹂
            ["\u2018", "\uFE43"], // ' → ﹃
            ["\u2019", "\uFE44"], // ' → ﹄
            ["\uFF08", "\uFE35"], // （ → ︵
            ["\uFF09", "\uFE36"], // ） → ︶
            ["\u300A", "\uFE3F"], // 《 → ︿
            ["\u300B", "\uFE40"], // 》 → ﹀
            ["[", "\uFE47"],      // [ → ﹇
            ["]", "\uFE48"],      // ] → ﹈
            ["(", "\uFE35"],      // ( → ︵
            [")", "\uFE36"],      // ) → ︶
        ]);
        const chars = Array.from(displayText);
        const lines = [];
        for (const ch of chars) {
            if (/\s/.test(ch)) continue;
            lines.push(vPunct.has(ch) ? vPunct.get(ch) : ch);
        }
        lyricsLabel.text = lines.join("\n");
        lyricsLabel.scrollY = 0;
        scrollAnim.stop();

        Qt.callLater(() => {
            const overflow = lyricsLabel.implicitHeight - root.lyricsAreaHeight;
            if (overflow > 0) {
                scrollAnim.to = overflow;
                const dur = Lyrics.currentLineDuration;
                scrollAnim.duration = Math.max(dur > 0 ? dur * 1000 * 0.8 : 3000, 1500);
                scrollAnim.start();
            }
        });
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
        color: root.colour
        opacity: root.current === this ? 1 : 0
        transform: [
            Translate { x: Config.bar.activeWindow.inverted ? -implicitWidth + text.implicitHeight : 0 },
            Rotation {
                angle: Config.bar.activeWindow.inverted ? 270 : 90
                origin.x: text.implicitHeight / 2
                origin.y: text.implicitHeight / 2
            }
        ]
        width: implicitHeight
        height: implicitWidth
        Behavior on opacity { Anim {} }
    }
}
