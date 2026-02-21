import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var wrapper

    readonly property var monitor: Brightness.getMonitorForScreen(Quickshell.screens[0])
    readonly property real currentBrightness: monitor?.brightness ?? 0.5

    implicitWidth: layout.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: layout.implicitHeight + Appearance.padding.normal * 2

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.normal

        StyledText {
            text: qsTr("亮度 (%1%)").arg(Math.round(root.currentBrightness * 100))
            font.weight: 500
        }

        CustomMouseArea {
            Layout.fillWidth: true
            implicitHeight: Appearance.padding.normal * 3

            onWheel: event => {
                if (event.angleDelta.y > 0)
                    Brightness.increaseBrightness();
                else if (event.angleDelta.y < 0)
                    Brightness.decreaseBrightness();
            }

            StyledSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: parent.implicitHeight

                value: root.currentBrightness
                onMoved: root.monitor?.setBrightness(value)

                Behavior on value {
                    Anim {}
                }
            }
        }
    }
}
