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
    property bool lyricsVertical: true
    property Title current: text1

    clip: true
    implicitWidth: {
        if (showLyrics)
            return Math.max(icon.implicitWidth, lyricsVertical ? vertLyrics.implicitWidth : rotLyrics.implicitHeight);
        return Math.max(icon.implicitWidth, current.implicitHeight);
    }
    implicitHeight: {
        if (showLyrics) {
            const lh = lyricsVertical ? vertLyrics.implicitHeight : rotLyrics.implicitWidth;
            return icon.implicitHeight + Math.min(lh, lyricsAreaHeight) + Appearance.spacing.small;
        }
        return icon.implicitHeight + current.implicitWidth + current.anchors.topMargin;
    }

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

    // --- Lyrics display (vertical for CJK, rotated for Latin) ---
    Item {
        id: lyricsClip
        visible: root.showLyrics
        clip: true
        anchors.horizontalCenter: icon.horizontalCenter
        anchors.top: icon.bottom
        anchors.topMargin: Appearance.spacing.small
        width: root.lyricsVertical ? vertLyrics.implicitWidth : rotLyrics.implicitHeight
        height: {
            const lh = root.lyricsVertical ? vertLyrics.implicitHeight : rotLyrics.implicitWidth;
            return Math.min(lh, root.lyricsAreaHeight);
        }

        // Vertical mode (CJK)
        StyledText {
            id: vertLyrics
            visible: root.lyricsVertical
            property real scrollVal: 0
            y: -scrollVal
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            color: Colours.palette.m3tertiary
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.1
        }

        // Rotated horizontal mode (Latin)
        StyledText {
            id: rotLyrics
            visible: !root.lyricsVertical
            property real scrollVal: 0
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            color: Colours.palette.m3tertiary
            transform: [
                Translate { x: -rotLyrics.scrollVal },
                Rotation {
                    angle: 90
                    origin.x: rotLyrics.implicitHeight / 2
                    origin.y: rotLyrics.implicitHeight / 2
                }
            ]
            width: implicitHeight
            height: implicitWidth
        }

        NumberAnimation {
            id: scrollAnim
            target: root.lyricsVertical ? vertLyrics : rotLyrics
            property: "scrollVal"
            from: 0
            duration: 3000
            easing.type: Easing.Linear
        }
    }

    onDisplayTextChanged: {
        if (!showLyrics) return;
        const cjkRe = /[\u4e00-\u9fff\u3400-\u4dbf]/g;
        const cjkCount = (displayText.match(cjkRe) || []).length;
        const isCJK = cjkCount > displayText.length * 0.3;
        lyricsVertical = isCJK;

        if (isCJK) {
            const vPunct = new Map([
                ["\uFF0C", "\uFE10"], ["\u3002", "\uFE12"], ["\u3001", "\uFE11"],
                ["\uFF1A", "\uFE13"], ["\uFF1B", "\uFE14"], ["\uFF01", "\uFE15"],
                ["\uFF1F", "\uFE16"], ["\u2026", "\uFE19"], ["\u2014", "\uFE31"],
                ["\u201C", "\uFE41"], ["\u201D", "\uFE42"], ["\u2018", "\uFE43"],
                ["\u2019", "\uFE44"], ["\uFF08", "\uFE35"], ["\uFF09", "\uFE36"],
                ["\u300A", "\uFE3F"], ["\u300B", "\uFE40"],
                ["[", "\uFE47"], ["]", "\uFE48"], ["(", "\uFE35"], [")", "\uFE36"],
            ]);
            const chars = Array.from(displayText);
            const lines = [];
            for (const ch of chars) {
                if (/\s/.test(ch)) continue;
                lines.push(vPunct.has(ch) ? vPunct.get(ch) : ch);
            }
            vertLyrics.text = lines.join("\n");
            rotLyrics.text = "";
            vertLyrics.scrollVal = 0;
        } else {
            rotLyrics.text = displayText;
            vertLyrics.text = "";
            rotLyrics.scrollVal = 0;
        }
        scrollAnim.stop();

        Qt.callLater(() => {
            const overflow = isCJK
                ? vertLyrics.implicitHeight - root.lyricsAreaHeight
                : rotLyrics.implicitWidth - root.lyricsAreaHeight;
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
