import QtQuick
import "../CustomComponents"
import "../../settings"

// 标题栏中间的四个页面入口。这里只负责选中和悬停，不切换页面
Item {
    id: root

    // 和原型 .nav 一样宽高
    width: 328
    height: 30

    property Theme theme: null
    // -1 是设置页，四个胶囊都不选中
    property int currentIndex: 0
    readonly property string currentPage: {
        if (currentIndex < 0)
            return "settings"
        if (pages.count === 0)
            return ""
        return pages.get(currentIndex).name
    }

    property color textNormal: paint("navTextNormal")
    property color textHover: paint("navTextHover")
    property color textOn: paint("navTextOn")
    property color fillNormal: paint("navFillNormal")
    property color fillHover: paint("navFillHover")
    property color fillOn: paint("navFillOn")
    property color fillPress: paint("navFillPress")

    // 配色没到齐时不缓动。悬停是换用哪一套颜色，不走这段动画
    Behavior on textNormal { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }
    Behavior on textHover { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }
    Behavior on textOn { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }
    Behavior on fillNormal { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }
    Behavior on fillHover { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }
    Behavior on fillOn { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }
    Behavior on fillPress { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }

    function paint(key) {
        if (!theme)
            return "#00000000"
        return theme.colorOf(key)
    }

    ListModel {
        id: pages
        ListElement { name: "video"; caption: "视频" }
        ListElement { name: "music"; caption: "音乐" }
        ListElement { name: "history"; caption: "历史" }
        ListElement { name: "share"; caption: "共享" }
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: pages

            delegate: Item {
                width: root.width / pages.count
                height: root.height

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    // 选中时悬停保持选中色，和原型 pill:hover:not(.is-on) 一样
                    color: {
                        var on = root.currentIndex === index
                        var down = pillMouse.pressed && pillMouse.containsMouse
                        if (on)
                            return down ? root.fillPress : root.fillOn
                        if (pillMouse.containsMouse)
                            return root.fillHover
                        return root.fillNormal
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: caption
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 3
                    color: {
                        if (root.currentIndex === index)
                            return root.textOn
                        if (pillMouse.containsMouse)
                            return root.textHover
                        return root.textNormal
                    }
                }

                MouseStateItem {
                    id: pillMouse
                    anchors.fill: parent
                    onClicked: root.currentIndex = index
                }
            }
        }
    }
}
