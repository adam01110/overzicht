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
        property QtObject overview: QtObject {
            property int rows: root.optionValue(["overview", "rows"], 2)
            property int columns: root.optionValue(["overview", "columns"], 4)
            property real scale: root.optionValue(["overview", "scale"], 0.12)
            property bool enable: root.optionValue(["overview", "enable"], true)
            property bool hideEmptyRows: root.optionValue(["overview", "hideEmptyRows"], false)
        }

        property QtObject hacks: QtObject {
            property int arbitraryRaceConditionDelay: root.optionValue(["hacks", "arbitraryRaceConditionDelay"], 150)
        }
    }
}
