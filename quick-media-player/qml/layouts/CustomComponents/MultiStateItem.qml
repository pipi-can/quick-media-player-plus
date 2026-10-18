import QtQuick

Item {
    id: root

    // 和 stateInfos、items 一样长，多出来的不参与切换
    property int stateCount: 0

    // 每一项用 name 表示状态名，顺序和 items 相同
    property var stateInfos: []

    // 每个状态自己的控件，彼此独立，只是换显示
    property var items: []

    // 还没写当前状态时，用这个名字
    property string defaultState: ""

    // 正在显示的状态名
    property string currentState: ""

    onCurrentStateChanged: showCurrent()
    onDefaultStateChanged: showCurrent()
    onStateCountChanged: showCurrent()
    onStateInfosChanged: showCurrent()
    onItemsChanged: showCurrent()

    Component.onCompleted: {
        if (currentState === "")
            currentState = defaultState
        showCurrent()
    }

    /**
     * @brief 只显示当前状态名对应的那一个控件
     * @retval 无
     */
    function showCurrent() {
        var name = currentState !== "" ? currentState : defaultState
        var count = stateCount
        if (count > items.length)
            count = items.length

        for (var i = 0; i < count; i++) {
            var item = items[i]
            if (!item)
                continue
            var info = i < stateInfos.length ? stateInfos[i] : null
            item.visible = info !== null && info.name === name
        }
    }

    /**
     * @brief 按声明顺序切到下一个状态，到末尾回到第一个
     * @retval 无
     */
    function next() {
        if (stateCount <= 0 || stateInfos.length === 0)
            return

        var name = currentState !== "" ? currentState : defaultState
        var index = 0
        var limit = stateCount < stateInfos.length ? stateCount : stateInfos.length
        for (var i = 0; i < limit; i++) {
            if (stateInfos[i].name === name) {
                index = i
                break
            }
        }

        var nextIndex = (index + 1) % limit
        currentState = stateInfos[nextIndex].name
    }
}
