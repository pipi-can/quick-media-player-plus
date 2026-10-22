import QtQuick

// 图标按钮：图标自己不变形，只跟着鼠标换颜色，按下时垫一层底色
Item {
    id: root

    property alias source: icon.source

    // 三种状态各给一个颜色，鼠标移上去和按下的样子由外面定
    property color normalColor: "#00000000"
    property color hoverColor: "#00000000"
    property color pressColor: "#00000000"

    // 按下时垫在图标下面的底色，透明就是不垫
    property color pressFill: "transparent"

    // 点击范围比图标大一圈，图标四周留的空白。28 的按钮配 18 的图标就是 5
    property real iconInset: 5

    signal clicked()

    implicitWidth: 28
    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: mouse.mouseState === "press" ? root.pressFill : "transparent"
    }

    ColorImage {
        id: icon
        anchors.fill: parent
        anchors.margins: root.iconInset
        color: mouse.color
    }

    MouseStateItem {
        id: mouse
        anchors.fill: parent
        normalColor: root.normalColor
        hoverColor: root.hoverColor
        pressColor: root.pressColor
        onClicked: root.clicked()
    }
}
