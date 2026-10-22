import QtQuick

// 和 MouseArea 一样盖在控件上面。控件自己画，这里只根据鼠标算出颜色和光标
MouseArea {
    id: root

    // 不开的话，鼠标移上去不会变成 hover
    hoverEnabled: true

    // 三种状态各用各的颜色和鼠标。外面的控件只读算出来的 color
    property color normalColor: "#d7deea"
    property color hoverColor: "#ffffff"
    property color pressColor: "#f0c36a"
    property int normalCursor: Qt.ArrowCursor
    property int hoverCursor: Qt.PointingHandCursor
    property int pressCursor: Qt.PointingHandCursor

    // 按下并且鼠标还在里面才算 press，拖出去就回到普通，避免松手点在外面也像按住
    readonly property string mouseState: {
        if (pressed && containsMouse)
            return "press"
        if (containsMouse)
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

    cursorShape: {
        if (mouseState === "press")
            return pressCursor
        if (mouseState === "hover")
            return hoverCursor
        return normalCursor
    }

    // 鼠标点过的焦点不画圈，只有键盘走到这里才画
    activeFocusOnTab: true

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 4
        border.width: root.visualFocus ? 2 : 0
        border.color: root.palette.highlight
    }

    Keys.onPressed: function (event) {
        if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space)
            return
        event.accepted = true
        root.clicked(null)
    }
}
