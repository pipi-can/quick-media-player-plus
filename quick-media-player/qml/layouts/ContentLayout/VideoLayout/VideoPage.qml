import QtQuick
import "../../../settings"

// 视频页：左边画面加控制条，右边队列加播放信息。比例照 pages 里的原型
Item {
    id: root
    objectName: "video"

    property Theme theme: null

    // 正在播放的那一条，队列的高亮和信息区都跟着它走
    property int currentIndex: 0

    // 原型里的三条假数据，等 PlayList 单例接上就换成它
    readonly property var queueItems: [
        {
            "name": "灰色轨迹",
            "length": "03:24",
            "path": "/home/video/灰色轨迹.mp4",
            "format": "MP4",
            "resolution": "1920×1080",
            "codec": "H.264",
            "decoder": "软解",
            "audio": "AAC · 48 kHz",
            "size": "86.4 MB"
        },
        {
            "name": "1120415067-1-20808",
            "length": "05:01",
            "path": "/data/inbox/1120415067-1-20808.mkv",
            "format": "MKV",
            "resolution": "1280×720",
            "codec": "H.265",
            "decoder": "VAAPI 硬解",
            "audio": "AAC · 立体声",
            "size": "214 MB"
        },
        {
            "name": "125082522_da3-1-16",
            "length": "03:29",
            "path": "/data/inbox/125082522_da3-1-16.mp4",
            "format": "MP4",
            "resolution": "3840×2160",
            "codec": "H.265",
            "decoder": "软解",
            "audio": "AAC · 立体声",
            "size": "1.2 GB"
        }
    ]

    // 队列固定 280，不跟着窗口变。原型是上 8、右 12、下 12
    Item {
        id: queueColumn
        width: 280
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 8
        anchors.rightMargin: 12
        anchors.bottomMargin: 12

        VideoPlaylistArea {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            // 队列和信息卡之间空 8
            anchors.bottom: messageArea.top
            anchors.bottomMargin: 8
            theme: root.theme
            items: root.queueItems
            selectedIndex: root.currentIndex
            playingIndex: root.currentIndex
            onItemSelected: function (index) {
                root.currentIndex = index
            }
        }

        VideoMessageArea {
            id: messageArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            theme: root.theme
            item: root.queueItems[root.currentIndex]
        }
    }

    // 剩下的宽度都给画面，和队列之间空 16
    Item {
        id: stage
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: queueColumn.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.topMargin: 8
        anchors.rightMargin: 16
        anchors.bottomMargin: 12

        VideoPlayArea {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: controlArea.top
            theme: root.theme
        }

        VideoPlayControlArea {
            id: controlArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            theme: root.theme
        }
    }
}
