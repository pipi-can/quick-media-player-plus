import QtQuick
import QtQuick.Controls
import "../../../settings"

Item {
    id: root
    objectName: "music"

    property Theme theme: null

    Label {
        anchors.centerIn: parent
        text: "音乐"
        font.pixelSize: 24
        font.bold: true
        color: root.theme ? root.theme.colorOf("titleNormal") : "#00000000"
    }
}
