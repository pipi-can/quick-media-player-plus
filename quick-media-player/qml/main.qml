import QtQuick
import "./layouts"
import "./layouts/TitleBarLayout"
import "./utils"

FramelessWindow {
    id: applicationMainWindow
    title: "QuickMediaPlayer"
    radius: 10

    Utils {
        id: utils
    }

    TitleBar {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
    }

    Component.onCompleted: utils.debug("qml logger ready")
}
