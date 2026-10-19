import QtQuick
import QtQuick.Controls

Popup {
    id: root

    property string themeName: "Dark"

    signal themePicked(string name)

    padding: 16
    // 宽高都按内容来，不要写死。写死后多出来的空白会堆在文字下面，上下边距就不一样
    width: 76 + 16 + 76 + leftPadding + rightPadding
    height: contentItem.implicitHeight + topPadding + bottomPadding
    modal: true
    focus: true
    // OutsideParent：点按钮本身不算“点到外面”，按钮才能负责开关
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    // 弹窗自己的壳也跟着当前主题走，颜色来自旧工程
    readonly property bool light: themeName === "Light"
    // 不能标 readonly：ColorAnimation 要逐帧写中间色
    property color panelColor: light ? "#FFFFFF" : "#152140"
    property color borderColor: light ? "#AFB2BA" : "#2C4485"
    property color captionColor: light ? "#000000" : "#ffffff"

    Behavior on panelColor { ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }
    Behavior on borderColor { ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }
    Behavior on captionColor { ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }

    background: Rectangle {
        radius: 12
        color: root.panelColor
        border.color: root.borderColor
        border.width: 1
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160 }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 120 }
    }

    contentItem: Row {
        spacing: 16

        Repeater {
            model: [
                { name: "Dark", caption: "深色", swatch: "#0e162a", ink: "#ffffff" },
                { name: "Light", caption: "浅色", swatch: "#f4f5f9", ink: "#000000" }
            ]

            delegate: Item {
                id: choice
                required property var modelData
                readonly property bool selected: root.themeName === modelData.name

                implicitWidth: 76
                implicitHeight: preview.height + caption.anchors.topMargin + caption.implicitHeight
                width: implicitWidth
                height: implicitHeight

                Rectangle {
                    id: preview
                    width: 76
                    height: 48
                    radius: 8
                    color: choice.modelData.swatch
                    border.width: choice.selected ? 2 : 1
                    border.color: choice.selected ? "#19adfa" : root.borderColor

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: "#19adfa"
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: 28
                        height: 4
                        radius: 2
                        color: choice.modelData.ink
                        opacity: 0.8
                        anchors.left: parent.left
                        anchors.leftMargin: 28
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    id: caption
                    anchors.top: preview.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: preview.horizontalCenter
                    text: choice.modelData.caption
                    color: root.captionColor
                    font.pixelSize: 13
                    font.bold: choice.selected
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.themePicked(choice.modelData.name)
                        root.close()
                    }
                }
            }
        }
    }
}
