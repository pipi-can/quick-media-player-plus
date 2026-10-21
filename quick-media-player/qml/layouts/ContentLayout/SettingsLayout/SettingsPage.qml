import QtQuick
import QtQuick.Controls
import "../../../settings"

Item {
    id: root
    objectName: "settings"

    property Theme theme: null

    Label {
        anchors.centerIn: parent
        text: "设置"
        font.pixelSize: 24
        font.bold: true
        color: root.theme ? root.theme.colorOf("titleNormal") : "#00000000"
    }
}
