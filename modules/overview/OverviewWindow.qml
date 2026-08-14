import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../common"
import "../../common/functions"
import "../../services"

Item { // Window
    id: root
    property var toplevel
    property var windowData
    property var monitorData
    property var scale
    property var availableWorkspaceWidth
    property var availableWorkspaceHeight
    property bool restrictToWorkspace: true
    property real initX: Math.max(((windowData?.at[0] ?? 0) - (monitorData?.x ?? 0) - (monitorData?.reserved?.[0] ?? 0)) * root.scale, 0) + xOffset
    property real initY: Math.max(((windowData?.at[1] ?? 0) - (monitorData?.y ?? 0) - (monitorData?.reserved?.[1] ?? 0)) * root.scale, 0) + yOffset
    property real xOffset: 0
    property real yOffset: 0
    property int widgetMonitorId: 0

    property var targetWindowWidth: (windowData?.size[0] ?? 100) * scale
    property var targetWindowHeight: (windowData?.size[1] ?? 100) * scale
    property bool hovered: false
    property bool pressed: false

    property var iconToWindowRatio: Config.options.windowPreview.iconToWindowRatio
    property var xwaylandIndicatorToIconRatio: Config.options.windowPreview.xwaylandIndicatorToIconRatio
    property var iconToWindowRatioCompact: Config.options.windowPreview.iconToWindowRatioCompact
    property bool cropToFill: Config.options.windowPreview.cropToFill
    property bool previewsEnabled: Config.options.overview.previewsEnabled
    property bool includeInactiveMonitorPreviews: Config.options.overview.includeInactiveMonitorPreviews
    property int previewRecaptureDelayMs: Config.options.overview.previewRecaptureDelayMs
    property real windowOverlayOpacity: Math.max(0, Math.min(1, Config.options.overview.effects.windowOverlayOpacity))
    property string previewModeRaw: Config.options.overview.previewMode
    property string previewMode: {
        const mode = `${previewModeRaw ?? "live"}`.trim().toLowerCase();
        return (mode === "event" || mode === "snapshot") ? "event" : "live";
    }
    property bool showIcons: Config.options.windowPreview.showIcons
    property bool livePreviewEnabled: previewsEnabled && previewMode === "live"
    property bool shouldCapturePreview: {
        if (!GlobalStates.overviewOpen || !previewsEnabled || !previewCaptureEnabled)
            return false;
        if (includeInactiveMonitorPreviews)
            return true;
        return (windowData?.monitor ?? -1) === widgetMonitorId;
    }
    property var entry: {
        DesktopEntries.applications.values; // re-run when the entry index updates
        return DesktopEntries.heuristicLookup(windowData?.class);
    }
    property string iconName: {
        const raw = `${entry?.icon ?? ""}`.trim();
        const withoutProviderPrefix = raw.replace(/^image:\/\/icon\//, "");
        const withoutQuery = withoutProviderPrefix.split("?")[0].trim();
        return withoutQuery.length > 0 ? withoutQuery : "application-x-executable";
    }
    property var iconPath: Quickshell.iconPath(iconName, "image-missing")
    property bool compactMode: Appearance.font.pixelSize.smaller * 4 > targetWindowHeight || Appearance.font.pixelSize.smaller * 4 > targetWindowWidth

    property bool indicateXWayland: windowData?.xwayland ?? false
    property bool previewCaptureEnabled: true
    property bool initialized: false
    readonly property real windowRounding: Math.max(0, Appearance.rounding.windowRounding * root.scale)

    x: initX
    y: initY
    width: Math.min(targetWindowWidth, availableWorkspaceWidth)
    height: Math.min(targetWindowHeight, availableWorkspaceHeight)
    opacity: (windowData?.monitor ?? -1) == widgetMonitorId ? 1 : Config.options.windowPreview.inactiveMonitorOpacity
    visible: {
        const thisWsId = windowData?.workspace?.id;
        const isFullscreen = (windowData?.fullscreen ?? 0) > 0;
        if (isFullscreen || thisWsId === undefined)
            return true;
        return !HyprlandData.fullscreenWorkspaces[thisWsId];
    }

    clip: true
    Component.onCompleted: Qt.callLater(() => root.initialized = true)

    Behavior on x {
        enabled: root.initialized
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    Behavior on y {
        enabled: root.initialized
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    Behavior on width {
        enabled: root.initialized
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    Behavior on height {
        enabled: root.initialized
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    // Opaque background for windows on the active monitor.
    // The simplest solution for making those windows fully opaque and not interacting with actual
    // windows behind the overview, e.g., applying blur to them.
    Rectangle {
        visible: (root.windowData?.monitor ?? -1) === root.widgetMonitorId
        anchors.fill: parent
        radius: root.windowRounding
        color: Appearance.colors.workspace
    }

    ScreencopyView {
        id: windowPreview
        readonly property real srcAspect: {
            const w = root.windowData?.size?.[0] ?? 0;
            const h = root.windowData?.size?.[1] ?? 0;
            return (w > 0 && h > 0) ? (w / h) : 1;
        }
        anchors.centerIn: parent
        width: root.cropToFill ? Math.max(parent.width, parent.height * srcAspect) : Math.min(parent.width, parent.height * srcAspect)
        height: root.cropToFill ? Math.max(parent.height, parent.width / srcAspect) : Math.min(parent.height, parent.width / srcAspect)
        captureSource: shouldCapturePreview ? root.toplevel : null
        live: livePreviewEnabled && shouldCapturePreview
        layer.enabled: root.windowRounding > 0
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: root.windowRounding > 0
            maskSource: previewMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.windowRounding
        color: pressed ? ColorUtils.applyAlpha(Appearance.colors.windowActive, Math.min(1, root.windowOverlayOpacity + 0.30)) : hovered ? ColorUtils.applyAlpha(Appearance.colors.windowHover, Math.min(1, root.windowOverlayOpacity + 0.20)) : ColorUtils.transparentize(Appearance.colors.window)
        border.color: Appearance.colors.windowBorder
        border.width: 1

        ColumnLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.font.pixelSize.smaller * 0.5

            Image {
                id: windowIcon
                visible: root.showIcons
                property var iconSize: {
                    return Math.min(targetWindowWidth, targetWindowHeight) * (root.compactMode ? root.iconToWindowRatioCompact : root.iconToWindowRatio) / (root.monitorData?.scale ?? 1);
                }
                Layout.alignment: Qt.AlignHCenter
                source: root.iconPath
                width: iconSize
                height: iconSize
                sourceSize: Qt.size(iconSize, iconSize)

                Behavior on width {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
                Behavior on height {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
            }
        }
    }

    Item {
        id: previewMask
        width: windowPreview.width
        height: windowPreview.height
        anchors.centerIn: parent
        visible: false
        layer.enabled: root.windowRounding > 0
        layer.smooth: true
        Rectangle {
            anchors.centerIn: parent
            width: root.width
            height: root.height
            radius: root.windowRounding
        }
    }

    function refreshCapture() {
        if (!GlobalStates.overviewOpen || livePreviewEnabled || !previewsEnabled)
            return;

        root.previewCaptureEnabled = false;
        previewResetTimer.restart();
    }

    Timer {
        id: previewResetTimer
        interval: Math.max(1, previewRecaptureDelayMs)
        repeat: false
        onTriggered: root.previewCaptureEnabled = true
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!GlobalStates.overviewOpen)
                return;

            const eventName = `${event?.name ?? event?.event ?? event?.type ?? ""}`;
            if (eventName === "closewindow" || eventName === "openwindow" || eventName === "movewindow")
                root.refreshCapture();
        }
    }
}
