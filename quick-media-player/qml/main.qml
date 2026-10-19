import QtQuick
import "./layouts"
import "./layouts/TitleBarLayout"
import "./settings"
import "./utils"

FramelessWindow {
    id: applicationMainWindow
    title: "QuickMediaPlayer"
    radius: 10
    visible: theme.ready

    Theme {
        id: theme
    }

    Utils {
        id: utils
    }

    TitleBar {
        theme: theme
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
    }

    Component.onCompleted: utils.debug("qml logger ready")
}
