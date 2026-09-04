import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../common"
import "../../services"
import "."

Scope {
    id: overviewScope

    function workspaceNavigationState(monitorId) {
        const rows = Math.max(1, Config.options.overview.rows);
        const columns = Math.max(1, Config.options.overview.columns);
        const count = rows * columns;
        const currentId = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1;
        const workspaceMap = Config.options.overview.workspaceMap ?? [];
        const offset = Config.options.overview.useWorkspaceMap ? Number(workspaceMap[monitorId] ?? 0) : 0;
        const firstId = Math.floor((currentId - offset - 1) / count) * count + 1 + offset;
        const normalIndex = Math.max(0, Math.min(count - 1, currentId - firstId));
        const normalRow = Math.floor(normalIndex / columns);
        const normalColumn = normalIndex % columns;

        return {
            rows,
            columns,
            count,
            firstId,
            visualRow: Config.options.overview.orderBottomUp ? rows - normalRow - 1 : normalRow,
            visualColumn: Config.options.overview.orderRightLeft ? columns - normalColumn - 1 : normalColumn
        };
    }

    function workspaceInCell(state, visualRow, visualColumn): int {
        const normalRow = Config.options.overview.orderBottomUp ? state.rows - visualRow - 1 : visualRow;
        const normalColumn = Config.options.overview.orderRightLeft ? state.columns - visualColumn - 1 : visualColumn;
        return state.firstId + normalRow * state.columns + normalColumn;
    }

    function workspaceAtLinearOffset(state, step): int {
        const visualIndex = state.visualRow * state.columns + state.visualColumn;
        const targetIndex = (visualIndex + step + state.count) % state.count;
        return workspaceInCell(state, Math.floor(targetIndex / state.columns), targetIndex % state.columns);
    }

    function focusWorkspace(workspaceId): void {
        Hyprland.dispatch(`hl.dsp.focus({workspace = '${workspaceId}'})`);
    }

    function handleWorkspaceKey(event, monitorId): bool {
        const state = workspaceNavigationState(monitorId);
        const tabForward = event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier);
        const tabBackward = event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier));
        let targetId = 0;

        if (event.key === Qt.Key_Left || event.key === Qt.Key_H || tabBackward) {
            targetId = workspaceAtLinearOffset(state, -1);
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || tabForward) {
            targetId = workspaceAtLinearOffset(state, 1);
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            targetId = workspaceInCell(state, (state.visualRow - 1 + state.rows) % state.rows, state.visualColumn);
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            targetId = workspaceInCell(state, (state.visualRow + 1) % state.rows, state.visualColumn);
        } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            const position = event.key - Qt.Key_0;
            if (position <= state.count)
                targetId = state.firstId + position - 1;
        } else if (event.key === Qt.Key_0 && state.count >= 10) {
            targetId = state.firstId + 9;
        }

        if (targetId === 0)
            return false;

        focusWorkspace(targetId);
        return true;
    }

    function cycleOrOpen(step): void {
        if (!GlobalStates.overviewOpen) {
            GlobalStates.overviewOpen = true;
            return;
        }

        const monitorId = Hyprland.focusedMonitor?.id ?? 0;
        focusWorkspace(workspaceAtLinearOffset(workspaceNavigationState(monitorId), step));
    }

    Variants {
        id: overviewVariants
        model: Quickshell.screens
        PanelWindow {
            id: root
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: Hyprland.focusedMonitor?.id == monitor?.id
            property bool backdropEnabled: Config.options.overview.effects.enableBackdrop
            property real backdropOpacity: Math.max(0, Math.min(1, Config.options.overview.effects.backdropOpacity))
            property bool closeOnFocusLoss: Config.options.overview.closeOnFocusLoss ?? true
            screen: modelData
            visible: GlobalStates.overviewOpen

            WlrLayershell.namespace: "overzicht"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                property bool canBeActive: root.monitorIsFocused
                active: false
                onCleared: () => {
                    if (root.closeOnFocusLoss && !active && canBeActive)
                        GlobalStates.overviewOpen = false;
                }
            }

            Connections {
                target: GlobalStates
                function onOverviewOpenChanged() {
                    if (GlobalStates.overviewOpen)
                        delayedGrabTimer.start();
                }
            }

            Connections {
                target: Hyprland
                function onFocusedMonitorChanged() {
                    if (!GlobalStates.overviewOpen)
                        return;

                    if (root.monitorIsFocused && !grab.active)
                        grab.active = true;
                    else if (!root.monitorIsFocused && grab.active)
                        grab.active = false;
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: Config.options.hacks.arbitraryRaceConditionDelay
                repeat: false
                onTriggered: {
                    if (!grab.canBeActive)
                        return;
                    grab.active = GlobalStates.overviewOpen;
                }
            }

            implicitWidth: screen.width
            implicitHeight: screen.height

            Item {
                id: keyHandler
                anchors.fill: parent
                visible: GlobalStates.overviewOpen
                focus: GlobalStates.overviewOpen
                z: 0

                Rectangle {
                    anchors.fill: parent
                    visible: root.backdropEnabled
                    color: "#000000"
                    opacity: root.backdropOpacity
                    z: 0
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    enabled: root.closeOnFocusLoss && GlobalStates.overviewOpen
                    z: 0
                    onPressed: mouse => {
                        GlobalStates.overviewOpen = false;
                        mouse.accepted = true;
                    }
                }

                Keys.onPressed: event => {
                    if (overviewLoader.item?.handleKeyPress(event)) {
                        event.accepted = true;
                        return;
                    }

                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.overviewOpen = false;
                        event.accepted = true;
                        return;
                    }

                    const monitorId = Hyprland.focusedMonitor?.id ?? root.monitor?.id ?? 0;
                    event.accepted = overviewScope.handleWorkspaceKey(event, monitorId);
                }
            }

            ColumnLayout {
                id: columnLayout
                visible: GlobalStates.overviewOpen
                anchors.centerIn: parent
                z: 1

                Loader {
                    id: overviewLoader
                    active: (Config?.options.overview.enable ?? true) && GlobalStates.overviewOpen
                    sourceComponent: OverviewWidget {
                        panelWindow: root
                        visible: true
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "overview"

        function toggle(): void {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function close(): void {
            GlobalStates.overviewOpen = false;
        }
        function cycle(): void {
            overviewScope.cycleOrOpen(1);
        }
        function cycleBackwards(): void {
            overviewScope.cycleOrOpen(-1);
        }
        function open(): void {
            GlobalStates.overviewOpen = true;
        }
        function isOpen(): bool {
            return GlobalStates.overviewOpen;
        }
    }
}
