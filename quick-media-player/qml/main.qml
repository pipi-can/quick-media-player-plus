import QtQuick
import "./layouts"
import "./layouts/CustomComponents"
import "./utils"

FramelessWindow {
    id: applicationMainWindow
    title: qsTr("Hello World")
    radius: 10

    Utils {
        id: utils
    }

    MultiStateItem {
        id: windowMode
        width: 36
        height: 36
        anchors.centerIn: parent
        stateCount: 2
        currentState: 0
        stateInfos: [
            { source: "qrc:/quick-media-player/resources/TitleBarIcons/maximize.svg", color: "#d7deea" },
            { source: "qrc:/quick-media-player/resources/TitleBarIcons/normalize.svg", color: "#f0c36a" }
        ]

        ColorImage {
            anchors.fill: parent
        }
    }

    MouseArea {
        anchors.fill: windowMode
        onClicked: windowMode.next()
    }

    Component.onCompleted: utils.debug("qml logger ready")
}
