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

        Item {
            anchors.fill: parent
            // 平时 90%，悬停放到 100%。从中心缩，图标才不会往左上角飘
            transformOrigin: Item.Center
            scale: closeMouse.containsMouse ? 1 : 0.9
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            ColorImage {
                anchors.fill: parent
                source: "qrc:/quick-media-player/resources/TitleBarIcons/close.svg"
                color: closeMouse.color
            }
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

        Item {
            anchors.fill: parent
            transformOrigin: Item.Center
            scale: windowMouse.containsMouse ? 1 : 0.9
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

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

        Item {
            anchors.fill: parent
            transformOrigin: Item.Center
            scale: minimizeMouse.containsMouse ? 1 : 0.9
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            ColorImage {
                anchors.fill: parent
                source: "qrc:/quick-media-player/resources/TitleBarIcons/minimize.svg"
                color: minimizeMouse.color
            }
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

        Item {
            anchors.fill: parent
            transformOrigin: Item.Center
            scale: themeMouse.containsMouse ? 1 : 0.9
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            ColorImage {
                anchors.fill: parent
                source: "qrc:/quick-media-player/resources/TitleBarIcons/theme.svg"
                color: themeMouse.color
            }
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

        Item {
            id: settingsIcon
            // 进入和离开各加一圈。读 rotation 会读到动画中的角度，所以用 spin 累加
            property real spin: 0
            anchors.fill: parent
            transformOrigin: Item.Center
            scale: settingsMouse.containsMouse ? 1 : 0.9
            rotation: spin
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on rotation {
                RotationAnimation { duration: 200; direction: RotationAnimation.Clockwise }
            }

            ColorImage {
                anchors.fill: parent
                source: "qrc:/quick-media-player/resources/TitleBarIcons/settings.svg"
                color: settingsMouse.color
            }
        }

        MouseStateItem {
            id: settingsMouse
            anchors.fill: parent
            normalColor: root.iconNormal
            hoverColor: root.iconHover
            pressColor: root.iconPress
            onContainsMouseChanged: settingsIcon.spin += 360
        }
    }
}
