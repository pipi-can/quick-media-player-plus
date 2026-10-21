import QtQuick

Window {
    id: root

    default property alias contentData: contentHost.data

    // 1920×1080 上原来是 920×600，其它分辨率按同样比例缩放
    readonly property real widthRatio: 920 / 1920
    readonly property real heightRatio: 600 / 1080
    minimumWidth: Math.round(screen.width * widthRatio)
    minimumHeight: Math.round(screen.height * heightRatio)
    width: minimumWidth
    height: minimumHeight
    visible: true

    // 去掉系统边框后，圆角外面的四个角要透出桌面
    flags: Qt.FramelessWindowHint | Qt.Window
    color: "transparent"

    property int radius: 5
    // 底色由主题配色写过来，这里先空着
    property color backgroundColor: "#00000000"

    Rectangle {
        id: background
        anchors.fill: container
        radius: root.radius
        color: root.backgroundColor
    }

    Item {
        id: container
        anchors.fill: parent

        Item {
            id: contentHost
            anchors.fill: parent
        }

        MouseArea {
            id: leftEdge
            hoverEnabled: true
            anchors {
                top: container.top
                topMargin: root.radius
                bottom: container.bottom
                bottomMargin: root.radius
                left: container.left
            }
            width: root.radius
            cursorShape: Qt.SizeHorCursor
            onPressed: root.startSystemResize(Qt.LeftEdge)
        }
        MouseArea {
            id: rightEdge
            hoverEnabled: true
            anchors {
                top: container.top
                topMargin: root.radius
                bottom: container.bottom
                bottomMargin: root.radius
                right: container.right
            }
            width: root.radius
            cursorShape: Qt.SizeHorCursor
            onPressed: root.startSystemResize(Qt.RightEdge)
        }
        MouseArea {
            id: topEdge
            hoverEnabled: true
            anchors {
                top: container.top
                left: container.left
                leftMargin: root.radius
                right: container.right
                rightMargin: root.radius
            }
            height: root.radius
            cursorShape: Qt.SizeVerCursor
            onPressed: root.startSystemResize(Qt.TopEdge)
        }
        MouseArea {
            id: bottomEdge
            hoverEnabled: true
            anchors {
                bottom: container.bottom
                left: container.left
                leftMargin: root.radius
                right: container.right
                rightMargin: root.radius
            }
            height: root.radius
            cursorShape: Qt.SizeVerCursor
            onPressed: root.startSystemResize(Qt.BottomEdge)
        }
        MouseArea {
            id: topLeftCorner
            hoverEnabled: true
            anchors {
                top: container.top
                left: container.left
            }
            width: root.radius
            height: width
            cursorShape: Qt.SizeFDiagCursor
            onPressed: root.startSystemResize(Qt.TopEdge | Qt.LeftEdge)
        }
        MouseArea {
            id: topRightCorner
            hoverEnabled: true
            anchors {
                top: container.top
                right: container.right
            }
            width: root.radius
            height: width
            cursorShape: Qt.SizeBDiagCursor
            onPressed: root.startSystemResize(Qt.TopEdge | Qt.RightEdge)
        }
        MouseArea {
            id: bottomLeftCorner
            hoverEnabled: true
            anchors {
                bottom: container.bottom
                left: container.left
            }
            width: root.radius
            height: width
            cursorShape: Qt.SizeBDiagCursor
            onPressed: root.startSystemResize(Qt.BottomEdge | Qt.LeftEdge)
        }
        MouseArea {
            id: bottomRightCorner
            hoverEnabled: true
            anchors {
                bottom: container.bottom
                right: container.right
            }
            width: root.radius
            height: width
            cursorShape: Qt.SizeFDiagCursor
            onPressed: root.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
        }
    }
}
