pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import "functions"

Singleton {
    id: root
    function themeValue(path, fallback = undefined) {
        let current = root.themeData;

        for (let i = 0; i < path.length; i++) {
            if (current === null || current === undefined)
                return fallback;

            current = current[path[i]];
        }

        return current === undefined || current === null ? fallback : current;
    }

    function parseThemeData() {
        try {
            const content = themeFile.text();

            if (!content || content.trim().length === 0)
                return ({});

            return JSON.parse(content);
        } catch (error) {
            console.warn(`Failed to parse theme json: ${error}`);
            return ({});
        }
    }

    property string configDirectory: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    property var themeData: ({})

    property QtObject m3colors
    property QtObject animation
    property QtObject animationCurves
    property QtObject colors
    property QtObject rounding
    property QtObject font
    property QtObject sizes

    FileView {
        id: themeFile
        path: `${root.configDirectory}/overzicht/colors.json`
        blockLoading: true
        watchChanges: true
        onLoadedChanged: if (loaded)
            root.themeData = root.parseThemeData()
        onFileChanged: {
            reload();
            root.themeData = root.parseThemeData();
        }
    }

    Component.onCompleted: themeData = parseThemeData()

    m3colors: QtObject {
        property color m3primary: root.themeValue(["m3primary"], "#E5B6F2")
        property color m3onPrimary: root.themeValue(["m3onPrimary"], "#452152")
        property color m3primaryContainer: root.themeValue(["m3primaryContainer"], "#5D386A")
        property color m3onPrimaryContainer: root.themeValue(["m3onPrimaryContainer"], "#F9D8FF")
        property color m3onSecondary: root.themeValue(["m3onSecondary"], "#392C3D")
        property color m3secondaryContainer: root.themeValue(["m3secondaryContainer"], "#534457")
        property color m3onSecondaryContainer: root.themeValue(["m3onSecondaryContainer"], "#F2DCF3")
        property color m3onBackground: root.themeValue(["m3onBackground"], "#EAE0E7")
        property color m3surface: root.themeValue(["m3surface"], "#161217")
        property color m3surfaceContainerHigh: root.themeValue(["m3surfaceContainerHigh"], "#2D282E")
        property color m3surfaceContainerHighest: root.themeValue(["m3surfaceContainerHighest"], "#383339")
        property color m3surfaceVariant: root.themeValue(["m3surfaceVariant"], "#4C444D")
        property color m3background: root.themeValue(["m3background"], "#161217")
        property color m3secondary: root.themeValue(["m3secondary"], "#D5C0D7")
        property color m3surfaceContainerLow: root.themeValue(["m3surfaceContainerLow"], "#1F1A1F")
        property color m3surfaceContainer: root.themeValue(["m3surfaceContainer"], "#231E23")
        property color m3onSurface: root.themeValue(["m3onSurface"], "#EAE0E7")
        property color m3onSurfaceVariant: root.themeValue(["m3onSurfaceVariant"], "#CFC3CD")
        property color m3inverseSurface: root.themeValue(["m3inverseSurface"], "#EAE0E7")
        property color m3inverseOnSurface: root.themeValue(["m3inverseOnSurface"], "#342F34")
        property color m3outline: root.themeValue(["m3outline"], "#988E97")
        property color m3outlineVariant: root.themeValue(["m3outlineVariant"], "#4C444D")
        property color m3shadow: root.themeValue(["m3shadow"], "#000000")
    }

    colors: QtObject {
        property color colSubtext: m3colors.m3outline
        property color colLayer0: m3colors.m3background
        property color colOnLayer0: m3colors.m3onBackground
        property color colLayer0Border: ColorUtils.mix(root.m3colors.m3outlineVariant, colLayer0, 0.4)
        property color colLayer1: m3colors.m3surfaceContainerLow
        property color colOnLayer1: m3colors.m3onSurfaceVariant
        property color colOnLayer1Inactive: ColorUtils.mix(colOnLayer1, colLayer1, 0.45)
        property color colLayer1Hover: ColorUtils.mix(colLayer1, colOnLayer1, 0.92)
        property color colLayer1Active: ColorUtils.mix(colLayer1, colOnLayer1, 0.85)
        property color colLayer2: m3colors.m3surfaceContainer
        property color colOnLayer2: m3colors.m3onSurface
        property color colLayer2Hover: ColorUtils.mix(colLayer2, colOnLayer2, 0.90)
        property color colLayer2Active: ColorUtils.mix(colLayer2, colOnLayer2, 0.80)
        property color colPrimary: m3colors.m3primary
        property color colOnPrimary: m3colors.m3onPrimary
        property color colSecondary: m3colors.m3secondary
        property color colSecondaryContainer: m3colors.m3secondaryContainer
        property color colOnSecondaryContainer: m3colors.m3onSecondaryContainer
        property color colTooltip: m3colors.m3inverseSurface
        property color colOnTooltip: m3colors.m3inverseOnSurface
        property color colShadow: ColorUtils.transparentize(m3colors.m3shadow, 0.7)
        property color colOutline: m3colors.m3outline
    }

    rounding: QtObject {
        property int unsharpen: Config.options.appearance.rounding.unsharpen
        property int verysmall: Config.options.appearance.rounding.verysmall
        property int small: Config.options.appearance.rounding.small
        property int normal: Config.options.appearance.rounding.normal
        property int large: Config.options.appearance.rounding.large
        property int full: Config.options.appearance.rounding.full
        property int screenRounding: Config.options.appearance.rounding.screenRounding
        property int windowRounding: Config.options.appearance.rounding.windowRounding
    }

    font: QtObject {
        property QtObject family: QtObject {
            property string main: Config.optionValue(["appearance", "font", "family", "main"], root.themeValue(["font", "family", "main"], "sans-serif"))
            property string title: Config.optionValue(["appearance", "font", "family", "title"], root.themeValue(["font", "family", "title"], "sans-serif"))
            property string expressive: Config.optionValue(["appearance", "font", "family", "expressive"], root.themeValue(["font", "family", "expressive"], "sans-serif"))
        }
        property QtObject pixelSize: QtObject {
            property int smaller: Config.optionValue(["appearance", "font", "pixelSize", "smaller"], root.themeValue(["font", "pixelSize", "smaller"], 12))
            property int small: Config.optionValue(["appearance", "font", "pixelSize", "small"], root.themeValue(["font", "pixelSize", "small"], 15))
            property int normal: Config.optionValue(["appearance", "font", "pixelSize", "normal"], root.themeValue(["font", "pixelSize", "normal"], 16))
            property int larger: Config.optionValue(["appearance", "font", "pixelSize", "larger"], root.themeValue(["font", "pixelSize", "larger"], 19))
            property int huge: Config.optionValue(["appearance", "font", "pixelSize", "huge"], root.themeValue(["font", "pixelSize", "huge"], 22))
        }
    }

    animationCurves: QtObject {
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1]
        readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property real expressiveDefaultSpatialDuration: Config.options.appearance.animation.duration.elementMove
        readonly property real expressiveEffectsDuration: Config.options.appearance.animation.duration.elementMoveFast
    }

    animation: QtObject {
        property QtObject elementMove: QtObject {
            property int duration: animationCurves.expressiveDefaultSpatialDuration
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveDefaultSpatial
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMove.duration
                    easing.type: root.animation.elementMove.type
                    easing.bezierCurve: root.animation.elementMove.bezierCurve
                }
            }
        }

        property QtObject elementMoveEnter: QtObject {
            property int duration: Config.options.appearance.animation.duration.elementMoveEnter
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedDecel
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveEnter.duration
                    easing.type: root.animation.elementMoveEnter.type
                    easing.bezierCurve: root.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        property QtObject elementMoveFast: QtObject {
            property int duration: animationCurves.expressiveEffectsDuration
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveEffects
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
                }
            }
        }
    }

    sizes: QtObject {
        property real elevationMargin: Config.options.appearance.sizes.elevationMargin
    }
}
