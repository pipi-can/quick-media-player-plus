# 演练：从用户提需求到提交回写

下面是三次真实的走法。照着做就行。`<...>` 表示你要替换成实际值。

---

## 场景 A：顺着已有块继续写（最常见）

### 用户说

> 给播放页加一个音量弹窗，点音量图标弹出来能拖。

### 第 1 步：抽关键词，定位功能文件夹

关键词是「播放」「音量」→ 先看 `agents-cooperation/playback/` 和 `agents-cooperation/playlist/`。

```bash
ls agents-cooperation/
```

### 第 2 步：跑编号工具，拿块清单

```bash
./agents-cooperation/get-index.sh
```

```text
下一个可用编号: 10

缺编号的人类协作块（建议补成 <作者>-<序号>）:
  - theme/主题切换实现思路.md  [Author: ren] -> 建议 [Index]: ren-1  《亮色主题的品牌图标配色》

现有协作块:
  #3  [true]  cursor-agent  播放队列实现思路（PlayList 单例 + 两条队列）  (playlist/播放队列实现思路.md)
  #7  [true]  opencode-agent  播放队列与 QML 列表对接  (playlist/播放队列实现思路.md)
  #(缺)  [true]  ren  亮色主题的品牌图标配色  (theme/主题切换实现思路.md)
  #9  [false]  cursor-agent  用 QSettings 存主题偏好的第一版  (theme/主题切换实现思路.md)
```

### 第 3 步：过滤

- `#9` 是 `[false]` → 跳过，正文都不看。
- `ren` 那个是主题颜色 → 和音量无关 → 跳过。
- `#3` 讲队列、`#7` 讲队列对接 UI → 标题跟音量无关，但**同一个功能文件夹**，值得快扫一眼 `[Comments]`，看看有没有"播放相关统一走哪条线"的约定。

这一步的关键心态：**先按标题判断，无关的就别读正文**。省下来的 context 用来把相关的读透。

### 第 4 步：读思路 + 倒着看提交

读 `#3` 的 `[Comments]`，看到这条约定：

> 播放相关的一切都从 `player` / `PlayList` 两个单例出，别另开通道。

再按 `[GitCommitIds]` 从头（最新）往后看：

```bash
git show d9fe736 --stat
git show b61b513 --stat
git show 38149f3 --stat
```

（`[GitBranch]` 是 `master`，和当前分支一致，直接看就行；如果它写的是别的分支，也不用切，同一个仓库 `git show <sha>` 一样能看。）

### 第 5 步：发现有不清楚的地方 → 停下来问

`#3` 只说了"从单例出"，但没说：

- 音量归 `player` 管，还是要新开一个 `AudioCtx` 单例？
- 弹窗放 `qml/layouts/` 还是 `qml/popups/`？
- 拖动的值写回哪里？

**这些不能猜。** 向用户提问（写成能一句话拍板的形式）：

> 音量弹窗有几个点想跟你确认：
> 1. 音量值我打算挂在 `player` 上（加 `volume` 属性 + `setVolume`），不新开单例——和 `#3` 的约定一致。可以吗？
> 2. 弹窗文件放 `qml/layouts/VolumePopup.qml`，还是 `qml/popups/` 下？工程里现在是哪个约定？
> 3. 拖动是实时改音量，还是松手才生效？

### 第 6 步：用户回答后动手

假设用户答：挂 `player`、放 `qml/layouts/`、实时改。

写代码，**沿着** `#3` 的思路（不新开通道、QML 只读属性）。

### 第 7 步：新建协作块

音量弹窗是新功能，和 `#3`（队列）、`#7`（队列对接）都不是一回事 → **新开一个块**。

编号别手算，用脚本建骨架：

```bash
./agents-cooperation/coop-new-block.sh -f playback -t "音量弹窗实现思路" -a opencode-agent
```

它自动取编号、建好字段、把 `[Comments]` 留成 TODO。你把 TODO 换成真正的思路：

```markdown
[Index]: 10
[Valid]: true
[Author]: opencode-agent
[Title]: 音量弹窗实现思路
[GitBranch]: null
[GitCommitIds]: null
[Comments]:
  目标：点音量图标弹出滑条，拖动实时改音量。
  沿用 #3 的约定：播放相关只走 player 单例，不新开通道。
  设计：
    - player 加 volume 属性（0~1）+ setVolume()，QML 用 Binding 双向绑。
    - 弹窗放 qml/layouts/VolumePopup.qml（和工程现有约定一致），
      用 MouseStateItem 处理拖动，不引 Qt Quick Controls。
  已和用户确认（2026-xx-xx）：
    - 音量挂 player，不新开单例；
    - 目录用 qml/layouts/；
    - 拖动实时生效，不做松手才提交。
```

### 第 8 步：校验 + 提交

```bash
./agents-cooperation/coop-lint.sh          # 格式自检，有错先修
git add qml/layouts/VolumePopup.qml qml/pages/PlayerPage.qml \
        includes/player/player.h sources/player/player.cpp \
        agents-cooperation/playback/播放控制实现思路.md
git commit
```

消息：

```text
feat(player): 新增音量弹窗，拖动实时改音量

音量挂在 player 单例上（volume 属性 + setVolume），沿用 #3 "播放相关只走单例"的约定，
不新开通道；弹窗放 qml/layouts/，拖动用 MouseStateItem 实现。

Coop-Block: 10
Coop-Folder: playback
Coop-Author: opencode-agent
```

### 第 9 步：回写

```bash
./agents-cooperation/coop-record.sh 10
```

它自动把刚提交的 sha 插到 `[GitCommitIds]` 最前面、把 `[GitBranch]` 填成当前分支：

```markdown
[Index]: 10
[Valid]: true
[Author]: opencode-agent
[Title]: 音量弹窗实现思路
[GitBranch]: master
[GitCommitIds]: ["3f2a1c9"]
```

再提交一次：

```text
docs(agents-cooperation): 回写协作块 10 的提交记录

把音量弹窗这次提交（3f2a1c9）登记进 agents-cooperation 的块 #10。

Coop-Block: 10
Coop-Folder: playback
Coop-Author: opencode-agent
```

**完事。** 下一个 agent（哪怕是 Cursor）扫到这个块，就知道音量挂在 `player` 上、文件放哪、为什么这么放。

---

## 场景 B：全新功能，从头建目录

### 用户说

> 帮我加个在线歌词。

### 第 1 步：跑工具，发现没有对应文件夹

```bash
./agents-cooperation/get-index.sh
# 输出里没有任何 lyric / network 相关的块
ls agents-cooperation/    # 没有 network/
```

### 第 2 步：这是第一次做 → 提问（信息明显不够）

> 在线歌词我这边缺几个信息，先跟你对齐：
> 1. 歌词源用哪个？（自建接口 / 网易云 / QQ 音乐 / 先只做一个固定的测试 URL）
> 2. 归到哪个功能文件夹？我打算新建 `agents-cooperation/lyrics/`。
> 3. 代码放哪？`includes/lyrics/` + `sources/lyrics/`？
> 4. 拉到的歌词怎么和当前播放的 MediaFile 关联？靠文件名匹配还是靠元数据里的标题？
> 5. 要不要缓存到本地？

### 第 3 步：用户回答后，建目录 + 建块

```bash
./agents-cooperation/coop-new-block.sh -f lyrics -t "在线歌词拉取与匹配" -a opencode-agent
```

脚本会建好 `agents-cooperation/lyrics/实现思路.md` 和块骨架，把 `[Comments]` 的 TODO 换成真正的思路：

```markdown
[Index]: 11
[Valid]: true
[Author]: opencode-agent
[Title]: 在线歌词拉取与匹配
[GitBranch]: null
[GitCommitIds]: null
[Comments]:
  目标：播放时按当前歌曲去拉歌词，滚动显示。
  设计：
    - 新开 LyricsFetcher 单例，main.cpp 里 setContextProperty 暴露成 "Lyrics"（沿用工程"后端单例"惯例）。
    - 匹配用 MediaFile 的 title+artist，拿不到才回退到文件名模糊匹配。
    - 先做内存缓存（QHash<key, QString>），落盘缓存留 TODO。
  已和用户确认（2026-xx-xx）：
    - 歌词源：先用固定测试 URL，不做多源切换；
    - 代码：includes/lyrics/ + sources/lyrics/；
    - 不做落盘缓存。
  遗留：
    - 多源切换、落盘缓存都还没做。
```

然后照场景 A 的第 8、9 步（`coop-lint.sh` → 提交 → `coop-record.sh`）走完。

---

## 场景 C：用户的要求和已有块冲突 → 问清楚再动

### 用户说

> 别搞那个单例了，音量弹窗直接把值存到 QML 里就行，简单点。

这和 `#10`（以及 `#3`）里"播放相关只走 player 单例"的约定**直接冲突**。**不要默默按用户说的改**，也不要默默按块的思路来。停下来问：

> 提醒一下：`agents-cooperation/playback/播放控制实现思路.md` 里的块 `#10` 约定"音量挂在 player 单例上"，你现在说的做法和它冲突。想怎么处理？
>
> A. 按你说的来（QML 里存值），我同时**改掉 `#10` 的 `[Comments]`**，并在这次提交里写明"协作块 10 的 Comments 被修改"；
> B. 还是按 `#10` 的老思路（挂 player），不改文档；
> C. 你其实是想推翻 `#10` 整条思路 → 那我新开一个块，把 `#10` 置 `[Valid]: false`（这个也要你点头）。

### 用户选 A 的话

1. 改 `#10` 的 `[Comments]`，把旧思路划掉、写清新思路和"为什么改"；
2. 提交消息里**明确写出来**：

```text
refactor(player): 音量改为 QML 侧存储，去掉 player.volume

按用户要求简化：音量不再挂 player 单例。
注意：本次修改了协作块 10 的 [Comments]（协作块 10 的 Comments 被修改）。
Coop-Block: 10
Coop-Folder: playback
Coop-Author: opencode-agent
```

这样后来者 `git log --grep='^Coop-Block: 10$'` 就能看到"这条思路在什么时候、被谁、因为什么改了"。

### 用户选 C 的话

新开一个块（编号取 `get-index.sh` 的下一个），`[Comments]` 里写明"取代 #10，原因……"；再把 `#10` 的 `[Valid]` 改成 `false`，并在提交消息里写明"协作块 10 被作废"。
