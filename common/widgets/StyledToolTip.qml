import QtQuick
import QtQuick.Controls
import "."

ToolTip {
    id: root
    property bool extraVisibleCondition: true
    property bool alternativeVisibleCondition: false
    property bool expandCollapseAnimationEnabled: true
    property bool fadeAnimationEnabled: true
    property int fadeAnimationDuration: Appearance?.animation.elementMoveFast.duration ?? 200
    readonly property bool internalVisibleCondition: (extraVisibleCondition && (parent.hovered === undefined || parent?.hovered)) || alternativeVisibleCondition
    verticalPadding: 5
    horizontalPadding: 10
    background: null

    visible: internalVisibleCondition

    contentItem: StyledToolTipContent {
        id: contentItem
        text: root.text
        shown: root.internalVisibleCondition
        expandCollapseAnimationEnabled: root.expandCollapseAnimationEnabled
        fadeAnimationEnabled: root.fadeAnimationEnabled
        fadeAnimationDuration: root.fadeAnimationDuration
        horizontalPadding: root.horizontalPadding
        verticalPadding: root.verticalPadding
    }
}
