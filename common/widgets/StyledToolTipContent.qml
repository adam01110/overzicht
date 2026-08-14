import QtQuick
import "."
import "../"

Item {
    id: root
    required property string text
    property bool shown: false
    property bool collapseWhenHidden: true
    property bool expandCollapseAnimationEnabled: true
    property bool fadeAnimationEnabled: true
    property int fadeAnimationDuration: Appearance?.animation.elementMoveFast.duration ?? 200
    property real horizontalPadding: 10
    property real verticalPadding: 5
    implicitWidth: tooltipTextObject.implicitWidth + 2 * root.horizontalPadding
    implicitHeight: tooltipTextObject.implicitHeight + 2 * root.verticalPadding

    property bool isVisible: backgroundRectangle.implicitHeight > 0

    Rectangle {
        id: backgroundRectangle
        anchors {
            bottom: root.bottom
            horizontalCenter: root.horizontalCenter
        }
        color: Appearance?.colors.colTooltip
        radius: Appearance?.rounding.verysmall
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance?.palette.outline, 0.7)
        opacity: shown ? 1 : 0
        implicitWidth: shown || !root.collapseWhenHidden ? (tooltipTextObject.implicitWidth + 2 * root.horizontalPadding) : 0
        implicitHeight: shown || !root.collapseWhenHidden ? (tooltipTextObject.implicitHeight + 2 * root.verticalPadding) : 0
        clip: true

        Behavior on implicitWidth {
            enabled: root.expandCollapseAnimationEnabled
            animation: Appearance?.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on implicitHeight {
            enabled: root.expandCollapseAnimationEnabled
            animation: Appearance?.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on opacity {
            enabled: root.fadeAnimationEnabled
            NumberAnimation {
                duration: Math.max(0, root.fadeAnimationDuration)
                easing.type: Appearance?.animation.elementMoveFast.type ?? Easing.OutCubic
                easing.bezierCurve: Appearance?.animation.elementMoveFast.bezierCurve ?? []
            }
        }

        StyledText {
            id: tooltipTextObject
            anchors.centerIn: parent
            text: root.text
            font.pixelSize: Appearance?.font.pixelSize.smaller ?? 14
            font.hintingPreference: Font.PreferNoHinting
            color: Appearance?.colors.colOnTooltip ?? "#FFFFFF"
            wrapMode: Text.Wrap
        }
    }
}
