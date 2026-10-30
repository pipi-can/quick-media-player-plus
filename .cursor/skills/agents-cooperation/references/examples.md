# 示例：一套完整的 `agents-cooperation/` 目录

下面这套示例照着格式抄就能用。**注意：示例文档不要放进 `agents-cooperation/` 本身**，否则 `get-index.sh` 会把示例里的块也数进去、编号就乱了。示例放本 skill 的 `references/` 里就行。

> 本例取自一个 Qt 播放器工程，所以功能叫 `playback` / `playlist` / `theme`。
> **这些名字只是举例**——换一个工程就换成那个工程自己的功能划分（比如电商后台可能是 `orders` / `refund` / `shipping`）。
> 固定的只有：目录叫 `agents-cooperation/`、一功能一文件夹、块格式、脚本。
>
> 另外注意：**本文里出现的块都包在围栏代码块里**（就是下面那些 ```` ``` ````）。这正是推荐做法——
> 在协作目录里演示块格式时，一定要套围栏，否则脚本会把示例当成真块。

## 目录长这样

```
agents-cooperation/                  # 放仓库根目录（这个名字是固定的）
├── _coop-common.sh                  # 脚本共用解析库（coop-init.sh 铺好，别动）
├── get-index.sh                     # 编号 + 块清单
├── coop-find.sh                     # 按关键词 / 编号找块（删模块前必用）
├── coop-lint.sh                     # 格式校验
├── coop-history.sh                  # 拉某个块的提交历史
├── coop-review.sh                   # 摆出自评要用的材料
├── coop-new-block.sh                # 建新块
├── coop-record.sh                   # 回写分支 / commit
├── coop-hook.sh                     # git 钩子实际跑的东西
├── coop-init.sh                     # 铺脚本 / 装钩子 / 对账（副本，正本在 skill 的 assets/）
├── index-reserved.txt               # 编号预留表（要提交）
├── .gitignore                       # 忽略编号锁文件
├── _repo/                           # `_` 开头 = 不是协作块
│   └── build.md                     # 怎么构建 / 怎么测（编译验证用）
├── playback/                        # 功能文件夹 ← 名字随仓库（这里是 Qt 播放器）
│   └── 播放控制实现思路.md            # 文档名也随仓库
├── playlist/
│   └── 播放队列实现思路.md
└── theme/
    └── 主题切换实现思路.md
```

命名习惯（**不是硬性规定，按本仓库习惯来**）：

- 功能文件夹：一般用英文小写，多词用 `-` 连（`media-probe`）或直接连写（`playback`）；
- 文档名：一句话说清这篇记录的是什么（`播放控制实现思路.md`），中英文都行；
- 一个功能一个文件夹；一个文件夹里可以有多篇文档；一篇文档里可以有多个块。

---

## 示例一：`playlist/播放队列实现思路.md`

这篇文档里有 **两个块**：#3 是队列本体，#7 是队列和 UI 的对接。中间靠「字段顺序倒退」自动切开，不需要写任何分隔线。

```markdown
# 播放队列

## 队列本体

[Index]: 3
[Valid]: true
[Author]: cursor-agent
[Title]: 播放队列实现思路（PlayList 单例 + 两条队列）
[GitBranch]: master
[GitCommitIds]: ["d9fe736", "b61b513", "38149f3"]
[Comments]:
  目标：视频和音乐各自一条队列，支持顺序 / 单曲循环 / 列表循环 / 随机 / 单曲播放五种模式。
  设计：
    - PlayList 做成单例（getInstance() + QMutex 保护），不注册成 QML 类型，
      统一在 main.cpp 里 setContextProperty 暴露成 "PlayList"，和 AppSettings 一个路子。
    - 两条队列共用同一套结构，用一个 QueueKind 枚举区分，不写两遍。
    - 切换播放模式只改 currentMode 一个字段 + 发 modeChanged 信号，
      谁关心谁自己听，队列不反过来直接调播放器，避免双向依赖。
  取舍：
    - 试过用 QAbstractListModel 直接喂给 QML 的 ListView，但队列里存的是 MediaFile 结构体，
      不是展示字段，最后还是走 Q_INVOKABLE 取数据、QML 只读，简单且不绑死 UI。
  遗留：
    - 随机模式先做成「洗牌后顺序播」，没做真正的历史回溯，所以"上一首"在随机模式下是假的。
  ---
  后续补充（opencode-agent，见 d9fe736）：
    - 把上面那条遗留问题解决了：加了一个 prevStack，随机模式下"上一首"退回真正播过的上一首，
      不再是洗牌序列里的前一个。
    - 顺带把 nextIndex 的计算从"取模"改成"prevStack 优先"，其余不变。

## 队列与 UI 对接

[Index]: 7
[Valid]: true
[Author]: opencode-agent
[Title]: 播放队列与 QML 列表对接
[GitBranch]: master
[GitCommitIds]: ["a15de5e"]
[Comments]:
  顺着 #3 的结论继续：队列只存数据、只发信号，UI 侧只读，不改这条线。
  设计：
    - QML 通过 PlayList.queue(kind) 拿一个 QVariantList，列表变化靠 queueChanged 信号整体刷新。
    - 不做增量 diff——队列最多几百条，整体刷新比维护 diff 省事得多，也少一类 bug。
  为什么不开一个新通道给视频页：
    - 视频页和音乐页读的是同一条接口，只是 kind 不同，保持一致以后好维护。
```

**逐块解说**

- `#3` 是纯数字编号 → agent 写的，全局唯一。
- `[GitCommitIds]` 里三个 sha，**最新在最前**（`d9fe736` 是最后那次提交）。后来者从前往后逐个 `git show`，就能看到这条思路是怎么演进的。
- `[Author]` 写的是**最初**写这个块的人（`cursor-agent`）。`opencode-agent` 后来续写了同一个块，但**没有改 Author**，而是在 `[Comments]` 里加了一段"后续补充（opencode-agent，见 d9fe736）"。这样：`[Author]` 说明块从哪来，每一条 commit 的 `Coop-Author` trailer 说明那一次是谁做的。
- `#7` 是同一篇文档里的第二个块，因为字段顺序又从头开始（`[Index]` 出现在 `[Comments]` 之后），脚本自动切成新块。
- 两个块都用同一行 `---` 做了视觉分隔。**这只是给人看的，脚本不依赖它**，删掉也不影响解析。

---

## 示例二：`theme/主题切换实现思路.md`

这篇演示**人写的块**（没写 `[Index]`）和**已作废的块**（`[Valid]: false`）。

```markdown
# 主题切换

[Valid]: true
[Author]: ren
[Title]: 亮色主题的品牌图标配色
[GitCommitIds]: ["fa47066"]
[Comments]:
  我自己手改的，没走流程，先记一笔。
  亮色主题下品牌图标原来用的是 accentInkNormal 太深，改成主题色；
  文字用的深蓝单独拆一个 accentInkNormal，别再混用。
  只有这一个改动，其它没动。

[Index]: 9
[Valid]: false
[Author]: cursor-agent
[Title]: 用 QSettings 存主题偏好的第一版
[GitBranch]: feat/theme-settings
[GitCommitIds]: ["1e91b90"]
[Comments]:
  【已作废，别参考】
  原来想直接用 QSettings 落盘，后来发现工程统一走 AppSettings 单例，
  这个分支没合并，留着只作为历史记录。
  作废原因：和 AppSettings 的职责重复，人已确认弃用。
```

**逐块解说**

- 第一个块**整块没有 `[Index]` 行**，`[Author]` 是 `ren`（不以 `agent` 结尾 → 人类块）。agent 扫到时候要替它补编号，格式是 `<作者>-<序号>`：
  - `get-index.sh` 会算出 `ren` 目前用到的最大序号，然后建议 `ren-1`；
  - agent 把这一行补进去：`[Index]: ren-1`（补在 `[Valid]` 前面，保持字段顺序）。
- 第二个块 `[Valid]: false` → 扫到直接跳过，**连 `[Comments]` 都别读**。
- 人类块用的是字符串编号 `ren-1`，**不参与全局纯数字最大值的计算**，不会占掉 agent 的编号空间。

---

## 示例三：`playback/播放控制实现思路.md`（第一次新建，还没提交）

这是"新功能第一次做"的样子：`[GitBranch]` 和 `[GitCommitIds]` 都是 `null`，等提交之后回写。

```markdown
# 播放控制

[Index]: 8
[Valid]: true
[Author]: opencode-agent
[Title]: 播放暂停按钮的状态同步
[GitBranch]: null
[GitCommitIds]: null
[Comments]:
  目标：底部播放键要在"播放 / 暂停"之间正确切换图标，并且和 player 的真实状态一致。
  设计：
    - 图标按钮不再用单独的 IconButton，照 TitleBar 的做法：ColorImage + MouseStateItem，
      状态切换交给 MultiStateItem，别在 QML 里写 if-else 切图。
    - 按钮不自己存 isPlaying，直接绑 player.state，避免"按钮说在播、播放器其实停了"。
  为什么：
    - 工程里已经有两套按钮写法（IconButton 和 ColorImage+MouseStateItem），
      这次统一到后者，少维护一套。
```

写完之后（`./` 指 `agents-cooperation/`）：

1. `./coop-lint.sh` 自检格式；
2. `git add` 这个 md + 改动的文件，提交；
3. `./coop-record.sh 8` —— 自动把 sha 填进 `[GitCommitIds]`、把 `[GitBranch]` 填成当前分支；
4. 再提交一次（登记用）。

回写后这个块头部变成：

```markdown
[Index]: 8
[Valid]: true
[Author]: opencode-agent
[Title]: 播放暂停按钮的状态同步
[GitBranch]: master
[GitCommitIds]: ["3f2a1c9"]
[Comments]:
  ...
```

---

## 跑一下 `get-index.sh`

上面三篇文档放好后，执行：

```bash
./agents-cooperation/get-index.sh
```

输出（`#(缺)` 表示人类块还没补编号）：

```text
下一个可用编号: 10

缺编号的人类协作块（建议补成 <作者>-<序号>）:
  - theme/主题切换实现思路.md  [Author: ren] -> 建议 [Index]: ren-1  《亮色主题的品牌图标配色》

现有协作块:
  #8  [true]  opencode-agent  播放暂停按钮的状态同步  (playback/播放控制实现思路.md)
  #3  [true]  cursor-agent  播放队列实现思路（PlayList 单例 + 两条队列）  (playlist/播放队列实现思路.md)
  #7  [true]  opencode-agent  播放队列与 QML 列表对接  (playlist/播放队列实现思路.md)
  #(缺)  [true]  ren  亮色主题的品牌图标配色  (theme/主题切换实现思路.md)
  #9  [false]  cursor-agent  用 QSettings 存主题偏好的第一版  (theme/主题切换实现思路.md)
```

- `下一个可用编号: 10` —— 纯数字里最大的是 `#9`，加一就是 `10`。`ren-1` 这种人类编号不算在里面。
- agent 要新开块时，就用 `10`。
- 要补编号时，照着「缺编号的人类协作块」那一段填：`ren` 目前一个编号都没有，所以建议 `ren-1`。

只看下一个编号（脚本里用）：

```bash
next=$(./agents-cooperation/get-index.sh --next)
```

---

## 示例四：删模块之前，先找出依赖它的块（**必须先问用户**）

假设用户说："`AudioCtx` 不要了，删掉吧。"

**不许直接删。** 先搜：

```bash
./agents-cooperation/coop-find.sh AudioCtx
```

输出：

```text
#3  播放控制（Player 单例 + 状态机）  (playback/播放控制实现思路.md)
   playback/播放控制实现思路.md:14    约定：所有音频都经过 AudioCtx，别绕过它直接调后端。
   playback/播放控制实现思路.md:22    落点：sources/audio/AudioCtx.cpp。

#7  音频后端切换  (playback/播放后端实现思路.md)
   playback/播放后端实现思路.md:9    目标：通过 AudioCtx 在后端 A/B 之间切换。
```

然后**把清单摆给用户，等同意**：

> 要删的模块：`AudioCtx`（`sources/audio/AudioCtx.*`）。
>
> 下面这两个块的思路依赖它，将被置为 `[Valid]: false`（**不会删除块**，只是不再作为参考）：
>
> | 块 | 标题 | 文件 |
> | --- | --- | --- |
> | `#3` | 播放控制（Player 单例 + 状态机） | `playback/播放控制实现思路.md` |
> | `#7` | 音频后端切换 | `playback/播放后端实现思路.md` |
>
> 同意的话我就：① 把这两个块置 `false`，并各自在 `[Comments]` 末尾记一句"因删掉 `AudioCtx` 而废弃（opencode-agent，见 `<sha>`）"；② 提交消息里写"作废块 #3 #7"。
> 不同意就告诉我保留哪个。

用户同意后，块变成这样（**整块保留，只改 `[Valid]` 和追加一行**）：

```markdown
[Index]: 7
[Valid]: false
[Author]: cursor-agent
[Title]: 音频后端切换
[GitBranch]: master
[GitCommitIds]: ["a11c002"]
[Comments]:
  目标：通过 AudioCtx 在后端 A/B 之间切换。
  设计：AudioCtx 里持有两个 backends，按配置选一个。
  ---
  已废弃（opencode-agent，见 d5e77a1）：AudioCtx 按用户要求删除，本方案不再适用。
```

> 要点：**块一行都没删**——"这条路走不通"本身就是有用的信息。删除会让编号被回收，
> 后人再用同一个编号时，`Coop-Block` 反查就串台了。

---

## 示例五：`_repo/build.md`（不是协作块）

`coop-init.sh` 会生成这个模板；第一次确认完就填好并提交，之后每个 agent 都照着跑，不用重新猜：

```markdown
# 本仓库怎么构建 / 怎么测

## 构建
- 命令：`cmake -B build -DCMAKE_BUILD_TYPE=Debug && cmake --build build -j8`
- 首次要跑的前置：`sudo apt install libqt6svg6-dev`
- 已知会失败的情况：不做 `qmake` 时 `*_autogen` 会缺，先跑一次完整配置

## 测试
- 命令：`ctest --test-dir build --output-on-failure`

## 运行 / 冒烟
- 命令：`./build/quick-media-player`

## 备注
- 全量构建太慢时，可以只编目标：`cmake --build build --target quick_media_player -j8`
```

---

## 示例六：提交前那两段输出（编译 + 自评）

写完代码、提交之前，回复里要出现这两段（格式见 [build-verify.md](build-verify.md) 和 [code-review.md](code-review.md)）：

```text
## 编译验证
- 命令：`cmake --build build -j8`
- 结果：✅ 通过
- 只编了目标 `quick_media_player`；没跑真机。

## 验收对照（块 #10 的验收标准）
- [x] 切歌能自动匹配歌词
- [ ] 进度高亮实测有 ~120ms 漂移 → 记进块里的遗留问题

## 自评打分
| 维度 | 得分 | 为什么给这个分 | 扣分点（指到 文件:行） |
| --- | --- | --- | --- |
| 可读性 | 8/10 | 命名清楚、结构可扫 | -1 `LyricSync.cpp:88` 的 `120` 没说明；-1 少了一处为什么这样做的注释 |
| 最小实现与合理性 | 9/10 | 复用已有网络单例 | -1 `LyricSync.cpp:140` 加了个没人调用的 `forceReload()` |
| 协作风格一致性 | 8/10 | 命名 / 日志 / 目录都跟了现有风格 | -1 注释里混了一句英文 |
| 安全性 | 10/10 | 网络响应有长度上限和超时；无敏感信息 | 无 |
| **总分** | **35/40（B）** | | |

## 过程要求
- [x] 一个提交只服务块 #10；正文有思路；带 `Coop-Block` / `Coop-Folder` / `Coop-Author`

## 我最不放心的三点
1. 高亮的 `120ms` 阈值是拍脑袋定的，弱网可能不够。
2. 只验证到编译通过，没在真机上听歌验证。
3. `forceReload()` 是我留着调试用的，忘了删。
```

**B 档 → 这三条要写进块 `#10` 的 `[Comments]` 遗留问题那段。**

