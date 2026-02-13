import qs.components
import qs.services
import qs.config
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property HyprlandToplevel client

    anchors.fill: parent
    spacing: Appearance.spacing.small

    Label {
        Layout.topMargin: Appearance.padding.large * 2

        text: root.client?.title ?? qsTr("无活动窗口")
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

        font.pointSize: Appearance.font.size.large
        font.weight: 500
    }

    Label {
        text: root.client?.lastIpcObject.class ?? qsTr("无活动窗口")
        color: Colours.palette.m3tertiary

        font.pointSize: Appearance.font.size.larger
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.leftMargin: Appearance.padding.large * 2
        Layout.rightMargin: Appearance.padding.large * 2
        Layout.topMargin: Appearance.spacing.normal
        Layout.bottomMargin: Appearance.spacing.large

        color: Colours.palette.m3secondary
    }

    Detail {
        icon: "location_on"
        text: qsTr("地址: %1").arg(`0x${root.client?.address}` ?? "unknown")
        color: Colours.palette.m3primary
    }

    Detail {
        icon: "location_searching"
        text: qsTr("位置: %1, %2").arg(root.client?.lastIpcObject.at[0] ?? -1).arg(root.client?.lastIpcObject.at[1] ?? -1)
    }

    Detail {
        icon: "resize"
        text: qsTr("大小: %1 x %2").arg(root.client?.lastIpcObject.size[0] ?? -1).arg(root.client?.lastIpcObject.size[1] ?? -1)
        color: Colours.palette.m3tertiary
    }

    Detail {
        icon: "workspaces"
        text: qsTr("工作区: %1 (%2)").arg(root.client?.workspace.name ?? -1).arg(root.client?.workspace.id ?? -1)
        color: Colours.palette.m3secondary
    }

    Detail {
        icon: "desktop_windows"
        text: {
            const mon = root.client?.monitor;
            if (mon)
                return qsTr("显示器: %1 (%2) 位置 %3, %4").arg(mon.name).arg(mon.id).arg(mon.x).arg(mon.y);
            return qsTr("显示器: 未知");
        }
    }

    Detail {
        icon: "page_header"
        text: qsTr("初始标题: %1").arg(root.client?.lastIpcObject.initialTitle ?? "unknown")
        color: Colours.palette.m3tertiary
    }

    Detail {
        icon: "category"
        text: qsTr("初始类: %1").arg(root.client?.lastIpcObject.initialClass ?? "unknown")
    }

    Detail {
        icon: "account_tree"
        text: qsTr("进程 ID: %1").arg(root.client?.lastIpcObject.pid ?? -1)
        color: Colours.palette.m3primary
    }

    Detail {
        icon: "picture_in_picture_center"
        text: qsTr("浮动: %1").arg(root.client?.lastIpcObject.floating ? "yes" : "no")
        color: Colours.palette.m3secondary
    }

    Detail {
        icon: "gradient"
        text: qsTr("Xwayland: %1").arg(root.client?.lastIpcObject.xwayland ? "yes" : "no")
    }

    Detail {
        icon: "keep"
        text: qsTr("固定: %1").arg(root.client?.lastIpcObject.pinned ? "yes" : "no")
        color: Colours.palette.m3secondary
    }

    Detail {
        icon: "fullscreen"
        text: {
            const fs = root.client?.lastIpcObject.fullscreen;
            if (fs)
                return qsTr("全屏状态: %1").arg(fs == 0 ? "off" : fs == 1 ? "maximised" : "on");
            return qsTr("全屏状态: 未知");
        }
        color: Colours.palette.m3tertiary
    }

    Item {
        Layout.fillHeight: true
    }

    component Detail: RowLayout {
        id: detail

        required property string icon
        required property string text
        property alias color: icon.color

        Layout.leftMargin: Appearance.padding.large
        Layout.rightMargin: Appearance.padding.large
        Layout.fillWidth: true

        spacing: Appearance.spacing.smaller

        MaterialIcon {
            id: icon

            Layout.alignment: Qt.AlignVCenter
            text: detail.icon
        }

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            text: detail.text
            elide: Text.ElideRight
            font.pointSize: Appearance.font.size.normal
        }
    }

    component Label: StyledText {
        Layout.leftMargin: Appearance.padding.large
        Layout.rightMargin: Appearance.padding.large
        Layout.fillWidth: true
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        animate: true
    }
}
