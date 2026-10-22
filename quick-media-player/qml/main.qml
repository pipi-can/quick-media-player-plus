import QtQuick
import "./layouts"
import "./layouts/TitleBarLayout"
import "./layouts/ContentLayout"
import "./settings"
import "./utils"

FramelessWindow {
    id: applicationMainWindow
    title: "QuickMediaPlayer"
    radius: 8
    visible: theme.ready

    Theme {
        id: theme
    }

    Utils {
        id: utils
    }

    TitleBar {
        id: titleBar
        theme: theme
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
    }

    ContentWidget {
        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        theme: theme
        currentPage: titleBar.currentPage
    }

    Component.onCompleted: {
        // 只放一次。绑在屏幕尺寸上的话，拖动窗口会被拉回正中
        x = (screen.width - width) / 2
        y = (screen.height - height) / 2
        utils.debug("qml logger ready")
    }
}
