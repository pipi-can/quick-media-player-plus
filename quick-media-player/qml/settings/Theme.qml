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

    Utils { id: utils }

    /**
     * @brief 读主题文件。qrc 是异步的，先记下数据，下一拍再标记 ready
     */
    function load() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("theme.json"))
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            if (!xhr.responseText) {
                utils.error("主题文件读不到")
                root.ready = true
                return
            }
            var data = JSON.parse(xhr.responseText)
            root.themeCount = data.themeCount
            root.theme = data.theme
            if (data.themeCount !== data.theme.length)
                utils.error("主题数量对不齐：themeCount=" + data.themeCount + "，theme=" + data.theme.length)
            Qt.callLater(function() { root.ready = true })
        }
        xhr.send()
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
