import QtQuick
import QtQuick.Controls
import "../../../settings"
import "../../CustomComponents"

// 按 pages 里的视频页摆界面。时间和队列是样子，不接播放
Item {
    id: root
    objectName: "video"

    property Theme theme: null
    property string modeName: "列表循环"
    property string speedName: "1.0X"
    property bool modeOpen: false
    property bool speedOpen: false
    property bool volOpen: false
    property int queueIndex: 0
    property color stageColor: paint("stageNormal")
    property color wellColor: paint("windowNormal")
    property color screenEdge: paint("popupBorder")

    Behavior on stageColor {
        enabled: theme && theme.ready
        ColorAnimation { duration: 560; easing.type: Easing.InOutCubic }
    }
    Behavior on wellColor {
        enabled: theme && theme.ready
        ColorAnimation { duration: 560; easing.type: Easing.InOutCubic }
    }
    Behavior on screenEdge {
        enabled: theme && theme.ready
        ColorAnimation { duration: 560; easing.type: Easing.InOutCubic }
    }

    function paint(key) {
        if (!theme)
            return "#00000000"
        return theme.colorOf(key)
    }

    function closePops() {
        modeOpen = false
        speedOpen = false
        volOpen = false
    }

    ListModel {
        id: queueModel
        ListElement { title: "播放中：灰色轨迹"; length: "03:24" }
        ListElement { title: "1120415067-1-20808"; length: "05:01" }
        ListElement { title: "125082522_da3-1-16"; length: "03:29" }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.modeOpen || root.speedOpen || root.volOpen
        onClicked: root.closePops()
    }

    Item {
        id: stage
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: queue.left
        anchors.leftMargin: 10
        anchors.rightMargin: 15
        anchors.topMargin: 8
        anchors.bottomMargin: 10

        Rectangle {
            anchors.fill: parent
            radius: 5
            color: root.wellColor
        }

        // 没片子时黑只留在这块 16:9 里，旁边用窗口色，避免一整面空黑
        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: controls.top
            anchors.margins: 24

            Rectangle {
                id: screen
                anchors.centerIn: parent
                // 空的时候不要铺满，留一圈窗口色，黑才像一块屏幕
                width: Math.min(parent.width, parent.height * 16 / 9, 640)
                height: width * 9 / 16
                radius: 6
                color: root.stageColor
                border.width: 1
                border.color: root.screenEdge

                Column {
                    anchors.centerIn: parent
                    spacing: 14
                    width: parent.width - 48

                    ColorImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 36
                        height: 36
                        source: "qrc:/quick-media-player/resources/PlayWidgetIcons/play.svg"
                        color: root.paint("logoNormal")
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "拖入视频，或点右侧加号加入队列"
                        font.pixelSize: 13
                        color: root.paint("navTextNormal")
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        Item {
            id: controls
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            anchors.bottomMargin: 8
            height: seek.height + ctrlRow.height + 6

            Slider {
                id: seek
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 14
                padding: 0
                from: 0
                to: 100
                value: 18

                background: Rectangle {
                    x: seek.leftPadding
                    y: seek.topPadding + seek.availableHeight / 2 - height / 2
                    width: seek.availableWidth
                    height: 4
                    radius: 2
                    color: root.paint("progressNormal")
                }

                handle: Rectangle {
                    x: seek.leftPadding + seek.visualPosition * (seek.availableWidth - width)
                    y: seek.topPadding + seek.availableHeight / 2 - height / 2
                    width: 10
                    height: 10
                    radius: 5
                    color: root.paint("logoNormal")
                }
            }

            Item {
                id: ctrlRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 28

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    IconButton {
                    source: "qrc:/quick-media-player/resources/PlayWidgetIcons/lastone.svg"
                }
                IconButton {
                    source: "qrc:/quick-media-player/resources/PlayWidgetIcons/play.svg"
                }
                IconButton {
                    source: "qrc:/quick-media-player/resources/PlayWidgetIcons/nextone.svg"
                }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "00:07 / 05:27"
                        font.pixelSize: 11
                        color: root.paint("titleNormal")
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Item {
                    id: modeHost
                    width: modeText.width
                    height: 28

                    Text {
                        id: modeText
                        anchors.centerIn: parent
                        text: root.modeName
                        font.pixelSize: 11
                        font.bold: true
                        color: modeMouse.containsMouse ? root.paint("iconHover") : root.paint("iconNormal")
                    }

                    MouseStateItem {
                        id: modeMouse
                        anchors.fill: parent
                        normalColor: "transparent"
                        hoverColor: "transparent"
                        pressColor: "transparent"
                        onClicked: {
                            var was = root.modeOpen
                            root.closePops()
                            root.modeOpen = !was
                        }
                    }

                    ChoiceMenu {
                        visible: root.modeOpen
                        width: 140
                        choices: ["顺序播放", "列表循环", "播完即停", "单曲循环", "随机播放"]
                        current: root.modeName
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 6
                        anchors.right: parent.right
                        onPicked: function (name) {
                            root.modeName = name
                            root.modeOpen = false
                        }
                    }
                }

                Item {
                    id: speedHost
                    width: speedText.width
                    height: 28

                    Text {
                        id: speedText
                        anchors.centerIn: parent
                        text: root.speedName
                        font.pixelSize: 11
                        font.bold: true
                        color: speedMouse.containsMouse ? root.paint("iconHover") : root.paint("iconNormal")
                    }

                    MouseStateItem {
                        id: speedMouse
                        anchors.fill: parent
                        normalColor: "transparent"
                        hoverColor: "transparent"
                        pressColor: "transparent"
                        onClicked: {
                            var was = root.speedOpen
                            root.closePops()
                            root.speedOpen = !was
                        }
                    }

                    ChoiceMenu {
                        visible: root.speedOpen
                        width: 80
                        choices: ["0.75X", "1.0X", "1.5X", "2.0X"]
                        current: root.speedName
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 6
                        anchors.right: parent.right
                        onPicked: function (name) {
                            root.speedName = name
                            root.speedOpen = false
                        }
                    }
                }

                Item {
                    id: volHost
                    width: 28
                    height: 28

                    SpeakerIcon {
                        anchors.centerIn: parent
                        color: volMouse.color
                    }

                    MouseStateItem {
                        id: volMouse
                        anchors.fill: parent
                        normalColor: root.paint("iconNormal")
                        hoverColor: root.paint("iconHover")
                        pressColor: root.paint("iconPress")
                        onClicked: {
                            var was = root.volOpen
                            root.closePops()
                            root.volOpen = !was
                        }
                    }

                    Rectangle {
                        visible: root.volOpen
                        width: 30
                        height: 100
                        radius: 6
                        color: root.paint("popupNormal")
                        border.color: root.paint("popupBorder")
                        border.width: 1
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            text: "70%"
                            font.pixelSize: 10
                            font.bold: true
                            color: root.paint("titleNormal")
                        }

                        Rectangle {
                            width: 4
                            height: 64
                            radius: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 26
                            color: root.paint("progressNormal")

                            Rectangle {
                                width: parent.width
                                height: parent.height * 0.7
                                radius: 2
                                anchors.bottom: parent.bottom
                                color: root.paint("logoNormal")
                            }
                        }
                    }
                }

                Item {
                    width: 28
                    height: 28

                    FullIcon {
                        anchors.centerIn: parent
                        color: fullMouse.color
                    }

                    MouseStateItem {
                        id: fullMouse
                        anchors.fill: parent
                        normalColor: root.paint("iconNormal")
                        hoverColor: root.paint("iconHover")
                        pressColor: root.paint("iconPress")
                    }
                }
            }
        }
    }
    }

    Item {
        id: queue
        width: 280
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 8
        anchors.rightMargin: 10
        anchors.bottomMargin: 10

        Item {
            id: queueHead
            width: parent.width
            height: 28

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "播放队列"
                font.pixelSize: 15
                font.bold: true
                font.letterSpacing: 1
                color: root.paint("titleNormal")
            }

            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:/quick-media-player/resources/PlayWidgetIcons/add.svg"
            }
        }

        Flickable {
            anchors.top: queueHead.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            contentHeight: queueCol.height
            clip: true

            Column {
                id: queueCol
                width: parent.width

                Repeater {
                    model: queueModel

                    delegate: Item {
                        width: queueCol.width
                        height: 58

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: highlighted ? root.paint("queueItemOn") : "transparent"
                            border.width: 1
                            border.color: highlighted ? root.paint("queueItemBorder") : "transparent"
                        }

                        Rectangle {
                            x: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42
                            height: 42
                            radius: 21
                            color: root.paint("videoThumb")

                            ColorImage {
                                anchors.centerIn: parent
                                width: 14
                                height: 14
                                source: "qrc:/quick-media-player/resources/PlayWidgetIcons/play.svg"
                                color: root.paint("videoThumbIcon")
                            }
                        }

                        Column {
                            x: 58
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 66

                            Text {
                                width: parent.width
                                text: title
                                elide: Text.ElideRight
                                font.pixelSize: 13
                                color: root.paint("titleNormal")
                            }
                            Text {
                                text: length
                                font.pixelSize: 12
                                color: root.paint("navTextNormal")
                            }
                        }

                        MouseStateItem {
                            id: rowMouse
                            anchors.fill: parent
                            normalColor: "transparent"
                            hoverColor: "transparent"
                            pressColor: "transparent"
                            onClicked: root.queueIndex = index
                        }

                        property bool highlighted: index === root.queueIndex || rowMouse.containsMouse
                    }
                }
            }
        }
    }

    component IconButton: Item {
        id: button
        property alias source: icon.source
        width: 28
        height: 28

        ColorImage {
            id: icon
            anchors.centerIn: parent
            width: 18
            height: 18
            color: mouse.color
        }

        MouseStateItem {
            id: mouse
            anchors.fill: parent
            normalColor: root.paint("iconNormal")
            hoverColor: root.paint("iconHover")
            pressColor: root.paint("iconPress")
        }
    }

    component ChoiceMenu: Rectangle {
        id: menu
        property var choices: []
        property string current: ""
        signal picked(string name)

        color: root.paint("popupNormal")
        border.color: root.paint("popupBorder")
        border.width: 1
        height: menuCol.height
        z: 4

        Column {
            id: menuCol
            width: parent.width

            Repeater {
                model: menu.choices

                delegate: Rectangle {
                    width: menu.width
                    height: 33
                    color: choiceMouse.containsMouse ? root.paint("popupHover") : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 11
                        font.bold: true
                        color: modelData === menu.current ? root.paint("logoNormal") : root.paint("titleNormal")
                    }

                    MouseStateItem {
                        id: choiceMouse
                        anchors.fill: parent
                        normalColor: "transparent"
                        hoverColor: "transparent"
                        pressColor: "transparent"
                        onClicked: menu.picked(modelData)
                    }
                }
            }
        }
    }

    component SpeakerIcon: Item {
        property color color: "#ffffff"
        width: 18
        height: 18

        Rectangle {
            x: 1
            y: 6
            width: 4
            height: 6
            color: parent.color
        }
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = parent.color
                ctx.beginPath()
                ctx.moveTo(5, 6)
                ctx.lineTo(10, 3)
                ctx.lineTo(10, 15)
                ctx.lineTo(5, 12)
                ctx.closePath()
                ctx.fill()
            }
            onColorChanged: requestPaint()
            property color color: parent.color
        }
        Rectangle {
            x: 12
            y: 5
            width: 1.5
            height: 8
            radius: 1
            color: parent.color
        }
        Rectangle {
            x: 15
            y: 3
            width: 1.5
            height: 12
            radius: 1
            color: parent.color
        }
    }

    component FullIcon: Item {
        id: fullIcon
        property color color: "#ffffff"
        width: 18
        height: 18

        Repeater {
            model: [
                { x: 2, y: 2, w: 5, h: 1.6 },
                { x: 2, y: 2, w: 1.6, h: 5 },
                { x: 11, y: 2, w: 5, h: 1.6 },
                { x: 14.4, y: 2, w: 1.6, h: 5 },
                { x: 2, y: 14.4, w: 5, h: 1.6 },
                { x: 2, y: 11, w: 1.6, h: 5 },
                { x: 11, y: 14.4, w: 5, h: 1.6 },
                { x: 14.4, y: 11, w: 1.6, h: 5 }
            ]
            delegate: Rectangle {
                x: modelData.x
                y: modelData.y
                width: modelData.w
                height: modelData.h
                color: fullIcon.color
            }
        }
    }
}
