pragma ComponentBehavior: Bound

import ".."
import "../effects"
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Elevation {
    id: root

    property list<MenuItem> items
    property MenuItem active: items[0] ?? null
    property bool expanded
    property bool blurBackground: false

    signal itemSelected(item: MenuItem)

    radius: Appearance.rounding.normal
    level: 2

    implicitWidth: Math.max(root.minWidth, column.implicitWidth)
    property int minWidth: 200
    implicitHeight: root.expanded ? column.implicitHeight : 0
    opacity: root.expanded ? 1 : 0

    StyledClippingRect {
        anchors.fill: parent
        radius: parent.radius
        color: root.blurBackground && Colours.transparency.enabled
            ? Qt.alpha(Colours.palette.m3surfaceContainer, Colours.transparency.base + 0.15)
            : Colours.palette.m3surfaceContainer

        ColumnLayout {
            id: column

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

            Repeater {
                model: root.items

                StyledRect {
                    id: item

                    required property int index
                    required property MenuItem modelData
                    readonly property bool active: modelData === root.active

                    Layout.fillWidth: true
                    implicitWidth: menuOptionRow.implicitWidth + Appearance.padding.normal * 2
                    implicitHeight: menuOptionRow.implicitHeight + Appearance.padding.normal * 2

                    color: Qt.alpha(Colours.palette.m3secondaryContainer, active ? 1 : 0)

                    StateLayer {
                        color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        disabled: !root.expanded

                        function onClicked(): void {
                            root.itemSelected(item.modelData);
                            root.active = item.modelData;
                            root.expanded = false;
                        }
                    }

                    RowLayout {
                        id: menuOptionRow

                        anchors.fill: parent
                        anchors.margins: Appearance.padding.normal
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            Layout.alignment: Qt.AlignVCenter
                            text: item.modelData.icon
                            color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                            text: item.modelData.text
                            color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        }

                        Loader {
                            Layout.alignment: Qt.AlignVCenter
                            active: item.modelData.trailingIcon.length > 0
                            visible: active

                            sourceComponent: MaterialIcon {
                                text: item.modelData.trailingIcon
                                color: item.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            }
                        }
                    }
                }
            }
        }
    }

    Behavior on opacity {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
        }
    }

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }
}
