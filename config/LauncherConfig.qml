import Quickshell.Io

JsonObject {
    property bool enabled: true
    property bool showOnHover: false
    property int maxShown: 7
    property int maxWallpapers: 9 // Warning: even numbers look bad
    property string specialPrefix: "@"
    property string actionPrefix: ">"
    property bool enableDangerousActions: false // Allow actions that can cause losing data, like shutdown, reboot and logout
    property int dragThreshold: 50
    property bool vimKeybinds: false
    property list<string> favouriteApps: []
    property list<string> hiddenApps: []
    property list<string> customCategories: []
    property string categoryRenamesJson: "{}"
    property string appCategoryOverridesJson: "{}"
    property string sortMode: "name"
    property int iconSize: 1
    property UseFuzzy useFuzzy: UseFuzzy {}
    property Sizes sizes: Sizes {}

    component UseFuzzy: JsonObject {
        property bool apps: false
        property bool actions: false
        property bool schemes: false
        property bool variants: false
        property bool wallpapers: false
    }

    component Sizes: JsonObject {
        property int itemWidth: 600
        property int itemHeight: 57
        property int wallpaperWidth: 280
        property int wallpaperHeight: 200
    }

    property list<var> actions: [
        {
            name: "计算器",
            icon: "calculate",
            description: "简单数学计算（由 Qalc 提供）",
            command: ["autocomplete", "calc"],
            enabled: true,
            dangerous: false
        },
        {
            name: "配色方案",
            icon: "palette",
            description: "更改当前配色方案",
            command: ["autocomplete", "scheme"],
            enabled: true,
            dangerous: false
        },
        {
            name: "壁纸",
            icon: "image",
            description: "更改当前壁纸",
            command: ["autocomplete", "wallpaper"],
            enabled: true,
            dangerous: false
        },
        {
            name: "变体",
            icon: "colors",
            description: "更改当前方案变体",
            command: ["autocomplete", "variant"],
            enabled: true,
            dangerous: false
        },
        {
            name: "透明度",
            icon: "opacity",
            description: "更改 Shell 透明度",
            command: ["autocomplete", "transparency"],
            enabled: false,
            dangerous: false
        },
        {
            name: "随机",
            icon: "casino",
            description: "切换到随机壁纸",
            command: ["caelestia", "wallpaper", "-r"],
            enabled: true,
            dangerous: false
        },
        {
            name: "亮色",
            icon: "light_mode",
            description: "切换为亮色模式",
            command: ["setMode", "light"],
            enabled: true,
            dangerous: false
        },
        {
            name: "深色",
            icon: "dark_mode",
            description: "切换为深色模式",
            command: ["setMode", "dark"],
            enabled: true,
            dangerous: false
        },
        {
            name: "关机",
            icon: "power_settings_new",
            description: "关闭系统",
            command: ["systemctl", "poweroff"],
            enabled: true,
            dangerous: true
        },
        {
            name: "重启",
            icon: "cached",
            description: "重启系统",
            command: ["systemctl", "reboot"],
            enabled: true,
            dangerous: true
        },
        {
            name: "注销",
            icon: "exit_to_app",
            description: "退出当前会话",
            command: ["loginctl", "terminate-user", ""],
            enabled: true,
            dangerous: true
        },
        {
            name: "Lock",
            icon: "lock",
            description: "Lock the current session",
            command: ["loginctl", "lock-session"],
            enabled: true,
            dangerous: false
        },
        {
            name: "Sleep",
            icon: "bedtime",
            description: "Suspend then hibernate",
            command: ["systemctl", "suspend-then-hibernate"],
            enabled: true,
            dangerous: false
        },
        {
            name: "Settings",
            icon: "settings",
            description: "Configure the shell",
            command: ["caelestia", "shell", "controlCenter", "open"],
            enabled: true,
            dangerous: false
        }
    ]
}
