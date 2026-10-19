import QtQuick
import "../utils"

// 主题存在 theme.json。这里只负责读进来，并按当前名字取出一套颜色
Item {
    id: root

    property string current: "Dark"
    property int themeCount: 0
    property var theme: []
    // 配色到齐后再打开动画和窗口，避免启动时从透明色缓一遍
    property bool ready: false
    // 成功或失败只处理一次，避免错误回调把已经读到的配色盖掉
    property bool settled: false

    Utils { id: utils }

    // 失败也要把窗口放出来，不然进程在跑、屏幕上什么都没有
    function fail(reason) {
        if (root.settled)
            return
        root.settled = true
        utils.error(reason)
        root.ready = true
    }

    function applyText(text) {
        var data
        try {
            data = JSON.parse(text)
        } catch (error) {
            fail("主题文件解析失败：" + error)
            return
        }
        if (!data || !data.theme || data.theme.length === undefined) {
            fail("主题文件格式不对")
            return
        }
        root.themeCount = data.themeCount
        root.theme = data.theme
        if (data.themeCount !== data.theme.length)
            utils.error("主题数量对不齐：themeCount=" + data.themeCount + "，theme=" + data.theme.length)
        if (!findTheme(root.current))
            utils.error("当前主题不存在：" + root.current)
        root.settled = true
        Qt.callLater(function() { root.ready = true })
    }

    /**
     * @brief 读主题文件。读不到或解析失败也要打开窗口，并写明原因
     */
    function load() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("theme.json"))
        xhr.onerror = function() {
            fail("主题文件读不到")
        }
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || root.settled)
                return
            if (!xhr.responseText) {
                fail("主题文件读不到")
                return
            }
            applyText(xhr.responseText)
        }
        xhr.send()
        // 本地读取被关掉时，请求停在未发送，回调不会来
        if (xhr.readyState === XMLHttpRequest.UNSENT)
            fail("主题文件读不到")
    }

    function findTheme(name) {
        var items = root.theme
        for (var i = 0; i < items.length; ++i) {
            if (items[i].name === name)
                return items[i]
        }
        return null
    }

    // 当前主题里某个控件状态的颜色
    function colorOf(key) {
        return colorIn(findTheme(root.current), key)
    }

    // 指定主题的颜色，预览块要用它自己的配色，不能跟当前主题走
    function colorOfTheme(name, key) {
        return colorIn(findTheme(name), key)
    }

    function colorIn(item, key) {
        if (!item)
            return "#00000000"
        if (item[key] === undefined) {
            utils.error("主题 " + item.name + " 缺少颜色 " + key)
            return "#00000000"
        }
        return parseRgba(item[key])
    }

    /**
     * @brief 把 "rgba(r, g, b, a)" 转成颜色。a 为 1 表示不透明
     */
    function parseRgba(text) {
        var matched = /^rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([0-9.]+)\s*\)$/.exec(text)
        if (!matched) {
            utils.error("颜色不是 rgba 字符串：" + text)
            return "#00000000"
        }
        return Qt.rgba(Number(matched[1]) / 255, Number(matched[2]) / 255, Number(matched[3]) / 255, Number(matched[4]))
    }

    Component.onCompleted: load()
}
