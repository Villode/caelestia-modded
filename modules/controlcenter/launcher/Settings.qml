pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.normal

    SettingsHeader {
        icon: "apps"
        title: qsTr("启动器设置")
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("通用")
        description: qsTr("常规启动器设置")
    }

    SectionContainer {
        ToggleRow {
            label: qsTr("已启用")
            checked: Config.launcher.enabled
            toggle.onToggled: {
                Config.launcher.enabled = checked;
                Config.save();
            }
        }

        ToggleRow {
            label: qsTr("悬停时显示")
            checked: Config.launcher.showOnHover
            toggle.onToggled: {
                Config.launcher.showOnHover = checked;
                Config.save();
            }
        }

        ToggleRow {
            label: qsTr("Vim 快捷键")
            checked: Config.launcher.vimKeybinds
            toggle.onToggled: {
                Config.launcher.vimKeybinds = checked;
                Config.save();
            }
        }

        ToggleRow {
            label: qsTr("启用危险操作")
            checked: Config.launcher.enableDangerousActions
            toggle.onToggled: {
                Config.launcher.enableDangerousActions = checked;
                Config.save();
            }
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("显示")
        description: qsTr("显示和外观设置")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small / 2

        PropertyRow {
            label: qsTr("最多显示项目数")
            value: qsTr("%1").arg(Config.launcher.maxShown)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("最大壁纸数")
            value: qsTr("%1").arg(Config.launcher.maxWallpapers)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("拖拽阈值")
            value: qsTr("%1 像素").arg(Config.launcher.dragThreshold)
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("前缀")
        description: qsTr("命令前缀设置")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small / 2

        PropertyRow {
            label: qsTr("特殊前缀")
            value: Config.launcher.specialPrefix || qsTr("无")
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("操作前缀")
            value: Config.launcher.actionPrefix || qsTr("无")
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("模糊搜索")
        description: qsTr("模糊搜索设置")
    }

    SectionContainer {
        ToggleRow {
            label: qsTr("应用")
            checked: Config.launcher.useFuzzy.apps
            toggle.onToggled: {
                Config.launcher.useFuzzy.apps = checked;
                Config.save();
            }
        }

        ToggleRow {
            label: qsTr("操作")
            checked: Config.launcher.useFuzzy.actions
            toggle.onToggled: {
                Config.launcher.useFuzzy.actions = checked;
                Config.save();
            }
        }

        ToggleRow {
            label: qsTr("方案")
            checked: Config.launcher.useFuzzy.schemes
            toggle.onToggled: {
                Config.launcher.useFuzzy.schemes = checked;
                Config.save();
            }
        }

        ToggleRow {
            label: qsTr("变体")
            checked: Config.launcher.useFuzzy.variants
            toggle.onToggled: {
                Config.launcher.useFuzzy.variants = checked;
                Config.save();
            }
        }

        ToggleRow {
            label: qsTr("壁纸")
            checked: Config.launcher.useFuzzy.wallpapers
            toggle.onToggled: {
                Config.launcher.useFuzzy.wallpapers = checked;
                Config.save();
            }
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("大小")
        description: qsTr("启动器项目大小设置")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small / 2

        PropertyRow {
            label: qsTr("项目宽度")
            value: qsTr("%1 像素").arg(Config.launcher.sizes.itemWidth)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("项目高度")
            value: qsTr("%1 像素").arg(Config.launcher.sizes.itemHeight)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("壁纸宽度")
            value: qsTr("%1 像素").arg(Config.launcher.sizes.wallpaperWidth)
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("壁纸高度")
            value: qsTr("%1 像素").arg(Config.launcher.sizes.wallpaperHeight)
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("隐藏的应用")
        description: qsTr("从启动器隐藏的应用")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small / 2

        PropertyRow {
            label: qsTr("已隐藏总数")
            value: qsTr("%1").arg(Config.launcher.hiddenApps ? Config.launcher.hiddenApps.length : 0)
        }
    }
}
