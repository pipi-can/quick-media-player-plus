import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property alias source: image.source
    property alias color: overlay.color
    property alias fillMode: image.fillMode

    // 原图只给 ColorOverlay 取样，自己不显示，避免和着色结果叠成两层
    Image {
        id: image
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        visible: false
    }

    ColorOverlay {
        id: overlay
        anchors.fill: parent
        source: image
        color: "#ffffff"
    }
}
