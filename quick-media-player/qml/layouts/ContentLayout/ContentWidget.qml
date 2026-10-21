import QtQuick
import QtQuick.Controls
import "../../utils"
import "../../settings"
import "VideoLayout"
import "MusicLayout"
import "HistoryLayout"
import "ShareLayout"
import "SettingsLayout"

// 标题栏下面的内容区。自己不画底色，五个页面各自放在子目录里
Item {
    id: root

    property string currentPage: "video"
    property Theme theme: null

    Utils { id: utils }

    onCurrentPageChanged: showPage(currentPage)

    function showPage(name) {
        var page = pageComponent(name)
        if (!page)
            return
        if (stack.currentItem && stack.currentItem.objectName === name
                && !leaveAnim.running && !enterAnim.running)
            return
        leaveAnim.stop()
        enterAnim.stop()
        if (!stack.currentItem) {
            placePage(page, name, false)
            return
        }
        // StackView 的进出动画一起跑，新页会盖住旧页，淡出看不见
        leaveAnim.nextPage = page
        leaveAnim.nextName = name
        leaveAnim.target = stack.currentItem
        leaveAnim.restart()
    }

    function placePage(page, name, fadeIn) {
        stack.replace(page, {}, StackView.Immediate)
        utils.debug("切到 " + name)
        if (!fadeIn || !stack.currentItem)
            return
        stack.currentItem.opacity = 0
        enterAnim.target = stack.currentItem
        enterAnim.restart()
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
        if (name === "settings")
            return settingsPage
        return null
    }

    StackView {
        id: stack
        anchors.fill: parent
        // 关掉自带的左右滑入。初始页也走 placePage，避免和动画目标不是同一页
        replaceEnter: Transition {}
        replaceExit: Transition {}
    }

    NumberAnimation {
        id: leaveAnim
        property var nextPage
        property string nextName
        property: "opacity"
        to: 0
        duration: 200
        easing.type: Easing.OutCubic
        onFinished: placePage(nextPage, nextName, true)
    }

    NumberAnimation {
        id: enterAnim
        property: "opacity"
        from: 0
        to: 1
        duration: 200
        easing.type: Easing.OutCubic
    }

    Component {
        id: videoPage
        VideoPage { theme: root.theme }
    }
    Component {
        id: musicPage
        MusicPage { theme: root.theme }
    }
    Component {
        id: historyPage
        HistoryPage { theme: root.theme }
    }
    Component {
        id: sharePage
        SharePage { theme: root.theme }
    }
    Component {
        id: settingsPage
        SettingsPage { theme: root.theme }
    }

    Component.onCompleted: showPage(currentPage)
}
