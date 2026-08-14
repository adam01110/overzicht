import QtQuick
import ".."

Text {
    id: root
    property bool animateChange: false

    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    font {
        hintingPreference: Font.PreferFullHinting
        family: Appearance?.font.family.main ?? "sans-serif"
        pixelSize: Appearance?.font.pixelSize.small ?? 15
    }
    color: Appearance?.colors.panelText ?? "white"
}
