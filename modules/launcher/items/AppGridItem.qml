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

    signal rightClicked(var sourceItem, var entry)

    implicitWidth: 80
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

            width: 56
            height: 56
            anchors.horizontalCenter: parent.horizontalCenter

            StyledRect {
                anchors.fill: parent
                radius: Appearance.rounding.normal
                color: Colours.layer(Colours.palette.m3surfaceContainer, 4)
            }

            IconImage {
                id: icon

                source: Quickshell.iconPath(root.appEntry?.icon, root.appEntry?.icon)
                width: 40
                height: 40
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
            width: 76
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 1
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
