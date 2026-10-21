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

    Component.onCompleted: {
        // 只放一次。绑在屏幕尺寸上的话，拖动窗口会被拉回正中
        x = (screen.width - width) / 2
        y = (screen.height - height) / 2
        utils.debug("qml logger ready")
    }
}
