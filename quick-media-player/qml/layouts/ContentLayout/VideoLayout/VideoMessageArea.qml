pragma ComponentBehavior: Bound

import QtQuick
import "../../../settings"
import "../../CustomComponents"

// 播放信息区：一行文件名加「详情」，点开是四行具体参数
Item {
    id: root

    property Theme theme: null

    // 当前这一项的信息，字段见 VideoPage 里的假数据
    property var item: null

    // 默认收起，点「详情」才铺开四行
    property bool detailOpen: false

    readonly property color cardColor: paint("popupNormal")
    readonly property color cardEdge: paint("popupBorder")
    readonly property color textColor: paint("titleNormal")
    readonly property color mutedColor: paint("navTextNormal")
    readonly property color accentColor: paint("logoNormal")
    readonly property color pressFill: paint("queueItemHover")

    // 一行里放格式、分辨率、体积，和原型一样用点隔开
    readonly property string brief: root.item
            ? [root.item.format, root.item.resolution, root.item.size].join(" · ") : ""

    readonly property var rows: [
        { "label": "路径", "value": root.item ? root.item.path : "" },
        { "label": "视频编码", "value": root.item ? root.item.codec : "" },
        { "label": "解码器", "value": root.item ? root.item.decoder : "" },
        { "label": "音频", "value": root.item ? root.item.audio : "" }
    ]

    // 卡片高度跟着内容走，外面按 implicitHeight 摆
    implicitHeight: card.height

    function paint(key) {
        return theme ? theme.colorOf(key) : "#00000000"
    }

    Rectangle {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        // 上下各 12 的内边距，行数变了高度跟着变
        height: body.height + 24
        radius: 8
        color: root.cardColor
        border.width: 1
        border.color: root.cardEdge

        Item {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            height: head.height + 4 + briefLabel.height
                    + (detailRows.visible ? 8 + detailRows.height : 0)

            Item {
                id: head
                width: parent.width
                height: Math.max(nameLabel.height, moreButton.height)

                Text {
                    id: nameLabel
                    anchors.left: parent.left
                    anchors.right: moreButton.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.item ? root.item.name : ""
                    elide: Text.ElideRight
                    color: root.textColor
                    font.pixelSize: 13
                    font.bold: true
                }

                // 点击范围比两个字大一圈，和图标按钮一样按下垫底色
                Item {
                    id: moreButton
                    width: moreLabel.width + 8
                    height: moreLabel.height + 8
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: moreMouse.mouseState === "press" ? root.pressFill : "transparent"
                    }

                    Text {
                        id: moreLabel
                        anchors.centerIn: parent
                        text: root.detailOpen ? "收起" : "详情"
                        color: root.accentColor
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseStateItem {
                        id: moreMouse
                        anchors.fill: parent
                        onClicked: root.detailOpen = !root.detailOpen
                    }
                }
            }

            Text {
                id: briefLabel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: head.bottom
                anchors.topMargin: 4
                text: root.brief
                elide: Text.ElideRight
                color: root.mutedColor
                font.pixelSize: 12
            }

            Column {
                id: detailRows
                visible: root.detailOpen
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: briefLabel.bottom
                anchors.topMargin: 8

                Repeater {
                    model: root.rows

                    delegate: Item {
                        id: detailRow

                        required property var modelData

                        width: detailRows.width
                        height: 18

                        Text {
                            id: rowLabel
                            width: 60
                            anchors.verticalCenter: parent.verticalCenter
                            text: detailRow.modelData.label
                            color: root.mutedColor
                            font.pixelSize: 12
                        }

                        Text {
                            anchors.left: rowLabel.right
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: detailRow.modelData.value
                            elide: Text.ElideRight
                            color: root.textColor
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
