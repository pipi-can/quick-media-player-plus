pragma ComponentBehavior: Bound

import QtQuick
import "../../../settings"
import "../../CustomComponents"

// 播放队列区：一行标题加一个加号，下面整列都是队列
Item {
    id: root

    property Theme theme: null

    // 队列内容，每项要有 name 和 length。这一版由外面喂假数据
    property var items: []

    // 高亮的那一行。外面写，这里只读，点了由 itemSelected 交出去
    property int selectedIndex: 0

    // 正在播放的那一行，行尾标「正在播放」
    property int playingIndex: 0

    signal itemSelected(int index)

    readonly property color titleColor: paint("titleNormal")
    readonly property color itemColor: paint("queueItemOn")
    readonly property color hoverColor: paint("queueItemHover")
    readonly property color markColor: paint("queueMark")
    readonly property color mutedColor: paint("navTextNormal")
    readonly property color thumbColor: paint("videoThumb")
    readonly property color thumbIconColor: paint("videoThumbIcon")
    readonly property color btnColor: paint("iconNormal")
    readonly property color btnHover: paint("iconHover")
    readonly property color btnPress: paint("iconPress")

    function paint(key) {
        return theme ? theme.colorOf(key) : "#00000000"
    }

    // 标题行：上 4、下 8，加号 28，所以整行 40
    Item {
        id: head
        height: 40
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: addButton.verticalCenter
            text: "播放队列"
            color: root.titleColor
            font.pixelSize: 15
            font.bold: true
            font.letterSpacing: 1
        }

        // 加号：原型 .ico 是 28 的按钮配 18 的图标，所以图标四周各留 5
        Item {
            id: addButton
            width: 28
            height: 28
            y: 4
            anchors.right: parent.right
            anchors.rightMargin: 8

            ColorImage {
                anchors.fill: parent
                anchors.margins: 5
                source: "qrc:/quick-media-player/resources/PlayWidgetIcons/add.svg"
                color: addMouse.color
            }

            MouseStateItem {
                id: addMouse
                anchors.fill: parent
                normalColor: root.btnColor
                hoverColor: root.btnHover
                pressColor: root.btnPress
            }
        }
    }

    ListView {
        id: queueView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: head.bottom
        anchors.bottom: parent.bottom
        clip: true
        spacing: 4
        model: root.items

        delegate: Item {
            id: row

            required property int index
            required property var modelData

            width: queueView.width
            height: 58

            readonly property bool isSelected: row.index === root.selectedIndex
            readonly property bool isPlaying: row.index === root.playingIndex

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: row.isSelected ? root.itemColor
                                      : (rowMouse.containsMouse ? root.hoverColor : "transparent")
            }

            // 选中的左边一条竖标记，和悬停的中性灰不靠深浅区分
            Rectangle {
                visible: row.isSelected
                width: 3
                height: parent.height
                radius: width / 2
                color: root.markColor
            }

            // 缩略图是个深色圆加白播放图标，队列里还没有真帧
            Rectangle {
                id: thumb
                x: 8
                y: 8
                width: 42
                height: 42
                radius: width / 2
                color: root.thumbColor

                ColorImage {
                    width: 14
                    height: 14
                    anchors.centerIn: parent
                    source: "qrc:/quick-media-player/resources/PlayWidgetIcons/play.svg"
                    color: root.thumbIconColor
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 58
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.top: parent.top
                anchors.topMargin: 14
                text: row.modelData ? row.modelData.name : ""
                elide: Text.ElideRight
                color: root.titleColor
                font.pixelSize: 13
            }

            Text {
                visible: row.isPlaying
                anchors.left: parent.left
                anchors.leftMargin: 58
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                text: "正在播放"
                color: root.titleColor
                font.pixelSize: 12
                font.bold: true
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                text: row.modelData ? row.modelData.length : ""
                color: root.mutedColor
                font.pixelSize: 12
            }

            MouseStateItem {
                id: rowMouse
                anchors.fill: parent
                onClicked: root.itemSelected(row.index)
            }
        }
    }
}
