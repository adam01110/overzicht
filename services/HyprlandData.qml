pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../common"

/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 */
Singleton {
    id: root
    property var windowList: []
    property var windowByAddress: ({})
    property var fullscreenWorkspaces: ({})
    property var monitors: []
    property bool pendingWindowsUpdate: false
    property bool pendingMonitorsUpdate: false
    function updateWindowList() {
        getClients.running = true;
    }

    function updateMonitors() {
        getMonitors.running = true;
    }

    function updateAll() {
        scheduleUpdates(true, true);
    }

    function scheduleUpdates(windows, monitors) {
        if (!GlobalStates.overviewOpen)
            return;

        pendingWindowsUpdate = pendingWindowsUpdate || !!windows;
        pendingMonitorsUpdate = pendingMonitorsUpdate || !!monitors;

        const debounceMs = Math.max(0, Config.options.hacks.hyprlandEventDebounceMs);
        if (debounceMs === 0) {
            flushPendingUpdates();
        } else {
            eventDebounceTimer.interval = debounceMs;
            eventDebounceTimer.restart();
        }
    }

    function flushPendingUpdates() {
        if (pendingWindowsUpdate) {
            pendingWindowsUpdate = false;
            updateWindowList();
        }
        if (pendingMonitorsUpdate) {
            pendingMonitorsUpdate = false;
            updateMonitors();
        }
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w.workspace.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    Component.onCompleted: {
        if (GlobalStates.overviewOpen) {
            root.updateAll();
            root.flushPendingUpdates();
        }
    }

    Connections {
        target: GlobalStates

        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen) {
                root.updateAll();
                root.flushPendingUpdates();
            } else {
                eventDebounceTimer.stop();
                root.pendingWindowsUpdate = false;
                root.pendingMonitorsUpdate = false;
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (!GlobalStates.overviewOpen)
                return;

            const eventName = `${event?.name ?? event?.event ?? event?.type ?? ""}`;
            if (eventName === "openwindow" || eventName === "closewindow" || eventName === "movewindow" || eventName === "movewindowv2" || eventName === "windowtitle") {
                root.scheduleUpdates(true, false);
                return;
            }

            if (eventName.startsWith("monitor") || eventName === "configreloaded")
                root.scheduleUpdates(true, true);
        }
    }

    Timer {
        id: eventDebounceTimer
        interval: Math.max(0, Config.options.hacks.hyprlandEventDebounceMs)
        repeat: false
        onTriggered: root.flushPendingUpdates()
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                if (!GlobalStates.overviewOpen)
                    return;

                root.windowList = JSON.parse(clientsCollector.text);
                let tempWinByAddress = {};
                let tempFullscreenWorkspaces = {};
                for (var i = 0; i < root.windowList.length; ++i) {
                    var win = root.windowList[i];
                    tempWinByAddress[win.address] = win;
                    if ((win.fullscreen ?? 0) > 0 && win.workspace?.id !== undefined)
                        tempFullscreenWorkspaces[win.workspace.id] = true;
                }
                root.windowByAddress = tempWinByAddress;
                root.fullscreenWorkspaces = tempFullscreenWorkspaces;
            }
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                if (GlobalStates.overviewOpen)
                    root.monitors = JSON.parse(monitorsCollector.text);
            }
        }
    }
}
