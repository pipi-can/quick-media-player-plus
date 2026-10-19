import QtQuick
import "../CustomComponents"
import "../../settings"

Item {
    id: root

    // 和旧标题栏一样高
    height: 60

    property Theme theme: null

    // 不能标 readonly：ColorAnimation 要逐帧写中间色
    property color windowColor: paint("windowNormal")
    property color titleColor: paint("titleNormal")
    property color iconNormal: paint("iconNormal")
    property color iconHover: paint("iconHover")
    property color iconPress: paint("iconPress")
    property color logoColor: paint("logoNormal")
    property color closeHover: paint("closeHover")
    property color closePress: paint("closePress")

    // 配色没到齐时不缓动，否则启动会从透明色淡过来
    Behavior on windowColor { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }
    Behavior on titleColor { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }
    Behavior on iconNormal { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }
    Behavior on iconHover { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }
    Behavior on iconPress { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }

    function paint(key) {
        if (!theme)
            return "#00000000"
        return theme.colorOf(key)
    }

    Binding {
        target: root.Window.window
        property: "backgroundColor"
        value: root.windowColor
        when: root.Window.window !== null
    }

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
            hoverColor: root.closeHover
            pressColor: root.closePress
            onClicked: Window.window.close()
        }
    }

    MultiStateItem {
        id: windowMode
        width: 23
        height: 23
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: closeButton.left
        anchors.rightMargin: 8
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
        anchors.rightMargin: 13

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

    Seprator {
        id: controlSplit
        width: 1
        height: 15
        radius: width / 2
        color: root.iconNormal
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: minimizeButton.left
        anchors.rightMargin: 15
    }

    Item {
        id: themeButton
        width: 23
        height: 23
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: controlSplit.left
        anchors.rightMargin: 15

        ColorImage {
            anchors.fill: parent
            source: "qrc:/quick-media-player/resources/TitleBarIcons/theme.svg"
            color: themeMouse.color
        }

        MouseStateItem {
            id: themeMouse
            anchors.fill: parent
            normalColor: root.iconNormal
            hoverColor: root.iconHover
            pressColor: root.iconPress
            onClicked: themePopup.opened ? themePopup.close() : themePopup.open()
        }

        ThemePopup {
            id: themePopup
            theme: root.theme
            x: (parent.width - width) / 2
            y: parent.height + 8
        }
    }

    Item {
        id: settingsButton
        width: 24
        height: 24
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: themeButton.left
        anchors.rightMargin: 14

        ColorImage {
            anchors.fill: parent
            source: "qrc:/quick-media-player/resources/TitleBarIcons/settings.svg"
            color: settingsMouse.color
        }

        MouseStateItem {
            id: settingsMouse
            anchors.fill: parent
            normalColor: root.iconNormal
            hoverColor: root.iconHover
            pressColor: root.iconPress
        }
    }
}
