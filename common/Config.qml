pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function optionValue(path, fallback) {
        let current = root.settingsData;

        for (let i = 0; i < path.length; i++) {
            if (current === null || current === undefined)
                return fallback;

            current = current[path[i]];
        }

        return current === undefined || current === null ? fallback : current;
    }

    function parseSettingsData() {
        try {
            const content = settingsFile.text();

            if (!content || content.trim().length === 0)
                return ({});

            return JSON.parse(content);
        } catch (error) {
            console.warn(`Failed to parse overview settings json: ${error}`);
            return ({});
        }
    }

    property string configDirectory: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    property var settingsData: ({})

    FileView {
        id: settingsFile
        path: `${root.configDirectory}/overzicht/settings.json`
        blockLoading: true
        watchChanges: true
        onLoadedChanged: if (loaded)
            root.settingsData = root.parseSettingsData()
        onFileChanged: {
            reload();
            root.settingsData = root.parseSettingsData();
        }
    }

    Component.onCompleted: settingsData = parseSettingsData()

    property QtObject options: QtObject {
        property QtObject appearance: QtObject {
            property QtObject rounding: QtObject {
                property int unsharpen: root.optionValue(["appearance", "rounding", "unsharpen"], 0)
                property int verysmall: root.optionValue(["appearance", "rounding", "verysmall"], 0)
                property int small: root.optionValue(["appearance", "rounding", "small"], 0)
                property int normal: root.optionValue(["appearance", "rounding", "normal"], 0)
                property int large: root.optionValue(["appearance", "rounding", "large"], 0)
                property int full: root.optionValue(["appearance", "rounding", "full"], 0)
                property int screenRounding: root.optionValue(["appearance", "rounding", "screenRounding"], 0)
                property int windowRounding: root.optionValue(["appearance", "rounding", "windowRounding"], 0)
            }

            property QtObject animation: QtObject {
                property QtObject duration: QtObject {
                    property int elementMove: root.optionValue(["appearance", "animation", "duration", "elementMove"], 500)
                    property int elementMoveEnter: root.optionValue(["appearance", "animation", "duration", "elementMoveEnter"], 400)
                    property int elementMoveFast: root.optionValue(["appearance", "animation", "duration", "elementMoveFast"], 200)
                }
            }

            property QtObject sizes: QtObject {
                property real elevationMargin: root.optionValue(["appearance", "sizes", "elevationMargin"], 10)
            }
        }

        property QtObject overview: QtObject {
            property int rows: root.optionValue(["overview", "rows"], 2)
            property int columns: root.optionValue(["overview", "columns"], 4)
            property real scale: root.optionValue(["overview", "scale"], 0.12)
            property bool enable: root.optionValue(["overview", "enable"], true)
            property bool hideEmptyRows: root.optionValue(["overview", "hideEmptyRows"], false)
            property real workspaceSpacing: root.optionValue(["overview", "workspaceSpacing"], 5)
            property real backgroundPadding: root.optionValue(["overview", "backgroundPadding"], 10)
            property real workspaceNumberBaseSize: root.optionValue(["overview", "workspaceNumberBaseSize"], 250)
        }

        property QtObject windowPreview: QtObject {
            property real iconToWindowRatio: root.optionValue(["windowPreview", "iconToWindowRatio"], 0.25)
            property real iconToWindowRatioCompact: root.optionValue(["windowPreview", "iconToWindowRatioCompact"], 0.45)
            property real xwaylandIndicatorToIconRatio: root.optionValue(["windowPreview", "xwaylandIndicatorToIconRatio"], 0.35)
            property real inactiveMonitorOpacity: root.optionValue(["windowPreview", "inactiveMonitorOpacity"], 0.4)
        }

        property QtObject hacks: QtObject {
            property int arbitraryRaceConditionDelay: root.optionValue(["hacks", "arbitraryRaceConditionDelay"], 150)
        }
    }
}
