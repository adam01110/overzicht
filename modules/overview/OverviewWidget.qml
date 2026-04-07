import QtQuick
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
    property var windowAddresses: HyprlandData.addresses
    property var monitorData: HyprlandData.monitors.find(m => m.id === root.monitor?.id)
    property real scale: Config.options.overview.scale
    property color activeBorderColor: Appearance.colors.colSecondary

    property real workspaceImplicitWidth: (monitorData?.transform % 2 === 1) ? ((monitor.height / monitor.scale - (monitorData?.reserved?.[0] ?? 0) - (monitorData?.reserved?.[2] ?? 0)) * root.scale) : ((monitor.width / monitor.scale - (monitorData?.reserved?.[0] ?? 0) - (monitorData?.reserved?.[2] ?? 0)) * root.scale)
    property real workspaceImplicitHeight: (monitorData?.transform % 2 === 1) ? ((monitor.width / monitor.scale - (monitorData?.reserved?.[1] ?? 0) - (monitorData?.reserved?.[3] ?? 0)) * root.scale) : ((monitor.height / monitor.scale - (monitorData?.reserved?.[1] ?? 0) - (monitorData?.reserved?.[3] ?? 0)) * root.scale)

    property real workspaceNumberMargin: 80
    property real workspaceNumberSize: Config.options.overview.workspaceNumberBaseSize * monitor.scale
    property int workspaceZ: 0
    property int windowZ: 1
    property int windowDraggingZ: 99999
    property real workspaceSpacing: Config.options.overview.workspaceSpacing
    property real panelOpacity: Math.max(0, Math.min(1, Config.options.overview.effects.panelOpacity))
    property real workspaceOpacity: Math.max(0, Math.min(1, Config.options.overview.effects.workspaceOpacity))

    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1
    property bool hideEmptyRows: Config.options.overview.hideEmptyRows

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

    implicitWidth: overviewBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: overviewBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

    property Component windowComponent: OverviewWindow {}
    property list<OverviewWindow> windowWidgets: []

    StyledRectangularShadow {
        target: overviewBackground
    }
    Rectangle { // Background
        id: overviewBackground
        property real padding: Config.options.overview.backgroundPadding
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin

        implicitWidth: workspaceColumnLayout.implicitWidth + padding * 2
        implicitHeight: workspaceColumnLayout.implicitHeight + padding * 2
        radius: 0
        clip: true
        color: ColorUtils.applyAlpha(Appearance.colors.colLayer0, root.panelOpacity)
        border.width: 1
        border.color: ColorUtils.applyAlpha(Appearance.colors.colLayer0Border, root.panelOpacity)

        ColumnLayout { // Workspaces
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
                        Rectangle { // Workspace
                            id: workspace
                            property int colIndex: index
                            property int workspaceValue: root.getWorkspaceInCell(rowIndex, colIndex)
                            property color defaultWorkspaceColor: Appearance.colors.colLayer1
                            property color hoveredWorkspaceColor: ColorUtils.mix(defaultWorkspaceColor, Appearance.colors.colLayer1Hover, 0.1)
                            property color hoveredBorderColor: Appearance.colors.colLayer2Hover
                            property bool hoveredWhileDragging: false

                            implicitWidth: root.workspaceImplicitWidth
                            implicitHeight: root.workspaceImplicitHeight
                            color: ColorUtils.applyAlpha(hoveredWhileDragging ? hoveredWorkspaceColor : defaultWorkspaceColor, root.workspaceOpacity)
                            radius: 0
                            border.width: 2
                            border.color: hoveredWhileDragging ? hoveredBorderColor : "transparent"

                            StyledText {
                                anchors.centerIn: parent
                                text: workspaceValue
                                font {
                                    pixelSize: root.workspaceNumberSize * root.scale
                                    weight: Font.DemiBold
                                    family: Appearance.font.family.expressive
                                }
                                color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.8)
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
                                        Hyprland.dispatch(`workspace ${workspaceValue}`);
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
                        }
                    }
                }
            }
        }

        Item { // Windows & focused workspace indicator
            id: windowSpace
            anchors.centerIn: parent
            implicitWidth: workspaceColumnLayout.implicitWidth
            implicitHeight: workspaceColumnLayout.implicitHeight

            Repeater {
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
                        onEntered: hovered = true
                        onExited: hovered = false
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
                            window.pressed = false;
                            window.Drag.active = false;
                            root.draggingFromWorkspace = -1;
                            if (targetWorkspace !== -1 && targetWorkspace !== windowData?.workspace.id) {
                                Hyprland.dispatch(`movetoworkspacesilent ${targetWorkspace}, address:${window.windowData?.address}`);
                                updateWindowPosition.restart();
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
                                Hyprland.dispatch(`focuswindow address:${windowData.address}`);
                                event.accepted = true;
                            } else if (event.button === Qt.MiddleButton) {
                                Hyprland.dispatch(`closewindow address:${windowData.address}`);
                                event.accepted = true;
                            }
                        }

                        StyledToolTip {
                            extraVisibleCondition: false
                            alternativeVisibleCondition: dragArea.containsMouse && !window.Drag.active
                            text: `${windowData?.title ?? "Unknown"}\n[${windowData?.class ?? "unknown"}] ${windowData?.xwayland ? "[XWayland] " : ""}`
                        }
                    }
                }
            }

            Rectangle { // Focused workspace indicator
                id: focusedWorkspaceIndicator
                property int activeWorkspaceRowIndex: root.getWorkspaceRow(root.effectiveActiveWorkspaceId)
                property int activeWorkspaceColIndex: root.getWorkspaceColumn(root.effectiveActiveWorkspaceId)
                x: (root.workspaceImplicitWidth + workspaceSpacing) * activeWorkspaceColIndex
                y: (root.workspaceImplicitHeight + workspaceSpacing) * root.mappedRowIndex(activeWorkspaceRowIndex)
                z: root.windowZ
                width: root.workspaceImplicitWidth
                height: root.workspaceImplicitHeight
                color: "transparent"
                radius: 0
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
}
