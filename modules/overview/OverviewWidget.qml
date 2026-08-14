import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "../../services"
import "."

Item {
    id: root
    required property var panelWindow
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
    readonly property var toplevels: ToplevelManager.toplevels
    readonly property int effectiveActiveWorkspaceId: Math.max(1, Math.min(100, monitor?.activeWorkspace?.id ?? 1))
    readonly property int workspacesShown: Config.options.overview.rows * Config.options.overview.columns
    readonly property bool useWorkspaceMap: Config.options.overview.useWorkspaceMap
    readonly property var workspaceMap: Config.options.overview.workspaceMap
    readonly property int workspaceOffset: useWorkspaceMap ? Number(workspaceMap[root.monitor?.id] ?? 0) : 0
    readonly property int workspaceGroup: Math.floor((effectiveActiveWorkspaceId - workspaceOffset - 1) / workspacesShown)
    property bool monitorIsFocused: Hyprland.focusedMonitor?.name == monitor.name
    property var windows: HyprlandData.windowList
    property var windowByAddress: HyprlandData.windowByAddress
    property var monitorData: HyprlandData.monitors.find(m => m.id === root.monitor?.id)
    property real scale: Config.options.overview.scale
    property color activeBorderColor: Appearance.colors.accent

    property real workspaceImplicitWidth: Math.round((monitorData?.transform % 2 === 1) ? ((monitor.height / monitor.scale - (monitorData?.reserved?.[0] ?? 0) - (monitorData?.reserved?.[2] ?? 0)) * root.scale) : ((monitor.width / monitor.scale - (monitorData?.reserved?.[0] ?? 0) - (monitorData?.reserved?.[2] ?? 0)) * root.scale))
    property real workspaceImplicitHeight: Math.round((monitorData?.transform % 2 === 1) ? ((monitor.width / monitor.scale - (monitorData?.reserved?.[1] ?? 0) - (monitorData?.reserved?.[3] ?? 0)) * root.scale) : ((monitor.height / monitor.scale - (monitorData?.reserved?.[1] ?? 0) - (monitorData?.reserved?.[3] ?? 0)) * root.scale))

    property real workspaceNumberMargin: 80
    property real workspaceNumberSize: Config.options.overview.workspaceNumberBaseSize * monitor.scale
    property int workspaceZ: 0
    property int windowZ: 1
    property int windowDraggingZ: 99999
    property real workspaceSpacing: Config.options.overview.workspaceSpacing
    property string emptyWorkspaceWallpaperPath: Config.options.overview.emptyWorkspaceWallpaper
    property real panelOpacity: Math.max(0, Math.min(1, Config.options.overview.effects.panelOpacity))
    property real workspaceOpacity: Math.max(0, Math.min(1, Config.options.overview.effects.workspaceOpacity))
    property real emptyWorkspaceWallpaperOverlayOpacity: Math.max(0, Math.min(1, Config.options.overview.effects.emptyWorkspaceWallpaperOverlayOpacity))
    readonly property real screenRounding: Math.max(0, Appearance.rounding.screenRounding * root.scale)

    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1
    property bool hideEmptyRows: Config.options.overview.hideEmptyRows
    property bool smoothTooltipMovement: Config.options.windowPreview.smoothTooltipMovement
    property bool tooltipExpandCollapseAnimationEnabled: Config.options.windowPreview.tooltipAnimations.expandCollapse.enable
    property bool tooltipFadeAnimationEnabled: Config.options.windowPreview.tooltipAnimations.fade.enable
    property int tooltipFadeAnimationDuration: Math.max(0, Config.options.windowPreview.tooltipAnimations.fade.duration)
    readonly property bool hasEmptyWorkspaceWallpaper: `${emptyWorkspaceWallpaperPath ?? ""}`.trim().length > 0
    onSmoothTooltipMovementChanged: {
        tooltipHideTimer.stop();
        sharedWindowTooltip.targetWindow = null;
    }

    function windowTooltipText(window) {
        const data = window?.windowData;
        return `${data?.title ?? "Unknown"}\n[${data?.class ?? "unknown"}] ${data?.xwayland ? "[XWayland] " : ""}`;
    }

    function showWindowTooltip(window) {
        if (!root.smoothTooltipMovement)
            return;

        tooltipHideTimer.stop();
        sharedWindowTooltip.tooltipText = root.windowTooltipText(window);
        sharedWindowTooltip.targetWindow = window;
    }

    function hideWindowTooltip(window) {
        if (root.smoothTooltipMovement && sharedWindowTooltip.targetWindow === window)
            tooltipHideTimer.restart();
    }

    function getWorkspaceRow(workspaceId) {
        if (!Number.isFinite(workspaceId))
            return 0;

        const adjusted = workspaceId - workspaceOffset;
        const normalRow = Math.floor((adjusted - 1) / Config.options.overview.columns) % Config.options.overview.rows;
        return Config.options.overview.orderBottomUp ? (Config.options.overview.rows - normalRow - 1) : normalRow;
    }

    function getWorkspaceColumn(workspaceId) {
        if (!Number.isFinite(workspaceId))
            return 0;

        const adjusted = workspaceId - workspaceOffset;
        const normalCol = (adjusted - 1) % Config.options.overview.columns;
        return Config.options.overview.orderRightLeft ? (Config.options.overview.columns - normalCol - 1) : normalCol;
    }

    function getWorkspaceInCell(rowIndex, colIndex) {
        const mappedRow = Config.options.overview.orderBottomUp ? (Config.options.overview.rows - rowIndex - 1) : rowIndex;
        const mappedCol = Config.options.overview.orderRightLeft ? (Config.options.overview.columns - colIndex - 1) : colIndex;
        return workspaceGroup * workspacesShown + mappedRow * Config.options.overview.columns + mappedCol + 1 + workspaceOffset;
    }

    function wallpaperSource(path) {
        const trimmed = `${path ?? ""}`.trim();
        if (trimmed.length === 0)
            return "";
        if (trimmed.startsWith("file:/") || trimmed.startsWith("qrc:/") || trimmed.startsWith("image://") || trimmed.startsWith("http://") || trimmed.startsWith("https://"))
            return trimmed;
        if (trimmed.startsWith("/"))
            return `file://${trimmed}`;
        return trimmed;
    }

    property var rowsWithContent: {
        if (!root.hideEmptyRows)
            return null;

        let rows = new Set();
        const firstWorkspace = root.workspaceGroup * root.workspacesShown + 1 + workspaceOffset;
        const lastWorkspace = (root.workspaceGroup + 1) * root.workspacesShown + workspaceOffset;

        const currentWorkspace = effectiveActiveWorkspaceId;
        if (currentWorkspace >= firstWorkspace && currentWorkspace <= lastWorkspace)
            rows.add(getWorkspaceRow(currentWorkspace));

        for (let addr in windowByAddress) {
            const win = windowByAddress[addr];
            const wsId = win?.workspace?.id;
            if (wsId >= firstWorkspace && wsId <= lastWorkspace)
                rows.add(getWorkspaceRow(wsId));
        }

        return rows;
    }

    property var visibleRows: {
        if (!root.hideEmptyRows || !root.rowsWithContent)
            return null;

        return Array.from(root.rowsWithContent).sort((a, b) => a - b);
    }

    function mappedRowIndex(rowIndex) {
        if (!root.hideEmptyRows || !root.visibleRows)
            return rowIndex;

        const mappedIndex = root.visibleRows.indexOf(rowIndex);
        return mappedIndex === -1 ? rowIndex : mappedIndex;
    }

    function dropSwapTarget(workspaceId, dropX, dropY, excludedAddress) {
        for (let i = windowRepeater.count - 1; i >= 0; --i) {
            const candidate = windowRepeater.itemAt(i);
            const data = candidate?.windowData;
            if (!data || data.address === excludedAddress || data.workspace?.id !== workspaceId || data.floating || data.fullscreen > 0)
                continue;
            if (dropX >= candidate.x && dropX <= candidate.x + candidate.width && dropY >= candidate.y && dropY <= candidate.y + candidate.height)
                return data.address;
        }

        return "";
    }

    function refreshWindowCaptures() {
        for (let i = 0; i < windowRepeater.count; ++i)
            windowRepeater.itemAt(i)?.refreshCapture();
    }

    implicitWidth: overviewBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: overviewBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

    property Component windowComponent: OverviewWindow {}
    property list<OverviewWindow> windowWidgets: []

    StyledRectangularShadow {
        target: overviewBackground
    }
    Rectangle {
        id: overviewBackground
        property real padding: Config.options.overview.backgroundPadding
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin

        implicitWidth: workspaceColumnLayout.implicitWidth + padding * 2
        implicitHeight: workspaceColumnLayout.implicitHeight + padding * 2
        radius: root.screenRounding
        clip: true
        color: ColorUtils.applyAlpha(Appearance.colors.panel, root.panelOpacity)
        border.width: 1
        border.color: ColorUtils.applyAlpha(Appearance.colors.panelBorder, root.panelOpacity)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: workspaceColumnLayout

            z: root.workspaceZ
            anchors.centerIn: parent
            spacing: workspaceSpacing
            Repeater {
                model: Config.options.overview.rows
                delegate: RowLayout {
                    id: row
                    property int rowIndex: index
                    spacing: workspaceSpacing
                    visible: !root.hideEmptyRows || (root.rowsWithContent && root.rowsWithContent.has(rowIndex))
                    height: visible ? implicitHeight : 0

                    Repeater {
                        model: Config.options.overview.columns
                        Rectangle {
                            id: workspace
                            property int colIndex: index
                            property int workspaceValue: root.getWorkspaceInCell(rowIndex, colIndex)
                            readonly property bool hasWindows: {
                                const windows = root.windowByAddress;
                                for (const address in windows) {
                                    if (windows[address]?.workspace?.id === workspaceValue)
                                        return true;
                                }
                                return false;
                            }
                            property bool showWallpaper: root.hasEmptyWorkspaceWallpaper
                            property color defaultWorkspaceColor: Appearance.colors.workspace
                            property color hoveredWorkspaceColor: ColorUtils.mix(defaultWorkspaceColor, Appearance.colors.workspaceHover, 0.1)
                            property color hoveredBorderColor: Appearance.colors.windowHover
                            property bool hoveredWhileDragging: false

                            implicitWidth: root.workspaceImplicitWidth
                            implicitHeight: root.workspaceImplicitHeight
                            clip: showWallpaper
                            color: showWallpaper ? "transparent" : ColorUtils.applyAlpha(hoveredWhileDragging ? hoveredWorkspaceColor : defaultWorkspaceColor, root.workspaceOpacity)
                            radius: root.screenRounding
                            border.width: 0

                            Image {
                                id: workspaceWallpaper
                                visible: workspace.showWallpaper
                                anchors.fill: parent
                                source: root.wallpaperSource(root.emptyWorkspaceWallpaperPath)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                smooth: true
                                mipmap: true
                                layer.enabled: workspace.showWallpaper && workspace.radius > 0
                                layer.smooth: true
                                layer.effect: MultiEffect {
                                    maskEnabled: workspace.radius > 0
                                    maskSource: workspaceWallpaperMask
                                    maskThresholdMin: 0.5
                                    maskSpreadAtMin: 1.0
                                }
                            }

                            Item {
                                id: workspaceWallpaperMask
                                anchors.fill: parent
                                visible: false
                                layer.enabled: workspace.radius > 0
                                layer.smooth: true
                                Rectangle {
                                    anchors.fill: parent
                                    radius: workspace.radius
                                }
                            }

                            Rectangle {
                                visible: workspace.showWallpaper
                                anchors.fill: parent
                                radius: parent.radius
                                color: ColorUtils.applyAlpha(workspace.hoveredWhileDragging ? workspace.hoveredWorkspaceColor : workspace.defaultWorkspaceColor, workspace.hoveredWhileDragging ? Math.min(0.28, root.emptyWorkspaceWallpaperOverlayOpacity + 0.08) : root.emptyWorkspaceWallpaperOverlayOpacity)
                            }

                            StyledText {
                                anchors.centerIn: parent
                                visible: !workspace.showWallpaper
                                text: workspaceValue
                                font {
                                    pixelSize: root.workspaceNumberSize * root.scale
                                    weight: Font.DemiBold
                                    family: Appearance.font.family.expressive
                                }
                                color: ColorUtils.transparentize(Appearance.colors.workspaceText, 0.8)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                id: workspaceArea
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                onClicked: {
                                    if (root.draggingTargetWorkspace === -1) {
                                        GlobalStates.overviewOpen = false;
                                        Hyprland.dispatch(`hl.dsp.focus({workspace = '${workspaceValue}'})`);
                                    }
                                }
                            }

                            DropArea {
                                anchors.fill: parent
                                onEntered: {
                                    root.draggingTargetWorkspace = workspaceValue;
                                    if (root.draggingFromWorkspace == root.draggingTargetWorkspace)
                                        return;
                                    hoveredWhileDragging = true;
                                }
                                onExited: {
                                    hoveredWhileDragging = false;
                                    if (root.draggingTargetWorkspace == workspaceValue)
                                        root.draggingTargetWorkspace = -1;
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: workspace.hoveredWhileDragging || !workspace.hasWindows
                                color: "transparent"
                                radius: workspace.radius
                                border.width: workspace.hoveredWhileDragging ? 2 : 1
                                border.color: workspace.hoveredWhileDragging ? workspace.hoveredBorderColor : Appearance.colors.panelBorder
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: windowSpace
            anchors.centerIn: parent
            implicitWidth: workspaceColumnLayout.implicitWidth
            implicitHeight: workspaceColumnLayout.implicitHeight

            Repeater {
                id: windowRepeater
                model: ScriptModel {
                    values: {
                        return ToplevelManager.toplevels.values.filter(toplevel => {
                            const address = `0x${toplevel.HyprlandToplevel.address}`;
                            var win = windowByAddress[address];
                            const minWorkspace = root.workspaceGroup * root.workspacesShown + 1 + workspaceOffset;
                            const maxWorkspace = (root.workspaceGroup + 1) * root.workspacesShown + workspaceOffset;
                            return minWorkspace <= win?.workspace?.id && win?.workspace?.id <= maxWorkspace;
                        }).sort((a, b) => {
                            const addrA = `0x${a.HyprlandToplevel.address}`;
                            const addrB = `0x${b.HyprlandToplevel.address}`;
                            const winA = windowByAddress[addrA];
                            const winB = windowByAddress[addrB];

                            if (winA?.pinned !== winB?.pinned)
                                return winA?.pinned ? 1 : -1;

                            if (winA?.floating !== winB?.floating)
                                return winA?.floating ? 1 : -1;

                            return (winB?.focusHistoryID ?? 0) - (winA?.focusHistoryID ?? 0);
                        });
                    }
                }
                delegate: OverviewWindow {
                    id: window
                    required property var modelData
                    required property int index
                    property int monitorId: windowData?.monitor
                    property var monitor: HyprlandData.monitors.find(m => m.id === monitorId)
                    property var address: `0x${modelData.HyprlandToplevel.address}`
                    windowData: windowByAddress[address]
                    toplevel: modelData
                    monitorData: monitor

                    property real sourceMonitorWidth: (monitor?.transform % 2 === 1) ? (monitor?.height ?? 1920) / (monitor?.scale ?? 1) - (monitor?.reserved?.[0] ?? 0) - (monitor?.reserved?.[2] ?? 0) : (monitor?.width ?? 1920) / (monitor?.scale ?? 1) - (monitor?.reserved?.[0] ?? 0) - (monitor?.reserved?.[2] ?? 0)
                    property real sourceMonitorHeight: (monitor?.transform % 2 === 1) ? (monitor?.width ?? 1080) / (monitor?.scale ?? 1) - (monitor?.reserved?.[1] ?? 0) - (monitor?.reserved?.[3] ?? 0) : (monitor?.height ?? 1080) / (monitor?.scale ?? 1) - (monitor?.reserved?.[1] ?? 0) - (monitor?.reserved?.[3] ?? 0)

                    scale: Math.min(root.workspaceImplicitWidth / sourceMonitorWidth, root.workspaceImplicitHeight / sourceMonitorHeight)
                    availableWorkspaceWidth: root.workspaceImplicitWidth
                    availableWorkspaceHeight: root.workspaceImplicitHeight
                    widgetMonitorId: root.monitor.id

                    property bool atInitPosition: initX == x && initY == y

                    property int workspaceColIndex: root.getWorkspaceColumn(windowData?.workspace.id)
                    property int workspaceRowIndex: root.getWorkspaceRow(windowData?.workspace.id)
                    property int workspaceVisibleRowIndex: root.mappedRowIndex(workspaceRowIndex)
                    xOffset: (root.workspaceImplicitWidth + workspaceSpacing) * workspaceColIndex
                    yOffset: (root.workspaceImplicitHeight + workspaceSpacing) * workspaceVisibleRowIndex

                    Timer {
                        id: updateWindowPosition
                        interval: Config.options.hacks.arbitraryRaceConditionDelay
                        repeat: false
                        running: false
                        onTriggered: {
                            window.x = Math.round(Math.max((windowData?.at[0] - (monitor?.x ?? 0) - (monitorData?.reserved?.[0] ?? 0)) * window.scale, 0) + xOffset);
                            window.y = Math.round(Math.max((windowData?.at[1] - (monitor?.y ?? 0) - (monitorData?.reserved?.[1] ?? 0)) * window.scale, 0) + yOffset);
                        }
                    }

                    z: atInitPosition ? root.windowZ + index : root.windowDraggingZ
                    Drag.hotSpot.x: targetWindowWidth / 2
                    Drag.hotSpot.y: targetWindowHeight / 2
                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            hovered = true;
                            root.showWindowTooltip(window);
                        }
                        onExited: {
                            hovered = false;
                            root.hideWindowTooltip(window);
                        }
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        drag.target: parent
                        onPressed: mouse => {
                            root.draggingFromWorkspace = windowData?.workspace.id;
                            window.pressed = true;
                            window.Drag.active = true;
                            window.Drag.source = window;
                            window.Drag.hotSpot.x = mouse.x;
                            window.Drag.hotSpot.y = mouse.y;
                        }
                        onReleased: {
                            const targetWorkspace = root.draggingTargetWorkspace;
                            const address = window.windowData?.address;
                            let swapTarget = "";
                            let cursorPosition = null;
                            if (targetWorkspace !== -1) {
                                const dropX = window.x + window.Drag.hotSpot.x;
                                const dropY = window.y + window.Drag.hotSpot.y;
                                swapTarget = !windowData?.floating ? root.dropSwapTarget(targetWorkspace, dropX, dropY, address) : "";
                                if (swapTarget)
                                    cursorPosition = windowSpace.mapToGlobal(dropX, dropY);
                            }

                            window.pressed = false;
                            window.Drag.active = false;
                            root.draggingFromWorkspace = -1;
                            root.draggingTargetWorkspace = -1;
                            if (targetWorkspace !== -1) {
                                const changingWorkspace = targetWorkspace !== windowData?.workspace.id;
                                if (changingWorkspace)
                                    Hyprland.dispatch(`hl.dsp.window.move({workspace = '${targetWorkspace}', follow = false, window = 'address:${address}'})`);
                                if (swapTarget) {
                                    Hyprland.dispatch(`hl.dsp.window.swap({target = 'address:${swapTarget}', window = 'address:${address}'})`);
                                    Hyprland.dispatch(`hl.dsp.cursor.move({x = ${Math.round(cursorPosition.x)}, y = ${Math.round(cursorPosition.y)}})`);
                                }

                                if (changingWorkspace || swapTarget) {
                                    HyprlandData.updateWindowList();
                                    root.refreshWindowCaptures();
                                    updateWindowPosition.restart();
                                } else {
                                    window.x = window.initX;
                                    window.y = window.initY;
                                }
                            } else {
                                window.x = window.initX;
                                window.y = window.initY;
                            }
                        }
                        onClicked: event => {
                            if (!windowData)
                                return;

                            if (event.button === Qt.LeftButton) {
                                GlobalStates.overviewOpen = false;
                                Hyprland.dispatch(`hl.dsp.focus({window = 'address:${windowData.address}'})`);
                                event.accepted = true;
                            } else if (event.button === Qt.MiddleButton) {
                                Hyprland.dispatch(`hl.dsp.window.close('address:${windowData.address}')`);
                                event.accepted = true;
                            }
                        }

                        StyledToolTip {
                            extraVisibleCondition: false
                            alternativeVisibleCondition: !root.smoothTooltipMovement && dragArea.containsMouse && !window.Drag.active
                            text: root.windowTooltipText(window)
                            expandCollapseAnimationEnabled: root.tooltipExpandCollapseAnimationEnabled
                            fadeAnimationEnabled: root.tooltipFadeAnimationEnabled
                            fadeAnimationDuration: root.tooltipFadeAnimationDuration
                        }
                    }
                }
            }

            Rectangle {
                id: focusedWorkspaceIndicator
                property int activeWorkspaceRowIndex: root.getWorkspaceRow(root.effectiveActiveWorkspaceId)
                property int activeWorkspaceColIndex: root.getWorkspaceColumn(root.effectiveActiveWorkspaceId)
                x: (root.workspaceImplicitWidth + workspaceSpacing) * activeWorkspaceColIndex
                y: (root.workspaceImplicitHeight + workspaceSpacing) * root.mappedRowIndex(activeWorkspaceRowIndex)
                z: root.windowDraggingZ - 1
                width: root.workspaceImplicitWidth
                height: root.workspaceImplicitHeight
                color: "transparent"
                radius: root.screenRounding
                border.width: 2
                border.color: root.activeBorderColor
                Behavior on x {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on y {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }

    Timer {
        id: tooltipHideTimer
        interval: Appearance.animation.elementMoveFast.duration
        repeat: false
        onTriggered: sharedWindowTooltip.targetWindow = null
    }

    StyledToolTipContent {
        id: sharedWindowTooltip
        property var targetWindow: null
        property bool hasPosition: false
        property string tooltipText: ""
        property real tooltipX: 0
        property real tooltipY: 0
        readonly property real edgeMargin: Appearance.sizes.elevationMargin

        x: tooltipX
        y: tooltipY
        z: root.windowDraggingZ + 1
        width: implicitWidth
        height: implicitHeight
        text: tooltipText
        shown: root.smoothTooltipMovement && targetWindow !== null && !targetWindow.Drag.active
        collapseWhenHidden: true
        expandCollapseAnimationEnabled: root.tooltipExpandCollapseAnimationEnabled
        fadeAnimationEnabled: root.tooltipFadeAnimationEnabled
        fadeAnimationDuration: root.tooltipFadeAnimationDuration

        onTargetWindowChanged: {
            if (targetWindow) {
                const targetTop = targetWindow.mapToItem(root, targetWindow.width / 2, 0);
                tooltipX = Math.max(edgeMargin, Math.min(root.width - width - edgeMargin, targetTop.x - width / 2));
                tooltipY = targetTop.y - height - edgeMargin;
                if (!hasPosition)
                    Qt.callLater(() => sharedWindowTooltip.hasPosition = true);
            } else {
                hasPosition = false;
            }
        }

        Behavior on x {
            enabled: sharedWindowTooltip.hasPosition
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on y {
            enabled: sharedWindowTooltip.hasPosition
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }
}
