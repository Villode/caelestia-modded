pragma ComponentBehavior: Bound

import "services"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets

Item {
    id: root

    required property PersistentProperties visibilities
    required property var panels
    required property real maxHeight

    readonly property int padding: Appearance.padding.large
    readonly property int rounding: Appearance.rounding.large

    // Persistent menu state
    readonly property PersistentProperties launcherPrefs: PersistentProperties {
        id: prefs
        reloadableId: "launcherPrefs"
    }

    property string sortMode: Config.launcher.sortMode
    property int iconSize: Config.launcher.iconSize

    // Custom categories and overrides - read from Config (file-persisted)
    readonly property var customCategories: Config.launcher.customCategories ?? []
    readonly property var appCategoryOverrides: {
        try { return JSON.parse(Config.launcher.appCategoryOverridesJson || "{}"); } catch(e) { return {}; }
    }
    readonly property var categoryRenames: {
        try { return JSON.parse(Config.launcher.categoryRenamesJson || "{}"); } catch(e) { return {}; }
    }

    function addCustomCategory(name: string): void {
        const cats = [...customCategories];
        if (!cats.includes(name)) {
            cats.push(name);
            Config.launcher.customCategories = cats;
            Config.save();
        }
    }

    function renameCategory(oldName: string, newName: string): void {
        // Update custom categories list
        const cats = [...customCategories];
        const idx = cats.indexOf(oldName);
        if (idx !== -1) cats[idx] = newName;
        Config.launcher.customCategories = cats;

        // Update category renames (built-in category display name mapping)
        const renames = Object.assign({}, categoryRenames);
        let originalKey = null;
        for (const k in renames) {
            if (renames[k] === oldName) { originalKey = k; break; }
        }
        const builtIns = ["效率与财务", "娱乐", "社交", "工具", "创意", "其他"];
        if (originalKey) {
            renames[originalKey] = newName;
        } else if (builtIns.includes(oldName)) {
            renames[oldName] = newName;
        }
        Config.launcher.categoryRenamesJson = JSON.stringify(renames);

        // Update overrides that point to old name
        const overrides = Object.assign({}, appCategoryOverrides);
        for (const appId in overrides) {
            if (overrides[appId] === oldName) overrides[appId] = newName;
        }
        Config.launcher.appCategoryOverridesJson = JSON.stringify(overrides);
        Config.save();
    }

    function deleteCategory(name: string): void {
        const cats = customCategories.filter(c => c !== name);
        Config.launcher.customCategories = cats;

        const renames = Object.assign({}, categoryRenames);
        for (const k in renames) {
            if (renames[k] === name) delete renames[k];
        }
        Config.launcher.categoryRenamesJson = JSON.stringify(renames);

        const overrides = Object.assign({}, appCategoryOverrides);
        for (const appId in overrides) {
            if (overrides[appId] === name) delete overrides[appId];
        }
        Config.launcher.appCategoryOverridesJson = JSON.stringify(overrides);
        Config.save();
    }

    function moveAppToCategory(appId: string, categoryName: string): void {
        const overrides = Object.assign({}, appCategoryOverrides);
        if (categoryName === "") {
            delete overrides[appId];
        } else {
            overrides[appId] = categoryName;
        }
        Config.launcher.appCategoryOverridesJson = JSON.stringify(overrides);
        Config.save();
    }

    onSortModeChanged: {
        Config.launcher.sortMode = sortMode;
        Config.save();
    }
    onIconSizeChanged: {
        Config.launcher.iconSize = iconSize;
        Config.save();
    }

    // App context menu state
    property var contextMenuApp: null
    property real contextMenuX: 0
    property real contextMenuY: 0
    property bool showingHiddenApps: false

    // Category context menu state
    property string contextCategoryName: ""
    property real catMenuX: 0
    property real catMenuY: 0

    // Input dialog state
    property bool showInputDialog: false
    property string inputDialogTitle: ""
    property string inputDialogValue: ""
    property var inputDialogCallback: null

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: searchWrapper.height + listWrapper.height + padding * 2

    Item {
        id: listWrapper

        implicitWidth: list.width
        implicitHeight: list.height + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: searchWrapper.bottom
        anchors.topMargin: 0

        visible: !root.showingHiddenApps

        ContentList {
            id: list

            content: root
            visibilities: root.visibilities
            panels: root.panels
            maxHeight: root.maxHeight - searchWrapper.implicitHeight - root.padding * 3
            search: search
            padding: root.padding
            rounding: root.rounding
            sortMode: root.sortMode
            iconSize: root.iconSize
            customCategories: root.customCategories
            appCategoryOverrides: root.appCategoryOverrides
            categoryRenames: root.categoryRenames

            onAppRightClicked: (src, entry) => root.showAppContextMenu(src, entry)
            onCategoryRightClicked: (src, catName) => root.showCategoryContextMenu(src, catName)
            onAppDroppedOnCategory: (appId, catName) => root.moveAppToCategory(appId, catName)
        }
    }

    // Hidden apps view
    Item {
        id: hiddenAppsWrapper

        visible: root.showingHiddenApps
        anchors.top: searchWrapper.bottom
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.right: parent.right

        implicitHeight: hiddenCol.implicitHeight + root.padding

        Column {
            id: hiddenCol
            width: parent.width
            spacing: Appearance.spacing.small

            // Back button row
            Row {
                spacing: Appearance.spacing.small
                leftPadding: root.padding

                MaterialIcon {
                    text: "arrow_back"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: 18
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showingHiddenApps = false
                    }
                }

                StyledText {
                    text: qsTr("隐藏的应用")
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 500
                    color: Colours.palette.m3onSurface
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Hidden apps grid
            Flickable {
                width: parent.width
                height: Math.min(root.maxHeight - searchWrapper.implicitHeight - root.padding * 3 - 40, hiddenGrid.implicitHeight)
                contentHeight: hiddenGrid.implicitHeight
                clip: true

                Grid {
                    id: hiddenGrid
                    width: parent.width - Appearance.padding.normal * 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: root.iconSize === 0 ? 8 : (root.iconSize === 2 ? 4 : 6)
                    rowSpacing: Appearance.spacing.normal

                    readonly property real cellWidth: width / columns
                    readonly property var hiddenEntries: {
                        const ids = Config.launcher.hiddenApps ?? [];
                        const all = DesktopEntries.applications.values;
                        return all.filter(a => ids.includes(a.id));
                    }

                    Repeater {
                        model: hiddenGrid.hiddenEntries

                        delegate: Item {
                            required property var modelData
                            width: hiddenGrid.cellWidth
                            height: hiddenItem.implicitHeight

                            Column {
                                id: hiddenItem
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: Appearance.spacing.small

                                Item {
                                    width: 56
                                    height: 56
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    StyledRect {
                                        anchors.fill: parent
                                        radius: Appearance.rounding.normal
                                        color: Colours.layer(Colours.palette.m3surfaceContainer, 4)
                                        opacity: 0.6
                                    }

                                    IconImage {
                                        source: Quickshell.iconPath(modelData?.icon, modelData?.icon)
                                        width: 40
                                        height: 40
                                        anchors.centerIn: parent
                                        asynchronous: true
                                        opacity: 0.6
                                    }

                                    // Restore overlay
                                    StateLayer {
                                        radius: Appearance.rounding.normal

                                        function onClicked(): void {
                                            const appId = modelData?.id ?? "";
                                            const hiddenApps = [...(Config.launcher.hiddenApps ?? [])];
                                            const idx = hiddenApps.indexOf(appId);
                                            if (idx !== -1) hiddenApps.splice(idx, 1);
                                            Config.launcher.hiddenApps = hiddenApps;
                                            Config.save();
                                            if (hiddenApps.length === 0) root.showingHiddenApps = false;
                                        }
                                    }
                                }

                                StyledText {
                                    text: modelData?.name ?? ""
                                    font.pointSize: Appearance.font.size.smaller
                                    color: Colours.palette.m3onSurface
                                    opacity: 0.6
                                    elide: Text.ElideRight
                                    width: 76
                                    horizontalAlignment: Text.AlignHCenter
                                    maximumLineCount: 1
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }
                }

                // Empty state
                Column {
                    visible: (hiddenGrid.hiddenEntries?.length ?? 0) === 0
                    anchors.centerIn: parent
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: "visibility"
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.extraLarge
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    StyledText {
                        text: qsTr("没有隐藏的应用")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.normal
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    StyledRect {
        id: searchWrapper

        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Appearance.rounding.full

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.padding

        implicitHeight: 56

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.padding
            anchors.rightMargin: root.padding
            spacing: Appearance.spacing.small

            Image {
                id: searchIcon
                source: `${Quickshell.shellDir}/assets/appstore.svg`
                sourceSize.width: 24
                sourceSize.height: 24
                Layout.alignment: Qt.AlignVCenter

                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: Colours.palette.m3primary
                }
            }

            StyledTextField {
                id: search
                Layout.fillWidth: true
                
                placeholderText: search.text ? "" : qsTr("应用程序")
                
                leftPadding: Appearance.spacing.small
                topPadding: 0
                bottomPadding: 0

                onAccepted: {
                    const currentItem = list.currentList?.currentItem;
                    if (currentItem) {
                        if (list.showWallpapers) {
                            if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                                Wallpapers.previewColourLock = true;
                            Wallpapers.setWallpaper(currentItem.modelData.path);
                            root.visibilities.launcher = false;
                        } else if (text.startsWith(Config.launcher.actionPrefix)) {
                            if (text.startsWith(`${Config.launcher.actionPrefix}calc `))
                                currentItem.onClicked();
                            else
                                currentItem.modelData.onClicked(list.currentList);
                        } else {
                            Apps.launch(currentItem.modelData);
                            root.visibilities.launcher = false;
                        }
                    }
                }

                Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
                Keys.onDownPressed: list.currentList?.incrementCurrentIndex()
                Keys.onEscapePressed: root.visibilities.launcher = false

                Keys.onPressed: event => {
                    if (!Config.launcher.vimKeybinds)
                        return;

                    if (event.modifiers & Qt.ControlModifier) {
                        if (event.key === Qt.Key_J) {
                            list.currentList?.incrementCurrentIndex();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_K) {
                            list.currentList?.decrementCurrentIndex();
                            event.accepted = true;
                        }
                    } else if (event.key === Qt.Key_Tab) {
                        list.currentList?.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                        list.currentList?.decrementCurrentIndex();
                        event.accepted = true;
                    }
                }

                Component.onCompleted: forceActiveFocus()

                Connections {
                    target: root.visibilities

                    function onLauncherChanged(): void {
                        if (!root.visibilities.launcher) {
                            search.text = "";
                            launcherMenu.expanded = false;
                            appContextMenu.expanded = false;
                            moveToCatMenu.visible = false;
                            catContextMenu.expanded = false;
                            root.showingHiddenApps = false;
                            root.showInputDialog = false;
                        }
                    }

                    function onSessionChanged(): void {
                        if (!root.visibilities.session)
                            search.forceActiveFocus();
                    }
                }
            }

            MaterialIcon {
                id: clearIcon
                text: "close"
                color: Colours.palette.m3onSurfaceVariant
                visible: !!search.text
                font.pointSize: 18
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: search.text = ""
                }
            }

            MaterialIcon {
                id: menuIcon
                text: "more_horiz"
                font.pointSize: 24
                color: Colours.palette.m3onSurfaceVariant
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: launcherMenu.expanded = !launcherMenu.expanded
                }
            }
        }
    }

    // Dismiss overlay for dropdown menu
    MouseArea {
        anchors.fill: parent
        z: 99
        visible: launcherMenu.expanded
        onClicked: launcherMenu.expanded = false
    }

    // Dropdown menu
    Menu {
        id: launcherMenu

        anchors.top: searchWrapper.bottom
        anchors.right: searchWrapper.right
        anchors.topMargin: Appearance.spacing.small
        anchors.rightMargin: root.padding

        z: 100
        expanded: false
        blurBackground: true

        items: [
            menuSortName,
            menuSortFreq,
            menuIconSmall,
            menuIconMedium,
            menuIconLarge,
            menuNewCategory,
            menuWallpaper,
            menuHidden,
            menuSettings
        ]

        active: root.sortMode === "name" ? menuSortName : menuSortFreq

        onItemSelected: item => {
            if (item === menuSortName) root.sortMode = "name";
            else if (item === menuSortFreq) root.sortMode = "frequency";
            else if (item === menuIconSmall) root.iconSize = 0;
            else if (item === menuIconMedium) root.iconSize = 1;
            else if (item === menuIconLarge) root.iconSize = 2;
            else if (item === menuNewCategory) {
                root.showInputDialogFor("新建分类", "", function(name) {
                    if (name.trim()) root.addCustomCategory(name.trim());
                });
                launcherMenu.expanded = false;
            }
            else if (item === menuWallpaper) {
                search.text = `${Config.launcher.actionPrefix}wallpaper `;
                launcherMenu.expanded = false;
            }
            else if (item === menuHidden) {
                root.showingHiddenApps = true;
                launcherMenu.expanded = false;
            }
            else if (item === menuSettings) {
                Quickshell.execDetached({command: ["caelestia", "shell", "controlCenter", "open"]});
                root.visibilities.launcher = false;
            }
        }
    }

    // Show app context menu
    function showAppContextMenu(sourceItem: var, entry: var): void {
        contextMenuApp = entry;
        const pos = sourceItem.mapToItem(root, sourceItem.width / 2, sourceItem.height);
        contextMenuX = pos.x;
        contextMenuY = pos.y;
        appContextMenu.expanded = true;
        launcherMenu.expanded = false;
    }

    MenuItem { id: menuSortName; text: "按名称排序"; icon: "sort_by_alpha" }
    MenuItem { id: menuSortFreq; text: "按使用频率"; icon: "trending_up" }
    MenuItem { id: menuIconSmall; text: "小图标"; icon: "grid_on"; trailingIcon: root.iconSize === 0 ? "check" : "" }
    MenuItem { id: menuIconMedium; text: "中图标"; icon: "grid_view"; trailingIcon: root.iconSize === 1 ? "check" : "" }
    MenuItem { id: menuIconLarge; text: "大图标"; icon: "apps"; trailingIcon: root.iconSize === 2 ? "check" : "" }
    MenuItem { id: menuNewCategory; text: "新建分类"; icon: "create_new_folder" }
    MenuItem { id: menuWallpaper; text: "更换壁纸"; icon: "wallpaper" }
    MenuItem { id: menuHidden; text: "隐藏的应用"; icon: "visibility_off" }
    MenuItem { id: menuSettings; text: "系统设置"; icon: "settings" }

    // Dismiss overlay for context menu
    MouseArea {
        anchors.fill: parent
        z: 299
        visible: appContextMenu.expanded
        onClicked: {
            appContextMenu.expanded = false;
            root.contextMenuApp = null;
        }
    }

    // App right-click context menu (floating at root level)
    Menu {
        id: appContextMenu

        x: root.contextMenuX - implicitWidth / 2
        y: root.contextMenuY + Appearance.spacing.small

        z: 300
        expanded: false
        blurBackground: true
        minWidth: 140

        items: {
            const result = [ctxHide, ctxMoveToCategory];
            if (root.contextMenuApp) {
                const appId = root.contextMenuApp.id ?? "";
                if (root.appCategoryOverrides[appId]) {
                    return [ctxHide, ctxMoveToCategory, ctxResetCategory];
                }
            }
            return result;
        }

        onItemSelected: item => {
            if (item === ctxHide && root.contextMenuApp) {
                const appId = root.contextMenuApp.id ?? "";
                const hiddenApps = Config.launcher.hiddenApps ? [...Config.launcher.hiddenApps] : [];
                if (!hiddenApps.includes(appId)) {
                    hiddenApps.push(appId);
                }
                Config.launcher.hiddenApps = hiddenApps;
                Config.save();
            } else if (item === ctxMoveToCategory) {
                // Show category picker menu
                appContextMenu.expanded = false;
                moveToCatMenu.visible = true;
                return;
            } else if (item === ctxResetCategory && root.contextMenuApp) {
                root.moveAppToCategory(root.contextMenuApp.id ?? "", "");
            }
            appContextMenu.expanded = false;
            root.contextMenuApp = null;
        }
    }

    MenuItem { id: ctxHide; text: "隐藏应用"; icon: "visibility_off" }
    MenuItem { id: ctxMoveToCategory; text: "移动到分类"; icon: "drive_file_move" }
    MenuItem { id: ctxResetCategory; text: "恢复默认分类"; icon: "restart_alt" }

    // Dismiss overlay for move-to-category menu
    MouseArea {
        anchors.fill: parent
        z: 309
        visible: moveToCatMenu.visible
        onClicked: {
            moveToCatMenu.visible = false;
            root.contextMenuApp = null;
        }
    }

    // Move-to-category picker (custom, not Menu-based)
    Item {
        id: moveToCatMenu

        x: root.contextMenuX - implicitWidth / 2
        y: root.contextMenuY + Appearance.spacing.small
        z: 310
        visible: false

        implicitWidth: Math.max(140, catPickerCol.implicitWidth)
        implicitHeight: catPickerCol.implicitHeight

        Elevation {
            anchors.fill: parent
            radius: Appearance.rounding.normal
            level: 2
        }

        StyledClippingRect {
            anchors.fill: parent
            radius: Appearance.rounding.normal
            color: Colours.transparency.enabled
                ? Qt.alpha(Colours.palette.m3surfaceContainer, Colours.transparency.base + 0.15)
                : Colours.palette.m3surfaceContainer

            Column {
                id: catPickerCol
                anchors.left: parent.left
                anchors.right: parent.right

                Repeater {
                    model: {
                        const catData = Apps.categorized(root.customCategories, root.appCategoryOverrides, root.categoryRenames);
                        return catData.filter(c => c.label !== "全部应用").map(c => c.label);
                    }

                    delegate: StyledRect {
                        required property var modelData
                        required property int index

                        width: catPickerCol.width
                        implicitWidth: catPickerRow.implicitWidth + Appearance.padding.normal * 2
                        implicitHeight: catPickerRow.implicitHeight + Appearance.padding.normal * 2
                        color: "transparent"

                        Row {
                            id: catPickerRow
                            anchors.fill: parent
                            anchors.margins: Appearance.padding.normal
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: "folder"
                                color: Colours.palette.m3onSurfaceVariant
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: modelData
                                color: Colours.palette.m3onSurface
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        StateLayer {
                            radius: 0
                            function onClicked(): void {
                                if (root.contextMenuApp) {
                                    root.moveAppToCategory(root.contextMenuApp.id ?? "", modelData);
                                }
                                moveToCatMenu.visible = false;
                                root.contextMenuApp = null;
                            }
                        }
                    }
                }
            }
        }
    }

    // Category context menu items
    MenuItem { id: ctxCatRename; text: "重命名分类"; icon: "edit" }
    MenuItem { id: ctxCatDelete; text: "删除分类"; icon: "delete" }

    // Show category context menu
    function showCategoryContextMenu(sourceItem: var, catName: string): void {
        contextCategoryName = catName;
        const pos = sourceItem.mapToItem(root, sourceItem.width / 2, sourceItem.height);
        catMenuX = pos.x;
        catMenuY = pos.y;
        catContextMenu.expanded = true;
        launcherMenu.expanded = false;
        appContextMenu.expanded = false;
    }

    // Show input dialog helper
    function showInputDialogFor(title: string, initialValue: string, callback: var): void {
        inputDialogTitle = title;
        inputDialogValue = initialValue;
        inputDialogCallback = callback;
        showInputDialog = true;
        inputField.text = initialValue;
        inputField.forceActiveFocus();
    }

    // Dismiss overlay for category context menu
    MouseArea {
        anchors.fill: parent
        z: 399
        visible: catContextMenu.expanded
        onClicked: {
            catContextMenu.expanded = false;
            root.contextCategoryName = "";
        }
    }

    // Category right-click context menu
    Menu {
        id: catContextMenu

        x: root.catMenuX - implicitWidth / 2
        y: root.catMenuY + Appearance.spacing.small

        z: 400
        expanded: false
        blurBackground: true
        minWidth: 120

        items: {
            // Check if category has apps to decide if delete is allowed
            const catData = Apps.categorized(root.customCategories, root.appCategoryOverrides, root.categoryRenames);
            let hasApps = false;
            for (const c of catData) {
                if (c.label === root.contextCategoryName) {
                    hasApps = c.apps.length > 0;
                    break;
                }
            }
            // Show both rename and delete; delete will clear overrides
            return [ctxCatRename, ctxCatDelete];
        }

        onItemSelected: item => {
            if (item === ctxCatRename) {
                const oldName = root.contextCategoryName;
                root.showInputDialogFor("重命名分类", oldName, function(newName) {
                    if (newName.trim() && newName.trim() !== oldName) {
                        root.renameCategory(oldName, newName.trim());
                    }
                });
            } else if (item === ctxCatDelete) {
                root.deleteCategory(root.contextCategoryName);
            }
            catContextMenu.expanded = false;
            root.contextCategoryName = "";
        }
    }

    // Input dialog overlay
    MouseArea {
        anchors.fill: parent
        z: 499
        visible: root.showInputDialog
        onClicked: {
            root.showInputDialog = false;
            root.inputDialogCallback = null;
        }
    }

    // Input dialog
    Item {
        id: inputDialog
        visible: root.showInputDialog
        z: 500

        anchors.centerIn: parent
        width: 280
        implicitHeight: inputCol.implicitHeight + Appearance.padding.large * 2

        Elevation {
            anchors.fill: parent
            radius: Appearance.rounding.normal
            level: 3
        }

        StyledClippingRect {
            anchors.fill: parent
            radius: Appearance.rounding.normal
            color: Colours.transparency.enabled
                ? Qt.alpha(Colours.palette.m3surfaceContainer, Colours.transparency.base + 0.15)
                : Colours.palette.m3surfaceContainer

            Column {
                id: inputCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Appearance.padding.large
                anchors.verticalCenter: parent.verticalCenter
                spacing: Appearance.spacing.normal

                StyledText {
                    text: root.inputDialogTitle
                    font.pointSize: Appearance.font.size.normal
                    font.weight: 600
                    color: Colours.palette.m3onSurface
                }

                StyledRect {
                    width: parent.width
                    height: 40
                    radius: Appearance.rounding.small
                    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                    StyledTextField {
                        id: inputField
                        anchors.fill: parent
                        anchors.margins: Appearance.padding.small
                        font.pointSize: Appearance.font.size.smaller

                        Keys.onReturnPressed: confirmInputDialog()
                        Keys.onEscapePressed: {
                            root.showInputDialog = false;
                            root.inputDialogCallback = null;
                            search.forceActiveFocus();
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    spacing: Appearance.spacing.small

                    StyledRect {
                        width: cancelLabel.implicitWidth + Appearance.padding.large
                        height: 32
                        radius: 16
                        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                        StyledText {
                            id: cancelLabel
                            text: "取消"
                            anchors.centerIn: parent
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Appearance.font.size.smaller
                        }

                        StateLayer {
                            radius: 16
                            function onClicked(): void {
                                root.showInputDialog = false;
                                root.inputDialogCallback = null;
                                search.forceActiveFocus();
                            }
                        }
                    }

                    StyledRect {
                        width: confirmLabel.implicitWidth + Appearance.padding.large
                        height: 32
                        radius: 16
                        color: Colours.palette.m3primary

                        StyledText {
                            id: confirmLabel
                            text: "确定"
                            anchors.centerIn: parent
                            color: Colours.palette.m3onPrimary
                            font.pointSize: Appearance.font.size.smaller
                        }

                        StateLayer {
                            radius: 16
                            function onClicked(): void {
                                confirmInputDialog();
                            }
                        }
                    }
                }
            }
        }
    }

    function confirmInputDialog(): void {
        if (root.inputDialogCallback) {
            root.inputDialogCallback(inputField.text);
        }
        root.showInputDialog = false;
        root.inputDialogCallback = null;
        search.forceActiveFocus();
    }
}
