# 视频页四区域组件规范

- 适用范围：`quick-media-player/qml/layouts/ContentLayout/VideoLayout/`
- 比例来源：`pages/index.html` + `pages/styles.css` 的视频页那一节（`.screen` / `.ctrl` / `.queue` / `.file-card`）
- 配色来源：`quick-media-player/qml/settings/theme.json`

这份文档说明这一页由哪四块拼出来、每块的对外接口和尺寸是多少、颜色从哪来。改这四个文件、或照着它做别的页面时按这里写的来。

## 1. 四个区域怎么拼起来

```
VideoPage                         Item，objectName: "video"
├─ queueColumn（宽 280，贴右上）   Item
│  ├─ VideoPlaylistArea           播放队列区，贴顶
│  └─ VideoMessageArea            播放信息区，贴底，高度由内容撑
└─ stage（占剩下的宽）             Item
   ├─ VideoPlayArea               播放区，贴顶
   └─ VideoPlayControlArea        播放控制区，贴底，高固定 48
```

| 关系 | 锚点 / 留白 |
| --- | --- |
| 队列列 ↔ 页面 | 上 8、右 12、下 12，宽固定 280（不跟着窗口变） |
| 画面列 ↔ 页面 | 左 12、上 8、下 12；右边贴住队列列左侧，再留 16 |
| 队列区 ↔ 信息区 | 队列区底边 = 信息区顶边 − 8 |
| 画面 ↔ 控制条 | 画面底边 = 控制条顶边（控制条自己 48 高） |

四个区域互不认识，数据全部由 `VideoPage` 一层传下去：

| 从 | 到 |
| --- | --- |
| `VideoPage.theme` | 四个区域的 `theme` |
| `VideoPage.queueItems` | `VideoPlaylistArea.items` |
| `VideoPage.currentIndex` | `VideoPlaylistArea.selectedIndex`、`playingIndex` |
| `VideoMessageArea.item` ← `VideoPage.queueItems[VideoPage.currentIndex]` | |
| `VideoPlaylistArea.itemSelected(index)` → 改 `VideoPage.currentIndex` | |

`VideoPage` 是唯一知道数据长什么样的地方（现在是自己写死的三条假数据，字段见 §8）。接 `PlayList` 单例时只改这一层，四个区域不动。

## 2. 四个区域

### 2.1 VideoPlayArea 播放区

文件 `VideoPlayArea.qml`。职责：在空白区正中画一块 16:9 的画面，按状态换里面的内容。

| 类型 | 名字 | 说明 |
| --- | --- | --- |
| 属性 | `theme` | `Theme`，必传 |
| 属性 | `screenState` | `string`，取值 `empty` / `loading` / `paused` / `playing` / `error`，默认 `empty` |
| 只读 | `stageColor`、`stageInk`、`stageEdge` | 画面底、图标文字、1px 边 |
| 只读 | `fitWidth` | `Math.min(width, height * 16 / 9)`，画面能铺到的最大宽 |
| 函数 | `paint(key)` | 取主题色，`theme` 没挂上时返回透明 |

画面是一块 `Rectangle`，在父项里居中：宽 = 播放中 ? `fitWidth` : `fitWidth × 0.618`；高 = 宽 × 9 / 16；圆角 8；1px 边。0.618 就是原型里「没在播时只取最大尺寸的 0.618」，播放时铺满。

五个状态用 `MultiStateItem`，`currentState` 跟着 `screenState`：

| 状态名 | 图标 | 文案 |
| --- | --- | --- |
| `empty` | `PlayWidgetIcons/play.svg` | 还没有视频。点右侧加号加入队列 |
| `loading` | 无 | 正在打开 |
| `paused` | `PlayWidgetIcons/pause.svg` | 已暂停 |
| `playing` | 无 | 无（不盖东西，画面让给视频） |
| `error` | `AppIcons/error.svg` | 打不开这个视频 |

每一态的排版都是同一个内联组件 `Face`：`Column`，图标 36×36 + 文案 13px，间距 16，整体在画面里居中，图标和文字都用 `stageInk`。没有图标的两态只显示一行字。

两点注意：

- 五个状态只换画面内容，**不代表已经在解码**。`playing` 那一态什么都不画，将来真画面就挂在这块 `Rectangle` 里。
- 图标是单色 svg，走 `ColorImage` 上色。

用到的配色键：`stageNormal`、`stageText`、`stageBorder`。

### 2.2 VideoPlaylistArea 播放队列区

文件 `VideoPlaylistArea.qml`。职责：一行标题加一个加号，下面整列都是队列。

| 类型 | 名字 | 说明 |
| --- | --- | --- |
| 属性 | `theme` | `Theme`，必传 |
| 属性 | `items` | `var`，队列数据，每项至少要有 `name`、`length` |
| 属性 | `selectedIndex` | `int`，高亮哪一行。这里只读，点上哪行由信号交出去 |
| 属性 | `playingIndex` | `int`，哪一行标「正在播放」 |
| 信号 | `itemSelected(int index)` | 点了某一行 |

| 部件 | 尺寸 / 位置 |
| --- | --- |
| 标题行 `head` | 高 40 = 上 4 + 按钮 28 + 下 8 |
| 「播放队列」 | 左边距 8，15px 加粗，字距 1，和加号按钮垂直居中 |
| 加号按钮 | 28×28（图标 18×18），`y: 4`，右边距 8 |
| 列表 | `ListView`，从标题行底到父项底，行间距 4，裁剪超出部分 |
| 行 | 高 58，圆角 8 |
| 选中标记 | 宽 3、满高、圆角 1.5 的竖条，只显示在选中行，贴最左 |
| 缩略图 | x 8 / y 8，42×42 圆（`radius: width / 2`），深色圆底 + 14×14 白色播放图标 |
| 文件名 | 左 58 / 右 10 / 上 14，13px，超长省略 |
| 「正在播放」 | 左 58 / 下 8，12px 加粗，只出现在 `playingIndex` 那一行 |
| 时长 | 右 8 / 下 8，12px，弱化色 |
| 交互层 | `MouseStateItem` 铺满整行，点击发 `itemSelected(index)` |

行的三种底色：选中 → `queueItemOn`；悬停 → `queueItemHover`；其它 → 透明。

选中和悬停**故意不靠深浅区分**（浅色主题下这两档明度很接近），选中另外靠左边那条竖标记。

用到的配色键：`titleNormal`、`queueItemOn`、`queueItemHover`、`queueMark`、`navTextNormal`、`videoThumb`、`videoThumbIcon`、`iconNormal` / `iconHover` / `iconPress`（加号，按下垫的底色也用 `queueItemHover`）。

### 2.3 VideoPlayControlArea 播放控制区

文件 `VideoPlayControlArea.qml`。职责：上面一条进度，下面一排按钮。这一版只画样子。

| 类型 | 名字 | 说明 |
| --- | --- | --- |
| 属性 | `theme` | `Theme`，必传 |
| 属性 | `progress` | `real`，0～1，默认 0.18 |
| 属性 | `timeText` | `string`，默认 `"00:07 / 05:27"` |
| 属性 | `modeText` | `string`，默认 `"列表循环"` |
| 属性 | `speedText` | `string`，默认 `"1.0X"` |
| 属性 | `playing` | `bool`，默认 `true`，决定播放键画暂停还是播放图标 |
| 只读 | `implicitHeight` | 48，外面按它摆 |

高度 48 = 进度条 4 + 间距 8 + 按钮行 28 + 底下留 8。

进度条：`Item` 高 4，左右各内缩 12。里面一条高 4、圆角 2 的轨道（`barColor`），加一个 10×10 的圆点（`dotColor`），圆点 `x = progress × (轨道宽 − 10)`。**只显示位置，不能拖**（没有交互层）。

按钮行：高 28，贴进度条下 8，左右各内缩 12。

- 从左往右：上一个（`lastone.svg`）、播放 / 暂停、下一个（`nextone.svg`），各自是一个 28×28 的 `Item`，互相间隔 8；再空 8 跟时间文字（12px）。播放键的根是 `MultiStateItem`，`playing` 为真显示暂停图标（`pause.svg`）、为假显示播放图标（`play.svg`）。
- 从右往左：音量按钮（`volume.svg`）、倍速文字、模式文字，都是 12px 加粗、带上下 4 左右 8 的内边距。倍速和模式只接了 `MouseStateItem` 换颜色，**还没有下拉菜单**。
- 中间剩下的空白就是原型里的 `.grow`。

按钮的 `clicked` 现在没有接，点了只有视觉反馈。

用到的配色键：`progressNormal`（轨道）、`progressThumb`（圆点）、`titleNormal`（时间）、`iconNormal` / `iconHover` / `iconPress`（按钮和倍速、模式文字，按下垫底用 `queueItemHover`）。

### 2.4 VideoMessageArea 播放信息区

文件 `VideoMessageArea.qml`。职责：一行文件名加「详情」，点开是四行具体参数。

| 类型 | 名字 | 说明 |
| --- | --- | --- |
| 属性 | `theme` | `Theme`，必传 |
| 属性 | `item` | `var`，当前这一项，`null` 时所有文字为空 |
| 属性 | `detailOpen` | `bool`，默认 `false`，点「详情」在 `false` / `true` 之间切 |
| 只读 | `implicitHeight` | 卡片高，外面按它摆 |
| 只读 | `brief` | `format · resolution · size` 拼起来的一行 |
| 只读 | `rows` | 路径 / 视频编码 / 解码器 / 音频，取值见下 |

`rows` 的四个字段：`item.path`、`item.codec`、`item.decoder`、`item.audio`。

| 部件 | 尺寸 / 位置 |
| --- | --- |
| 卡片 | 圆角 8，1px 边，上下各 12 内边距，高 = 内容高 + 24（行数变了高度跟着变） |
| 头部 | 文件名 13px 加粗、超长省略；右边是「详情」/「收起」12px 加粗、用主题色 |
| 详情按钮热区 | 比文字大一圈（宽高各 +8），按下垫一层圆角 4 的底色 |
| 摘要行 | 头部下 4，12px，弱化色，超长省略 |
| 四个详情行 | 默认收起；展开后在摘要下 8；每行高 18，左边标签列固定 60，标签弱化色、值超长省略 |

用到的配色键：`popupNormal`（卡底）、`popupBorder`（卡边）、`titleNormal`（文件名和值）、`navTextNormal`（摘要和标签）、`logoNormal`（「详情」，主题色）。

## 3. 复用到的原子控件

都在 `qml/layouts/CustomComponents/`。

| 控件 | 谁在用 | 接口要点 |
| --- | --- | --- |
| `MouseStateItem` | 队列每一行、倍速、模式、每个图标按钮 | `normalColor` / `hoverColor` / `pressColor`、三种光标、只读 `mouseState`（`normal` / `hover` / `press`）和 `color`、`clicked()`。开了 `hoverEnabled`；按着拖出去回到普通，不算 press；键盘 Enter / Space 也算点击；键盘走到才画焦点圈 |
| `MultiStateItem` | 播放区的五个状态 | `stateCount`、`stateInfos`（每项有 `name`）、`items`（和 `stateInfos` 顺序一一对应）、`defaultState`、`currentState`、`next()`。三个数量对不齐会报错 |
| `ColorImage` | 所有单色图标 | `source` + `color`（给单色 svg 上色）、`fillMode`。原图只给 `ColorOverlay` 取样，自己不显示 |

图标按钮不为它单独造控件，直接照 `TitleBar.qml` 里窗口控制那几个按钮的写法摊在用的地方：一个 `Item`（28×28）装三样东西 —— 按下垫底的 `Rectangle`、`ColorImage`（图标 18×18，所以四周各留 5）、压在最上面的 `MouseStateItem`。

```qml
// 图标按钮：28 的按钮配 18 的图标
Item {
    id: prevButton
    width: 28
    height: 28

    // 原型 .ico:active 会垫一层底色
    Rectangle {
        anchors.fill: parent
        radius: 4
        color: prevMouse.mouseState === "press" ? root.pressFill : "transparent"
    }

    ColorImage {
        anchors.fill: parent
        anchors.margins: 5
        source: "qrc:/quick-media-player/resources/PlayWidgetIcons/lastone.svg"
        color: prevMouse.color
    }

    MouseStateItem {
        id: prevMouse
        anchors.fill: parent
        normalColor: root.btnColor
        hoverColor: root.btnHover
        pressColor: root.btnPress
    }
}
```

一个按钮要在两张图标之间切的（播放 / 暂停、最大化 / 还原），把根换成 `MultiStateItem`，两个 `ColorImage` 放进 `items`、顺序和 `stateInfos` 对上，`currentState` 由外面给。现成例子：`TitleBar.qml` 的 `windowMode`、`VideoPlayControlArea.qml` 的 `playButton`。

各区域切颜色的写法统一是：

```qml
readonly property color xxxColor: paint("themeKey")

function paint(key) {
    return theme ? theme.colorOf(key) : "#00000000"
}
```

`theme` 还没挂上时返回透明，避免启动时闪一层黑。

## 4. 配色

颜色**只从** `theme.json` 取，区域里不写死色值。

| 区域 | 用到的键 |
| --- | --- |
| 播放区 | `stageNormal`、`stageText`、`stageBorder` |
| 队列区 | `titleNormal`、`queueItemOn`、`queueItemHover`、`queueMark`、`navTextNormal`、`videoThumb`、`videoThumbIcon`、`iconNormal`、`iconHover`、`iconPress` |
| 控制区 | `progressNormal`、`progressThumb`、`titleNormal`、`iconNormal`、`iconHover`、`iconPress` |
| 信息区 | `popupNormal`、`popupBorder`、`titleNormal`、`navTextNormal`、`logoNormal` |

**主题色的规则**：主题色只有一支 `#19adfa`，存在 `logoNormal` 里，两个主题一样，不在浅色主题里换成暗色。现在用这一支的是 `logoNormal`（品牌图标、「详情」）、`navFillOn`（Navigator 选中胶囊）、`queueMark`（队列左侧标记）。文字和小图形正常应该用暗一档的 `--accent-ink`（`#0a6fb0`），视频页为了品牌一致把「详情」和标记也用了主题色，代价是浅色主题下对比度只有 2.5:1（详情）和 2.2:1（标记），要调就调这几处。

已知的一处低对比还没改：`navTextNormal` 在浅色主题下是 `#5d7082`，对窗口底 `#e6eef5` 只有 4.36:1，队列里的时长用它。

## 5. 尺寸、留白、字号一览

数字都来自 §2 的表格，这里集中一份，免得来回翻：

- 页面：上 8、右 12、下 12；画面列左 12；队列列宽 280（固定）；队列列和画面列之间 16
- 队列列内部：队列区与信息区之间 8
- 队列：标题行 40（上 4 + 按钮 28 + 下 8）、行高 58、行间距 4、缩略图 42 圆、标记条宽 3
- 控制条：48 = 4 + 8 + 28 + 8
- 画面：16:9，圆角 8，1px 边，没在播时取最大尺寸的 0.618
- 信息卡：内边距上下各 12、详情行高 18、标签列宽 60
- 字号：15 加粗（队列标题）、13（画面文案、队列文件名、信息区文件名）、12（时间、倍速、模式、时长、「正在播放」、摘要、详情、详情行的标签和值）

## 6. 原型对照表

| 原型（`pages/styles.css`） | QML |
| --- | --- |
| `.screen` 宽 `min(100cqw × 0.618, 100cqh × 16/9 × 0.618)` | `fitWidth × 0.618`，其中 `fitWidth = min(width, height × 16/9)` |
| `.screen.is-playing` 宽 `min(100cqw, 100cqh × 16/9)` | `fitWidth` |
| `.screen` border 1 / radius 8 / `.screen .icon` 36×36 / gap 16 | 同上（`Face` 的 spacing 16） |
| `.ctrl` `padding: 0 12 8` | 左右各 12、下 8，`implicitHeight: 48` |
| `.ctrl-row` gap 8 / margin-top 8 | 按钮间隔 8、贴进度条下 8 |
| `.queue` width 280 | `queueColumn.width: 280` |
| `.queue-top` `padding: 4 8 8` | `head.height: 40` |
| `#page-video .q-item` height 58 / `.queue-list` gap 4 | 行高 58、`spacing: 4` |
| `.thumb` 42 圆 / `.thumb .icon` 14×14 | 42×42、`radius: width / 2`、图标 14×14 |
| `.q-item.is-on` `inset 3px 0 0` | 宽 3 的竖条 |
| `#page-video .q-title` left 58 / right 10 / top 14 | 同上 |
| `#page-video .q-len` right 8 / bottom 8 | 同上 |
| `#page-video .q-play` left 58 / bottom 8 | 「正在播放」 |
| `.file-card` padding 12 / border 1 / radius 8 | 同上（高 = 内容 + 24） |
| `.file-brief` margin-top 4 | 摘要上 4 |
| `.file-rows` margin-top 8 / `.file-row` 高 18 / 标签列 60 | 同上 |

原型的 token：`--space-1..5` = 4 / 8 / 12 / 16 / 24，`--radius-s` = 4、`--radius-m` = 8，`--t-sm` / `--t-md` / `--t-lg` = 12 / 15 / 18。QML 里没有这些 token，数字直接写在文件里。

## 7. 改这一页的检查清单

- [ ] 新 `.qml` 放进 `VideoLayout/`，一个文件一个根组件，文件名 = 根组件名（PascalCase）
- [ ] 写进 `quick-media-player/CMakeLists.txt` 的 `QML_FILES`；新图标放进 `resources/PlayWidgetIcons/`（或对应目录）并写进 `RESOURCES`
- [ ] 颜色只从 `theme.json` 取；新增的键 Dark 和 Light 两套都要加，名字沿用 `<部件><状态>`（`queueItemHover`、`logoNormal`）
- [ ] 布局用 `anchors`，这一页不用 `QtQuick.Layouts`
- [ ] 文件里有 delegate 或内联 `component` 的，加 `pragma ComponentBehavior: Bound`，否则 `qmllint` 报 unqualified access
- [ ] `/home/Qt/6.5.3/gcc_64/bin/qmllint <文件>` 干净、`cmake --build build` 通过
- [ ] 深色和浅色两套主题各看一遍；正文文字按 4.5:1、非文字图形按 3:1 核
- [ ] 注释写中文，说明为什么，不翻译是什么
- [ ] 提交一行中文，`feature：` / `fix：`，身份 `cursor-agent`

## 8. 这一版没做的（等后端接上）

1. 队列数据是 `VideoPage` 里写死的三条，字段：`name`、`length`、`path`、`format`、`resolution`、`codec`、`decoder`、`audio`、`size`。等 `PlayList` 单例。
2. `VideoPage.currentIndex` 默认 0，所以队列第一行默认选中、信息区默认有内容；原型是点过队列行才有内容。接真数据时这里要跟着改成“未选中”。
3. 画面五个状态只是显示，没接解码，`playing` 那一态还是空的。
4. 控制条点了不接播放，进度只显示不能拖。
5. 倍速、模式只有文字，没有下拉菜单；音量只有图标，没有滑条。
6. 队列不能拖拽排序，也不能删除、多选。
