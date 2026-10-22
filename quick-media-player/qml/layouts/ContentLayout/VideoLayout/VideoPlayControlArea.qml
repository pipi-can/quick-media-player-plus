import QtQuick
import "../../../settings"
import "../../CustomComponents"

// 播放控制区：上面一条进度，下面一排按钮。这一版只画样子，点了不接播放
Item {
    id: root

    property Theme theme: null

    // 进度 0 到 1，后面接上播放器由外面写
    property real progress: 0.18
    property string timeText: "00:07 / 05:27"
    property string modeText: "列表循环"
    property string speedText: "1.0X"
    property bool playing: true

    readonly property color barColor: paint("progressNormal")
    readonly property color dotColor: paint("progressThumb")
    readonly property color textColor: paint("titleNormal")
    readonly property color btnColor: paint("iconNormal")
    readonly property color btnHover: paint("iconHover")
    readonly property color btnPress: paint("iconPress")

    // 按钮 28、图标 18，取自原型 .ico 和 .icon，所以四周各留 5。播放键比它们大一圈
    readonly property real btnSize: 28
    readonly property real iconInset: 5
    readonly property real playBtnSize: 36
    readonly property real playIconInset: 6

    // 进度条 4、间距 8、按钮行 28、底下再留 8
    implicitHeight: 48

    function paint(key) {
        return theme ? theme.colorOf(key) : "#00000000"
    }

    // 进度条本身不填色，只靠圆点表示位置
    Item {
        id: seek
        height: 4
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Rectangle {
            width: parent.width
            height: 4
            radius: 2
            anchors.verticalCenter: parent.verticalCenter
            color: root.barColor
        }

        Rectangle {
            width: 10
            height: 10
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: root.dotColor
            x: root.progress * (parent.width - width)
        }
    }

    Item {
        id: controlRow
        height: 28
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: seek.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 8

        // 上一个
        Item {
            id: prevButton
            width: root.btnSize
            height: root.btnSize
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            ColorImage {
                anchors.fill: parent
                anchors.margins: root.iconInset
                source: "qrc:/quick-media-player/resources/PlayWidgetIcons/lastone.svg"
                color: prevMouse.color
            }

            MouseStateItem {
                id: prevMouse
                anchors.fill: parent
                normalColor: root.btnColor
                hoverColor: root.btnHover
                pressColor: root.btnPress
            }
        }

        // 播放和暂停共用这一个按钮，比旁边的大一圈。图标由 MultiStateItem 按 playing 切，
        // 状态名说的是「正在播 / 已暂停」，画的是点下去会发生什么
        MultiStateItem {
            id: playButton
            width: root.playBtnSize
            height: root.playBtnSize
            anchors.left: prevButton.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            stateCount: 2
            defaultState: "playing"
            currentState: root.playing ? "playing" : "paused"
            stateInfos: [
                { name: "playing" },
                { name: "paused" }
            ]
            items: [pauseIcon, playIcon]

            ColorImage {
                id: pauseIcon
                anchors.fill: parent
                anchors.margins: root.playIconInset
                source: "qrc:/quick-media-player/resources/PlayWidgetIcons/pause.svg"
                color: playMouse.color
            }

            ColorImage {
                id: playIcon
                anchors.fill: parent
                anchors.margins: root.playIconInset
                source: "qrc:/quick-media-player/resources/PlayWidgetIcons/play.svg"
                color: playMouse.color
            }

            MouseStateItem {
                id: playMouse
                anchors.fill: parent
                normalColor: root.btnColor
                hoverColor: root.btnHover
                pressColor: root.btnPress
                // 这一版还没有播放器，点了先自己翻一下；接上播放器后改成把点击交给外面
                onClicked: root.playing = !root.playing
            }
        }

        // 下一个
        Item {
            id: nextButton
            width: root.btnSize
            height: root.btnSize
            anchors.left: playButton.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            ColorImage {
                anchors.fill: parent
                anchors.margins: root.iconInset
                source: "qrc:/quick-media-player/resources/PlayWidgetIcons/nextone.svg"
                color: nextMouse.color
            }

            MouseStateItem {
                id: nextMouse
                anchors.fill: parent
                normalColor: root.btnColor
                hoverColor: root.btnHover
                pressColor: root.btnPress
            }
        }

        Text {
            id: timeLabel
            anchors.left: nextButton.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.timeText
            color: root.textColor
            font.pixelSize: 12
        }

        // 从右往左排，中间剩下的空白就是原型里的 grow
        Item {
            id: volumeButton
            width: root.btnSize
            height: root.btnSize
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            ColorImage {
                anchors.fill: parent
                anchors.margins: root.iconInset
                source: "qrc:/quick-media-player/resources/PlayWidgetIcons/volume.svg"
                color: volumeMouse.color
            }

            MouseStateItem {
                id: volumeMouse
                anchors.fill: parent
                normalColor: root.btnColor
                hoverColor: root.btnHover
                pressColor: root.btnPress
            }
        }

        Text {
            id: speedLabel
            anchors.right: volumeButton.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.speedText
            color: speedMouse.color
            font.pixelSize: 12
            font.bold: true
            // 原型给的是上下 4、左右 8
            leftPadding: 8
            rightPadding: 8
            topPadding: 4
            bottomPadding: 4

            MouseStateItem {
                id: speedMouse
                anchors.fill: parent
                normalColor: root.btnColor
                hoverColor: root.btnHover
                pressColor: root.btnPress
            }
        }

        Text {
            id: modeLabel
            anchors.right: speedLabel.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.modeText
            color: modeMouse.color
            font.pixelSize: 12
            font.bold: true
            leftPadding: 8
            rightPadding: 8
            topPadding: 4
            bottomPadding: 4

            MouseStateItem {
                id: modeMouse
                anchors.fill: parent
                normalColor: root.btnColor
                hoverColor: root.btnHover
                pressColor: root.btnPress
            }
        }
    }
}
