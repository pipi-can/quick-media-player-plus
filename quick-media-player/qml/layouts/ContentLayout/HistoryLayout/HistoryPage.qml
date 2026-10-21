import QtQuick
import QtQuick.Controls
import "../../../settings"

Item {
    id: root
    objectName: "history"

    property Theme theme: null

    Label {
        anchors.centerIn: parent
        text: "历史"
        font.pixelSize: 24
        font.bold: true
        color: root.theme ? root.theme.colorOf("titleNormal") : "#00000000"
    }
}
