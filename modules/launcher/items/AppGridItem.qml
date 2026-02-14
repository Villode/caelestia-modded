import "../services"
import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property var appEntry
    required property PersistentProperties visibilities
    property int iconSize: 1  // 0=small, 1=medium, 2=large

    signal rightClicked(var sourceItem, var entry)

    readonly property int iconBoxSize: iconSize === 0 ? 44 : (iconSize === 2 ? 72 : 56)
    readonly property int iconImgSize: iconSize === 0 ? 32 : (iconSize === 2 ? 52 : 40)
    readonly property int labelWidth: iconSize === 0 ? 60 : (iconSize === 2 ? 96 : 76)

    implicitWidth: labelWidth + 4
    implicitHeight: iconCol.implicitHeight + Appearance.padding.normal

    width: implicitWidth
    height: implicitHeight
    visible: !!appEntry

    Column {
        id: iconCol

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Appearance.padding.small
        spacing: Appearance.spacing.small

        Item {
            id: iconWrapper

            width: root.iconBoxSize
            height: root.iconBoxSize
            anchors.horizontalCenter: parent.horizontalCenter

            StyledRect {
                anchors.fill: parent
                radius: Appearance.rounding.normal
                color: Colours.layer(Colours.palette.m3surfaceContainer, 4)
            }

            IconImage {
                id: icon

                source: Quickshell.iconPath(root.appEntry?.icon, root.appEntry?.icon)
                width: root.iconImgSize
                height: root.iconImgSize
                anchors.centerIn: parent
                asynchronous: true
            }

            StateLayer {
                radius: Appearance.rounding.normal
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                function onClicked(event): void {
                    if (event && event.button === Qt.RightButton) {
                        root.rightClicked(root, root.appEntry);
                    } else {
                        Apps.launch(root.appEntry);
                        root.visibilities.launcher = false;
                    }
                }
            }
        }

        StyledText {
            text: root.appEntry?.name ?? ""
            font.pointSize: Appearance.font.size.smaller
            color: Colours.palette.m3onSurface
            elide: Text.ElideRight
            width: root.labelWidth
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 1
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
