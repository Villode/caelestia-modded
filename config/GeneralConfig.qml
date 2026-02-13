import Quickshell.Io

JsonObject {
    property string logo: ""
    property Apps apps: Apps {}
    property Idle idle: Idle {}
    property Battery battery: Battery {}

    component Apps: JsonObject {
        property list<string> terminal: ["foot"]
        property list<string> audio: ["pavucontrol"]
        property list<string> playback: ["mpv"]
        property list<string> explorer: ["thunar"]
    }

    component Idle: JsonObject {
        property bool lockBeforeSleep: true
        property bool inhibitWhenAudio: true
        property list<var> timeouts: [
            {
                timeout: 180,
                idleAction: "lock"
            },
            {
                timeout: 300,
                idleAction: "dpms off",
                returnAction: "dpms on"
            },
            {
                timeout: 600,
                idleAction: ["systemctl", "suspend-then-hibernate"]
            }
        ]
    }

    component Battery: JsonObject {
        property list<var> warnLevels: [
            {
                level: 20,
                title: qsTr("电池电量低"),
                message: qsTr("建议插入充电器"),
                icon: "battery_android_frame_2"
            },
            {
                level: 10,
                title: qsTr("你看到之前的消息了吗？"),
                message: qsTr("建议<b>立即</b>插入充电器"),
                icon: "battery_android_frame_1"
            },
            {
                level: 5,
                title: qsTr("电池电量严重不足"),
                message: qsTr("请立即插入充电器！！"),
                icon: "battery_android_alert",
                critical: true
            },
        ]
        property int criticalLevel: 3
    }
}
