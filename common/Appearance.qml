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

    property QtObject palette
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

    palette: QtObject {
        property color primary: root.themeValue(["primary"], "#E5B6F2")
        property color onPrimary: root.themeValue(["onPrimary"], "#452152")
        property color primaryContainer: root.themeValue(["primaryContainer"], "#5D386A")
        property color onPrimaryContainer: root.themeValue(["onPrimaryContainer"], "#F9D8FF")
        property color onSecondary: root.themeValue(["onSecondary"], "#392C3D")
        property color secondaryContainer: root.themeValue(["secondaryContainer"], "#534457")
        property color onSecondaryContainer: root.themeValue(["onSecondaryContainer"], "#F2DCF3")
        property color onBackground: root.themeValue(["onBackground"], "#EAE0E7")
        property color surface: root.themeValue(["surface"], "#161217")
        property color surfaceContainerHigh: root.themeValue(["surfaceContainerHigh"], "#2D282E")
        property color surfaceContainerHighest: root.themeValue(["surfaceContainerHighest"], "#383339")
        property color surfaceVariant: root.themeValue(["surfaceVariant"], "#4C444D")
        property color background: root.themeValue(["background"], "#161217")
        property color secondary: root.themeValue(["secondary"], "#D5C0D7")
        property color surfaceContainerLow: root.themeValue(["surfaceContainerLow"], "#1F1A1F")
        property color surfaceContainer: root.themeValue(["surfaceContainer"], "#231E23")
        property color onSurface: root.themeValue(["onSurface"], "#EAE0E7")
        property color onSurfaceVariant: root.themeValue(["onSurfaceVariant"], "#CFC3CD")
        property color inverseSurface: root.themeValue(["inverseSurface"], "#EAE0E7")
        property color inverseOnSurface: root.themeValue(["inverseOnSurface"], "#342F34")
        property color outline: root.themeValue(["outline"], "#988E97")
        property color outlineVariant: root.themeValue(["outlineVariant"], "#4C444D")
        property color shadow: root.themeValue(["shadow"], "#000000")
    }

    colors: QtObject {
        property color colSubtext: palette.outline
        property color colLayer0: palette.background
        property color colOnLayer0: palette.onBackground
        property color colLayer0Border: ColorUtils.mix(root.palette.outlineVariant, colLayer0, 0.4)
        property color colLayer1: palette.surfaceContainerLow
        property color colOnLayer1: palette.onSurfaceVariant
        property color colOnLayer1Inactive: ColorUtils.mix(colOnLayer1, colLayer1, 0.45)
        property color colLayer1Hover: ColorUtils.mix(colLayer1, colOnLayer1, 0.92)
        property color colLayer1Active: ColorUtils.mix(colLayer1, colOnLayer1, 0.85)
        property color colLayer2: palette.surfaceContainer
        property color colOnLayer2: palette.onSurface
        property color colLayer2Hover: ColorUtils.mix(colLayer2, colOnLayer2, 0.90)
        property color colLayer2Active: ColorUtils.mix(colLayer2, colOnLayer2, 0.80)
        property color colPrimary: palette.primary
        property color colOnPrimary: palette.onPrimary
        property color colSecondary: palette.secondary
        property color colSecondaryContainer: palette.secondaryContainer
        property color colOnSecondaryContainer: palette.onSecondaryContainer
        property color colTooltip: palette.inverseSurface
        property color colOnTooltip: palette.inverseOnSurface
        property color colShadow: ColorUtils.transparentize(palette.shadow, 0.7)
        property color colOutline: palette.outline
    }

    rounding: QtObject {
        property int unsharpen: 0
        property int verysmall: 0
        property int small: 0
        property int normal: 0
        property int large: 0
        property int full: 0
        property int screenRounding: 0
        property int windowRounding: 0
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
