import QtQuick
import QtQuick.Controls
import "../../settings"

Popup {
    id: root

    property Theme theme: null

    padding: 16
    readonly property int choiceCount: theme && theme.theme ? theme.theme.length : 0
    // 宽高都按内容来，不要写死。写死后多出来的空白会堆在文字下面，上下边距就不一样
    width: choiceCount * 76 + Math.max(choiceCount - 1, 0) * 16 + leftPadding + rightPadding
    height: contentItem.implicitHeight + topPadding + bottomPadding
    modal: true
    focus: true
    // OutsideParent：点按钮本身不算“点到外面”，按钮才能负责开关
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    // 不能标 readonly：ColorAnimation 要逐帧写中间色
    property color panelColor: paint("popupNormal")
    property color borderColor: paint("popupBorder")
    property color captionColor: paint("titleNormal")

    Behavior on panelColor { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }
    Behavior on borderColor { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }
    Behavior on captionColor { enabled: theme && theme.ready; ColorAnimation { duration: 560; easing.type: Easing.InOutCubic } }

    function paint(key) {
        if (!theme)
            return "#00000000"
        return theme.colorOf(key)
    }

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
            model: root.theme ? root.theme.theme : []

            delegate: Item {
                id: choice
                required property var modelData
                readonly property bool selected: root.theme && root.theme.current === modelData.name

                implicitWidth: 76
                implicitHeight: preview.height + caption.anchors.topMargin + caption.implicitHeight
                width: implicitWidth
                height: implicitHeight

                Rectangle {
                    id: preview
                    width: 76
                    height: 48
                    radius: 8
                    color: root.theme.colorOfTheme(choice.modelData.name, "windowNormal")
                    border.width: choice.selected ? 2 : 1
                    border.color: choice.selected ? root.theme.colorOfTheme(choice.modelData.name, "logoNormal") : root.borderColor

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: root.theme.colorOfTheme(choice.modelData.name, "logoNormal")
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: 28
                        height: 4
                        radius: 2
                        color: root.theme.colorOfTheme(choice.modelData.name, "titleNormal")
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
                        root.theme.current = choice.modelData.name
                        root.close()
                    }
                }
            }
        }
    }
}
