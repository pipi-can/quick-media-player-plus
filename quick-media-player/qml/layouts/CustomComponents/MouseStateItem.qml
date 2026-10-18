import QtQuick

Item {
    id: root

    signal clicked()

    // 三种状态各用各的颜色和鼠标。外面的控件只读算出来的 color
    property color normalColor: "#d7deea"
    property color hoverColor: "#ffffff"
    property color pressColor: "#f0c36a"
    property int normalCursor: Qt.ArrowCursor
    property int hoverCursor: Qt.PointingHandCursor
    property int pressCursor: Qt.PointingHandCursor

    // 按下并且鼠标还在里面才算 press，拖出去就回到普通，避免松手点在外面也像按住
    readonly property string mouseState: {
        if (area.pressed && area.containsMouse)
            return "press"
        if (area.containsMouse)
            return "hover"
        return "normal"
    }

    readonly property color color: {
        if (mouseState === "press")
            return pressColor
        if (mouseState === "hover")
            return hoverColor
        return normalColor
    }

    default property alias contentData: contentHost.data

    Item {
        id: contentHost
        anchors.fill: parent
    }

    // 盖在内容上面。不开 hoverEnabled，鼠标移上去不会变成 hover
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: {
            if (root.mouseState === "press")
                return root.pressCursor
            if (root.mouseState === "hover")
                return root.hoverCursor
            return root.normalCursor
        }
        onClicked: root.clicked()
    }
}
