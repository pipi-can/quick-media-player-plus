pragma ComponentBehavior: Bound

import QtQuick
import "../../../settings"
import "../../CustomComponents"

// 播放区：空白区正中一块 16:9 的画面，没在播时只占最大尺寸的 0.618
Item {
    id: root

    property Theme theme: null

    // 五个画面只换内容，不代表已经在解码
    property string screenState: "empty"

    readonly property color stageColor: paint("stageNormal")
    readonly property color stageInk: paint("stageText")
    readonly property color stageEdge: paint("stageBorder")

    // 画面同时受宽和高约束，取小的那条，正好是 16:9
    readonly property real fitWidth: Math.min(width, height * 16 / 9)

    function paint(key) {
        return theme ? theme.colorOf(key) : "#00000000"
    }

    Rectangle {
        id: screen
        anchors.centerIn: parent
        width: root.screenState === "playing" ? root.fitWidth : root.fitWidth * 0.618
        height: width * 9 / 16
        radius: 8
        color: root.stageColor
        border.width: 1
        border.color: root.stageEdge

        MultiStateItem {
            anchors.fill: parent
            stateCount: 5
            stateInfos: [
                { "name": "empty" },
                { "name": "loading" },
                { "name": "paused" },
                { "name": "playing" },
                { "name": "error" }
            ]
            items: [emptyFace, loadingFace, pausedFace, playingFace, errorFace]
            defaultState: "empty"
            currentState: root.screenState

            // 图标加一行说明，几个画面只有内容不同。没有图标的状态只写一行字
            component Face: Column {
                property alias iconSource: faceIcon.source
                property string caption: ""
                anchors.centerIn: parent
                spacing: 16

                ColorImage {
                    id: faceIcon
                    width: 36
                    height: 36
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.stageInk
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.caption
                    color: root.stageInk
                    font.pixelSize: 13
                }
            }

            Face {
                id: emptyFace
                iconSource: "qrc:/quick-media-player/resources/PlayWidgetIcons/play.svg"
                caption: "还没有视频。点右侧加号加入队列"
            }

            Face {
                id: loadingFace
                caption: "正在打开"
            }

            Face {
                id: pausedFace
                iconSource: "qrc:/quick-media-player/resources/PlayWidgetIcons/pause.svg"
                caption: "已暂停"
            }

            // 播放中不盖东西，画面让给视频
            Face {
                id: playingFace
            }

            Face {
                id: errorFace
                iconSource: "qrc:/quick-media-player/resources/AppIcons/error.svg"
                caption: "打不开这个视频"
            }
        }
    }
}
