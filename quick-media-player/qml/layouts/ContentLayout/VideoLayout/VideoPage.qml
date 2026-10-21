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
    // 还没接解码。点播放只切换这块画面的大小
    property bool playing: false
    property bool detailOpen: false
    property int dragFrom: -1
    property real dragGhostY: 0
    property real dragRowY: 0
    property real dragPressY: 0
    property color stageColor: paint("stageNormal")
    property color wellColor: paint("windowNormal")
    property color screenEdge: paint("stageBorder")

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

    // to 用的是这条最终要落在的位置
    function moveQueue(from, to) {
        if (from === to || from < 0 || to < 0)
            return
        if (from >= queueModel.count || to >= queueModel.count)
            return
        queueModel.move(from, to, 1)
        queueIndex = to
    }

    // 队列点中的那一条。字段是样子，等以后用真实媒体信息换
    function fileField(key) {
        if (queueIndex < 0 || queueIndex >= queueModel.count)
            return ""
        var value = queueModel.get(queueIndex)[key]
        return value === undefined ? "" : value
    }

    ListModel {
        id: queueModel
        ListElement {
            title: "播放中：灰色轨迹"
            length: "03:24"
            file: "灰色轨迹.mp4"
            path: "/home/video/灰色轨迹.mp4"
            format: "MP4"
            resolution: "1920×1080"
            codec: "H.264"
            decoder: "软解"
            audio: "AAC · 48 kHz"
            size: "86.4 MB"
        }
        ListElement {
            title: "1120415067-1-20808"
            length: "05:01"
            file: "1120415067-1-20808.mkv"
            path: "/data/inbox/1120415067-1-20808.mkv"
            format: "MKV"
            resolution: "1280×720"
            codec: "H.265"
            decoder: "VAAPI 硬解"
            audio: "AAC · 立体声"
            size: "214 MB"
        }
        ListElement {
            title: "125082522_da3-1-16"
            length: "03:29"
            file: "125082522_da3-1-16.mp4"
            path: "/data/inbox/125082522_da3-1-16.mp4"
            format: "MP4"
            resolution: "3840×2160"
            codec: "H.265"
            decoder: "软解"
            audio: "AAC · 立体声"
            size: "1.2 GB"
        }
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

        // 空白区是控制条以上。画面保持 16:9，空着只占这块能放下的 0.618
        Item {
            id: blank
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: controls.top

            Rectangle {
                id: screen
                anchors.centerIn: parent
                readonly property real fitWidth: Math.min(blank.width, blank.height * 16 / 9)
                width: fitWidth * (root.playing ? 1 : 0.618)
                height: width * 9 / 16
                radius: 6
                color: root.stageColor
                border.width: 1
                border.color: root.screenEdge

                Column {
                    visible: !root.playing
                    anchors.centerIn: parent
                    spacing: 14
                    width: Math.max(0, parent.width - 48)

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
                        color: root.paint("stageText")
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
                    source: root.playing
                           ? "qrc:/quick-media-player/resources/PlayWidgetIcons/pause.svg"
                           : "qrc:/quick-media-player/resources/PlayWidgetIcons/play.svg"
                    onClicked: root.playing = !root.playing
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
            anchors.bottom: fileCard.top
            anchors.bottomMargin: 10
            contentHeight: queueCol.height
            clip: true

            Column {
                id: queueCol
                width: parent.width
                spacing: 4

                Repeater {
                    model: queueModel

                    delegate: Item {
                        id: row
                        width: queueCol.width
                        height: 58
                        // 选中盖过悬停，两块蓝才分得开
                        readonly property bool selected: index === root.queueIndex
                        property bool dragged: false
                        opacity: root.dragFrom === index ? 0.35 : 1

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: selected ? root.paint("queueItemOn")
                                            : (rowMouse.containsMouse ? root.paint("queueItemHover") : "transparent")
                            border.width: 1
                            border.color: selected ? root.paint("queueItemBorder") : "transparent"
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

                        Text {
                            x: 58
                            width: parent.width - 68
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: -8
                            text: title
                            elide: Text.ElideRight
                            font.pixelSize: 13
                            color: root.paint("titleNormal")
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: 8
                            anchors.bottomMargin: 6
                            text: length
                            font.pixelSize: 12
                            color: root.paint("navTextNormal")
                        }

                        MouseStateItem {
                            id: rowMouse
                            anchors.fill: parent
                            preventStealing: true
                            normalColor: "transparent"
                            hoverColor: "transparent"
                            pressColor: "transparent"
                            onPressed: function (mouse) {
                                root.dragFrom = index
                                root.dragRowY = row.y
                                root.dragPressY = row.mapToItem(queueCol, mouse.x, mouse.y).y
                                root.dragGhostY = row.y
                                row.dragged = false
                            }
                            onPositionChanged: function (mouse) {
                                if (root.dragFrom !== index)
                                    return
                                var y = row.mapToItem(queueCol, mouse.x, mouse.y).y
                                root.dragGhostY = root.dragRowY + (y - root.dragPressY)
                                if (Math.abs(root.dragGhostY - root.dragRowY) > 6)
                                    row.dragged = true
                            }
                            onReleased: {
                                var from = root.dragFrom
                                var moved = row.dragged
                                root.dragFrom = -1
                                if (!moved || from !== index)
                                    return
                                var dest = Math.round(root.dragGhostY / (row.height + queueCol.spacing))
                                if (dest < 0)
                                    dest = 0
                                if (dest >= queueModel.count)
                                    dest = queueModel.count - 1
                                root.moveQueue(from, dest)
                            }
                            onClicked: {
                                if (row.dragged) {
                                    row.dragged = false
                                    return
                                }
                                root.queueIndex = index
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.dragFrom >= 0
                x: 0
                y: root.dragGhostY
                z: 3
                width: queueCol.width
                height: 58
                radius: 6
                color: root.paint("queueItemOn")
                border.width: 1
                border.color: root.paint("logoNormal")

                Text {
                    x: 58
                    width: parent.width - 70
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.dragFrom >= 0 ? queueModel.get(root.dragFrom).title : ""
                    elide: Text.ElideRight
                    font.pixelSize: 13
                    color: root.paint("titleNormal")
                }
            }
        }

        Item {
            id: fileCard
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: fileCol.height

            Column {
                id: fileCol
                width: parent.width
                spacing: 4

                Item {
                    width: parent.width
                    height: 18

                    Text {
                        anchors.left: parent.left
                        anchors.right: detailHit.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.fileField("file")
                        elide: Text.ElideMiddle
                        font.pixelSize: 13
                        font.bold: true
                        color: root.paint("titleNormal")
                    }

                    Item {
                        id: detailHit
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: detailText.implicitWidth
                        height: 18

                        Text {
                            id: detailText
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.detailOpen ? "收起" : "详情"
                            font.pixelSize: 12
                            font.bold: true
                            color: root.paint("logoNormal")
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.detailOpen = !root.detailOpen
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: root.fileField("format") + " · " + root.fileField("resolution") + " · " + root.fileField("size")
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    color: root.paint("navTextNormal")
                }

                Column {
                    visible: root.detailOpen
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: [
                            { name: "路径", key: "path" },
                            { name: "视频编码", key: "codec" },
                            { name: "解码器", key: "decoder" },
                            { name: "音频", key: "audio" }
                        ]

                        delegate: Item {
                            width: fileCol.width
                            height: 18

                            Text {
                                width: 60
                                text: modelData.name
                                font.pixelSize: 12
                                color: root.paint("navTextNormal")
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                x: 60
                                width: parent.width - 60
                                text: root.fileField(modelData.key)
                                elide: modelData.key === "path" ? Text.ElideMiddle : Text.ElideRight
                                font.pixelSize: 12
                                color: root.paint("titleNormal")
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    component IconButton: Item {
        id: button
        property alias source: icon.source
        signal clicked()
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
            onClicked: button.clicked()
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
