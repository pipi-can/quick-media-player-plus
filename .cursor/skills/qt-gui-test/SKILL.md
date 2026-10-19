---
name: qt-gui-test
description: Test Qt Quick / QML graphical UI for widget bugs, hover, click, layout, and visual regressions. Use when the user asks to test a Qt program, QML control, 图形化界面, 测界面, 点鼠标看效果, reproduce a UI bug, or verify FramelessWindow / TitleBar / MultiStateItem after a change.
---

# Qt 图形界面测试

本工程是 **C++ 后端 + QML 前端** 的桌面程序，入口在 `quick-media-player/qml/main.qml`。测界面时按下面三层选工具，不要一上来就挪系统鼠标。

| 层 | 用来干什么 | 什么时候用 |
| --- | --- | --- |
| A. Qt Quick Test | 在 QML 场景里注入点击、悬停、拖动 | 控件逻辑、状态切换、可复现 bug |
| B. 窗口截图 | 看实际画出来的样子 | 布局、颜色、裁切、弹窗位置 |
| C. 系统鼠标 | 真的移动电脑光标 | 用户明确要「看着鼠标点」、或 A 复现不了的系统级问题 |

网页稿 `pages/` 用浏览器工具，不要用本 skill。本 skill 只测原生 Qt 窗口。

## 流程

复制并勾选：

```
- [ ] 1. 说清测哪个控件、什么操作、期望画面
- [ ] 2. 先读对应 QML，确认根 id 和可点区域
- [ ] 3. 能单测就写 Qt Quick Test（层 A）
- [ ] 4. 启动程序，截窗口核对画面（层 B）
- [ ] 5. 只有 A/B 不够，或用户要看鼠标动，才走系统鼠标（层 C）
- [ ] 6. 记下复现步骤和截图，再改代码
```

1. 先问清或从对话里确认：哪个文件、点哪里、期望什么。不确定就停下来问。
2. 只测当前改动相关的控件。无边框窗口、标题栏、音量弹窗这类，优先对着 `qml/layouts/` 里的小组件测，不要一上来点整应用。
3. 改完再跑同一条用例。截图对不上就继续改，不要口头说「应该好了」。

## 层 A：Qt Quick Test（首选）

官方做法：`TestCase` 的 `mouseClick` / `mouseMove` / `mousePress` 把事件打进场景，**光标不必真的动**，结果稳定，能进 CI。

细节和最小例子见 [references/qml-testcase.md](references/qml-testcase.md)。

要点：

- 给被测根组件一个稳定 `id` 和明确宽高。
- 点控件中心或相对坐标，不要写死整屏像素。
- 测 `MultiStateItem` 时断言 `currentState` 和对应子项 `visible`。
- 测 hover 用 `mouseMove`，不要用系统鼠标去「移过去看看」。

## 层 B：截窗口

启动 `quick-media-player` 后，用脚本抓目标窗口，不要用浏览器截图工具。

```powershell
powershell -File .cursor/skills/qt-gui-test/scripts/qt-window.ps1 -Action screenshot -Title QMediaPlayer
```

截图存到系统临时目录，路径会打印出来。对照用户描述的错误（滑条跑出框、布局挤在一起、状态没切）。

窗口标题对不上时，先列出窗口：

```powershell
powershell -File .cursor/skills/qt-gui-test/scripts/qt-window.ps1 -Action list
```

## 层 C：系统鼠标（最后用）

本环境没有现成的「桌面鼠标 MCP」。要真的动光标，跑同目录脚本。窗口必须可见、未被最小化。无边框窗口按标题找。

```powershell
# 相对窗口客户区点击（像素）
powershell -File .cursor/skills/qt-gui-test/scripts/qt-window.ps1 -Action click -Title QMediaPlayer -X 40 -Y 20

# 移动到相对坐标（不点击）
powershell -File .cursor/skills/qt-gui-test/scripts/qt-window.ps1 -Action move -Title QMediaPlayer -X 200 -Y 80
```

注意：

- 坐标是**窗口客户区左上角**算起，不是屏幕绝对坐标。
- 高 DPI 下可能偏一点，先截图核对落点再连点。
- 不要在用户正在打字时乱跑鼠标。跑之前说一声。
- 测完把结论写成：操作 → 实际画面 → 是否复现。

## 报结果

对用户只讲现象和结论，不要贴一长串 Win32 细节。

- 复现了：哪一步、哪张图、哪个 QML 最可疑
- 没复现：做了哪些点击、和用户环境可能差在哪
- 下一步：改哪个文件，还是要用户本地再点一次
