import QtQuick
import "../CustomComponents"

Item {
    id: root

    // 和旧标题栏一样高
    height: 60

    // 深色主题：按钮平时灰，悬停和按下都是白；文字白色；图标用主题蓝
    readonly property color iconNormal: "#a3a3a6"
    readonly property color iconHover: "#ffffff"
    readonly property color iconPress: "#ffffff"
    readonly property color titleColor: "#ffffff"
    readonly property color logoColor: "#19adfa"
    // 只有关闭按钮悬停和按下是红的，避免按下去又闪回白色
    readonly property color closeColor: "#e81123"

    // 无边框窗口只能从标题栏空白处拖。写在按钮前面，点按钮时由上层鼠标层接收
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressed: Window.window.startSystemMove()
    }

    ColorImage {
        id: appIcon
        width: 25
        height: 25
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 15
        source: "qrc:/quick-media-player/resources/AppIcons/MainIcon.svg"
        color: root.logoColor
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: appIcon.right
        anchors.leftMargin: 5
        text: "QMediaPlayer"
        color: root.titleColor
        font.pixelSize: 20
        font.bold: true
    }

    Item {
        id: closeButton
        width: 30
        height: 30
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 10

        ColorImage {
            anchors.fill: parent
            source: "qrc:/quick-media-player/resources/TitleBarIcons/close.svg"
            color: closeMouse.color
        }

        MouseStateItem {
            id: closeMouse
            anchors.fill: parent
            normalColor: root.iconNormal
            hoverColor: root.closeColor
            pressColor: root.closeColor
            onClicked: Window.window.close()
        }
    }

    MultiStateItem {
        id: windowMode
        width: 23
        height: 23
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: closeButton.left
        anchors.rightMargin: 10
        stateCount: 2
        defaultState: "maximize"
        // 最大化时显示还原图标，窗口状态变了图标跟着变
        currentState: Window.window.visibility === Window.Maximized ? "normalize" : "maximize"
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

        MouseStateItem {
            id: windowMouse
            anchors.fill: parent
            normalColor: root.iconNormal
            hoverColor: root.iconHover
            pressColor: root.iconPress
            onClicked: {
                if (Window.window.visibility === Window.Maximized)
                    Window.window.showNormal()
                else
                    Window.window.showMaximized()
            }
        }
    }

    Item {
        id: minimizeButton
        width: 23
        height: 23
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: windowMode.left
        anchors.rightMargin: 15

        ColorImage {
            anchors.fill: parent
            source: "qrc:/quick-media-player/resources/TitleBarIcons/minimize.svg"
            color: minimizeMouse.color
        }

        MouseStateItem {
            id: minimizeMouse
            anchors.fill: parent
            normalColor: root.iconNormal
            hoverColor: root.iconHover
            pressColor: root.iconPress
            onClicked: Window.window.showMinimized()
        }
    }
}
