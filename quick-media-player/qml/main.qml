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
        defaultState: "maximize"
        currentState: "maximize"
        stateInfos: [
            { name: "maximize" },
            { name: "normalize" }
        ]
        items: [ maximizeIcon, normalizeIcon ]

        ColorImage {
            id: maximizeIcon
            anchors.fill: parent
            source: "qrc:/quick-media-player/resources/TitleBarIcons/maximize.svg"
            color: windowMouse.color
        }
        ColorImage {
            id: normalizeIcon
            anchors.fill: parent
            source: "qrc:/quick-media-player/resources/TitleBarIcons/normalize.svg"
            color: windowMouse.color
        }
    }

    MouseStateItem {
        id: windowMouse
        anchors.fill: windowMode
        normalColor: "#d7deea"
        hoverColor: "#ffffff"
        pressColor: "#f0c36a"
        onClicked: windowMode.next()
    }

    Component.onCompleted: utils.debug("qml logger ready")
}
