import QtQuick

// 状态个数和每个状态要改的属性都是外面传的，所以 State 按这份表生成
Item {
    id: root

    property int stateCount: 0
    property int currentState: 0
    property var stateInfos: []

    default property alias contentData: contentHolder.data

    function next() {
        var count = activeCount()
        if (count <= 0)
            return
        currentState = (currentState + 1) % count
    }

    function activeCount() {
        var listed = stateInfos ? stateInfos.length : 0
        if (stateCount > 0 && stateCount < listed)
            return stateCount
        return listed
    }

    function applyInfo(index) {
        var item = contentHolder.children.length > 0 ? contentHolder.children[0] : null
        if (!item || !stateInfos || index < 0 || index >= stateInfos.length)
            return
        var plain = JSON.parse(JSON.stringify(stateInfos[index]))
        for (var key in plain)
            item[key] = plain[key]
    }

    function rebuildStates() {
        clearStates()
        if (contentHolder.children.length === 0)
            return
        var count = activeCount()
        if (count <= 0)
            return

        for (var i = 0; i < count; i++)
            states.push(makeState(i))
        applyIndex(currentState)
    }

    function makeState(index) {
        var body = "import QtQuick\n"
                + "State {\n"
                + "    name: \"" + index + "\"\n"
                + "    StateChangeScript { script: root.applyInfo(" + index + ") }\n"
                + "}\n"
        return Qt.createQmlObject(body, root, "MultiStateItemState")
    }

    function clearStates() {
        state = ""
        var pending = []
        for (var i = 0; i < states.length; i++)
            pending.push(states[i])
        for (var j = 0; j < pending.length; j++)
            pending[j].destroy()
    }

    function applyIndex(index) {
        if (states.length === 0)
            return
        if (index < 0 || index >= states.length)
            return
        state = String(index)
    }

    onStateInfosChanged: rebuildStates()
    onStateCountChanged: rebuildStates()
    onCurrentStateChanged: applyIndex(currentState)
    Component.onCompleted: rebuildStates()

    Item {
        id: contentHolder
        anchors.fill: parent
        onChildrenChanged: root.rebuildStates()
    }
}
