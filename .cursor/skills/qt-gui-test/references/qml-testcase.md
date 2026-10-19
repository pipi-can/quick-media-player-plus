# Qt Quick Test 最小写法

独立小程序测一个控件，不要把整个播放器拉进测试窗口。

```qml
import QtQuick
import QtTest
import "../../qml/layouts/CustomComponents"

Item {
    width: 240
    height: 80

    MultiStateItem {
        id: target
        width: 120
        height: 36
        // 按该控件真实 API 填 stateInfos / items
    }

    TestCase {
        name: "MultiStateItemClick"
        when: windowShown

        function test_click_switches_state() {
            const before = target.currentState
            mouseClick(target, target.width / 2, target.height / 2)
            wait(50)
            verify(target.currentState !== before)
        }

        function test_hover_does_not_crash() {
            mouseMove(target, 4, 4)
            wait(30)
            mouseMove(target, target.width / 2, target.height / 2)
            wait(30)
        }
    }
}
```

用 `qmltestrunner` 跑（路径按本机 Qt 套件改）：

```
qmltestrunner -input tests/qml
```

`grabToImage` 适合断言「弹窗还在父框里」这类几何问题：比较 `mapToItem` 后的坐标，比比像素更稳。
