import QtQuick
import QtQuick.Controls
import "../../utils"

// 标题栏下面的内容区。自己不画底色，页面以后再放进对应的 Component
Item {
    id: root

    property string currentPage: "video"

    Utils { id: utils }

    onCurrentPageChanged: showPage(currentPage)

    function showPage(name) {
        var page = pageComponent(name)
        if (!page)
            return
        if (stack.currentItem && stack.currentItem.objectName === name)
            return
        stack.replace(page, {}, StackView.Immediate)
        utils.debug("切到 " + name)
    }

    function pageComponent(name) {
        if (name === "video")
            return videoPage
        if (name === "music")
            return musicPage
        if (name === "history")
            return historyPage
        if (name === "share")
            return sharePage
        return null
    }

    StackView {
        id: stack
        anchors.fill: parent
        // 不要默认的左右滑入，页面是直接换掉
        replaceEnter: Transition {}
        replaceExit: Transition {}
        initialItem: videoPage
    }

    Component {
        id: videoPage
        Item { objectName: "video" }
    }
    Component {
        id: musicPage
        Item { objectName: "music" }
    }
    Component {
        id: historyPage
        Item { objectName: "history" }
    }
    Component {
        id: sharePage
        Item { objectName: "share" }
    }

    Component.onCompleted: showPage(currentPage)
}
