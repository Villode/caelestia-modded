pragma ComponentBehavior: Bound

import "items"
import "services"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick

Flickable {
    id: root

    required property PersistentProperties visibilities
    property real maxHeight: 520
    property int preferredRows: 5
    property int gridColumns: 6
    property string sortMode: "name"
    property var customCategories: []
    property var appCategoryOverrides: ({})
    property var categoryRenames: ({})

    signal appRightClicked(var sourceItem, var entry)
    signal categoryRightClicked(var sourceItem, string catName)
    signal appDroppedOnCategory(string appId, string catName)

    readonly property var categoryData: Apps.categorized(customCategories, appCategoryOverrides, categoryRenames)
    property string selectedCategory: categoryData.length > 0 ? categoryData[0].label : ""

    contentWidth: width
    contentHeight: mainCol.height
    clip: true

    implicitHeight: mainCol.implicitHeight > 0 ? Math.min(520, maxHeight) : 0

    Column {
        id: mainCol
        width: parent.width
        spacing: Appearance.spacing.small

        // Category Pill Bar
        Flickable {
            id: tabFlick
            width: parent.width
            height: 36
            contentWidth: tabRow.width + Appearance.padding.normal * 2
            clip: true
            interactive: true
            flickableDirection: Flickable.HorizontalFlick

            Row {
                id: tabRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Appearance.padding.normal
                spacing: Appearance.spacing.small

                Repeater {
                    model: root.categoryData
                    delegate: StyledRect {
                        id: tabPill

                        required property var modelData
                        required property int index

                        readonly property bool isSelected: root.selectedCategory === modelData.label

                        width: tabLabel.implicitWidth + Appearance.padding.large
                        height: 32
                        radius: 16
                        color: isSelected
                            ? Colours.palette.m3primary
                            : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                        opacity: isSelected ? 1.0 : 0.8

                        StyledText {
                            id: tabLabel
                            text: modelData.label
                            anchors.centerIn: parent
                            color: tabPill.isSelected
                                ? Colours.palette.m3onPrimary
                                : Colours.palette.m3onSurfaceVariant
                            font.pointSize: Appearance.font.size.smaller
                            font.weight: tabPill.isSelected ? 600 : 400
                        }

                        StateLayer {
                            radius: 16
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            function onClicked(event): void {
                                if (event && event.button === Qt.RightButton) {
                                    if (modelData.label !== "全部应用") {
                                        root.categoryRightClicked(tabPill, modelData.label);
                                    }
                                } else {
                                    root.selectedCategory = modelData.label;
                                }
                            }
                        }
                    }
                }
            }
        }

        // App Icon Grid
        Grid {
            id: appGrid
            width: parent.width - Appearance.padding.normal * 2
            anchors.horizontalCenter: parent.horizontalCenter
            columns: root.gridColumns
            rowSpacing: Appearance.spacing.normal

            readonly property real cellWidth: width / columns

            readonly property var currentApps: {
                let apps = [];
                for (const cat of root.categoryData) {
                    if (cat.label === root.selectedCategory) {
                        apps = cat.apps.slice();
                        break;
                    }
                }
                if (root.sortMode === "name") {
                    apps.sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""));
                }
                return apps;
            }

            Repeater {
                model: appGrid.currentApps

                delegate: Item {
                    required property var modelData
                    width: appGrid.cellWidth
                    height: gridItem.implicitHeight

                    AppGridItem {
                        id: gridItem
                        appEntry: modelData
                        visibilities: root.visibilities
                        anchors.horizontalCenter: parent.horizontalCenter

                        onRightClicked: (src, entry) => root.appRightClicked(src, entry)
                    }
                }
            }
        }
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }
}
