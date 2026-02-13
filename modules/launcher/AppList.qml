pragma ComponentBehavior: Bound

import "items"
import "services"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property StyledTextField search
    required property PersistentProperties visibilities
    required property real maxHeight
    required property string sortMode
    required property int iconSize

    property var customCategories: []
    property var appCategoryOverrides: ({})
    property var categoryRenames: ({})

    readonly property int gridColumns: iconSize === 0 ? 8 : (iconSize === 2 ? 4 : 6)

    signal appRightClicked(var sourceItem, var entry)
    signal categoryRightClicked(var sourceItem, string catName)
    signal appDroppedOnCategory(string appId, string catName)

    readonly property bool isCategorized: state === "apps" && !search.text
    readonly property bool isAppSearch: state === "apps" && !!search.text
    readonly property var currentList: isCategorized ? grid : (isAppSearch ? searchGrid : listView)

    implicitHeight: (currentList ? currentList.implicitHeight : 0) + (isCategorized ? 50 : 0)

    state: {
        const text = search.text;
        const prefix = Config.launcher.actionPrefix;
        if (text.startsWith(prefix)) {
            for (const action of ["calc", "scheme", "variant"])
                if (text.startsWith(`${prefix}${action} `))
                    return action;

            return "actions";
        }

        return "apps";
    }

    onStateChanged: {
        if (state === "scheme" || state === "variant")
            Schemes.reload();
    }

    Column {
        id: layout
        anchors.fill: parent
        spacing: Appearance.spacing.normal
        padding: 0

        CategorizedGrid {
            id: grid
            width: parent.width
            visibilities: root.visibilities
            visible: root.isCategorized
            maxHeight: root.maxHeight
            gridColumns: root.gridColumns
            sortMode: root.sortMode
            customCategories: root.customCategories
            appCategoryOverrides: root.appCategoryOverrides
            categoryRenames: root.categoryRenames

            onAppRightClicked: (src, entry) => root.appRightClicked(src, entry)
            onCategoryRightClicked: (src, catName) => root.categoryRightClicked(src, catName)
            onAppDroppedOnCategory: (appId, catName) => root.appDroppedOnCategory(appId, catName)
        }

        // Grid view for app search results
        Flickable {
            id: searchGrid
            width: parent.width
            visible: root.isAppSearch
            clip: true
            contentWidth: width
            contentHeight: searchGridLayout.height

            readonly property int gridColumns: root.gridColumns
            readonly property int count: searchGridRepeater.count
            readonly property var currentItem: null

            implicitHeight: Math.min(520, root.maxHeight)

            function incrementCurrentIndex(): void {}
            function decrementCurrentIndex(): void {}

            Grid {
                id: searchGridLayout
                width: parent.width - Appearance.padding.normal * 2
                anchors.horizontalCenter: parent.horizontalCenter
                columns: searchGrid.gridColumns
                rowSpacing: Appearance.spacing.normal

                readonly property real cellWidth: width / columns

                Repeater {
                    id: searchGridRepeater
                    model: Apps.search(search.text)

                    delegate: Item {
                        required property var modelData
                        width: searchGridLayout.cellWidth
                        height: searchGridItem.implicitHeight

                        AppGridItem {
                            id: searchGridItem
                            appEntry: modelData
                            visibilities: root.visibilities
                            anchors.horizontalCenter: parent.horizontalCenter

                            onRightClicked: (src, entry) => root.appRightClicked(src, entry)
                        }
                    }
                }
            }

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: searchGrid
            }
        }

        StyledListView {
            id: listView

            width: parent.width
            visible: !root.isCategorized && !root.isAppSearch
            spacing: Appearance.spacing.small
            orientation: Qt.Vertical

            model: ScriptModel {
                id: scriptModel
                onValuesChanged: listView.currentIndex = 0
            }

            implicitHeight: (Config.launcher.sizes.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing

            preferredHighlightBegin: 0
            preferredHighlightEnd: height
            highlightRangeMode: ListView.ApplyRange

            highlightFollowsCurrentItem: false
            highlight: StyledRect {
                radius: Appearance.rounding.normal
                color: Colours.palette.m3onSurface
                opacity: 0.08

                y: listView.currentItem?.y ?? 0
                implicitWidth: listView.width
                implicitHeight: listView.currentItem?.implicitHeight ?? 0

                Behavior on y {
                    Anim {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }
            }

            states: [
                State {
                    name: "actions"
                    when: root.state === "actions"
                    PropertyChanges {
                        scriptModel.values: Actions.query(search.text)
                        listView.delegate: actionItem
                    }
                },
                State {
                    name: "calc"
                    when: root.state === "calc"
                    PropertyChanges {
                        scriptModel.values: [0]
                        listView.delegate: calcItem
                    }
                },
                State {
                    name: "scheme"
                    when: root.state === "scheme"
                    PropertyChanges {
                        scriptModel.values: Schemes.query(search.text)
                        listView.delegate: schemeItem
                    }
                },
                State {
                    name: "variant"
                    when: root.state === "variant"
                    PropertyChanges {
                        scriptModel.values: M3Variants.query(search.text)
                        listView.delegate: variantItem
                    }
                }
            ]

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: listView
            }

            Component {
                id: actionItem
                ActionItem {
                    list: listView
                }
            }

            Component {
                id: calcItem
                CalcItem {
                    list: listView
                }
            }

            Component {
                id: schemeItem
                SchemeItem {
                    list: listView
                }
            }

            Component {
                id: variantItem
                VariantItem {
                    list: listView
                }
            }
        }
    }
}
