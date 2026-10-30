# 提交消息：模板与正反例

提交消息是协作链条里最关键的一环——**后来者主要靠 `git log` 理解你当时为什么这么写**。块里的 `[Comments]` 讲"整体思路"，提交消息讲"这一步改了什么、为什么"。

## 模板

```text
<标题：这一版实现了什么>

<正文：实现思路；和块里的 [Comments] 对齐，但讲的是"这一次">

<可选：一行结论 —— 提交前跑过的编译验证 + 自评分数>
编译：✅ cmake --build build -j8 ｜ 自评：34/40（B，遗留见块 #3）

Coop-Block: <块编号>
Coop-Folder: <功能文件夹名>
Coop-Author: <你的 agent 名>
```

四条纪律：

1. **标题**一句话说清"实现了什么"。别写"修改代码""更新文件""fix bug"这种废话。
2. **正文**写思路，不能省。这是协作参考的核心指标。
3. **trailer** 三个都要写，用来反查。块编号、文件夹名要跟块里的一致。
4. **结论一行**（可选但推荐）：带上编译验证结果和自评分数——review 的人扫一眼就知道"验证到哪一步了"。没编译就写"未编译，原因 X"。

---

## 正例

### 1. 新功能第一次提交

```text
feat(player): 新增音量弹窗，拖动实时改音量

音量挂在 player 单例上（新增 volume 属性 + setVolume），沿用协作块 #3
"播放相关只走 player / PlayList 两个单例"的约定，不另开通道。
弹窗放 qml/layouts/VolumePopup.qml，拖动用 MouseStateItem 实现，
不引 Qt Quick Controls。

Coop-Block: 10
Coop-Folder: playback
Coop-Author: opencode-agent
```

好在哪里：标题说清了"做了什么"；正文交代了**关键决策**（挂哪个单例、放哪、用什么控件）和**依据**（`#3` 的约定），后来的 agent 读完就知道该顺着哪条线走。

### 2. 续写已有块

```text
fix(playback): 随机模式的"上一首"改用真实历史

协作块 #3 留下的遗留问题：随机模式是洗牌后顺序播，prevStack 是假的，
"上一首"会跳到洗牌序列的前一个而不是真正播过的那个。
本次加了一个 prevStack，nextIndex 优先从 prevStack 取，取空才走洗牌序列。
其余队列逻辑不动。

Coop-Block: 3
Coop-Folder: playlist
Coop-Author: opencode-agent
```

好在哪里：明确说"这是在 #3 的基础上补的"，并解释了改动边界（"其余逻辑不动"），避免后来者以为整条队列都被重写了。

### 3. 第一次提交 + 回写（两步）

第一次（带代码和块）：

```text
feat(lyrics): 新增在线歌词拉取与匹配

新建 LyricsFetcher 单例，按 MediaFile 的 title+artist 匹配歌词，
拿不到才回退文件名；先做内存缓存 QHash<key, QString>，落盘缓存留 TODO。
代码在 includes/lyrics/ 和 sources/lyrics/。

Coop-Block: 11
Coop-Folder: lyrics
Coop-Author: opencode-agent
```

第二次（只回写登记信息）：

```text
docs(agents-cooperation): 回写协作块 11 的提交记录

把歌词拉取这次实现（4b1e0a2）登记进 agents-cooperation 的块 #11。

Coop-Block: 11
Coop-Folder: lyrics
Coop-Author: opencode-agent
```

### 4. 修改了某个块的 Comments（必须写明）

```text
refactor(player): 音量改为 QML 侧存储，去掉 player.volume

按用户要求简化：音量不再挂 player 单例，改由播放页自己持有。
注意：本次修改了协作块 10 的 [Comments]（协作块 10 的 Comments 被修改）。

Coop-Block: 10
Coop-Folder: playback
Coop-Author: opencode-agent
```

好在哪里：**把"改了协作块的 Comments"这件事显式写在消息里**。后来者 `git log --grep='协作块 10'` 一眼就能看到思路是在什么时候、因为什么被改掉的。

### 5. 作废一个块

```text
refactor(theme): 主题偏好改走 AppSettings，作废块 9

块 #9 用 QSettings 直接落盘，和 AppSettings 单例职责重复，人已确认弃用。
本次把 #9 的 [Valid] 置为 false，并新增块 #12 走 AppSettings。

Coop-Block: 12
Coop-Folder: theme
Coop-Author: cursor-agent
```

---

## 不用登记时：`Coop-Skip: <原因>`

改动**不涉及功能 / 接口 / 取舍**（纯文案、注释、格式、笔误，或只在块里回写 `[GitCommitIds]`）→ 不用建/续写块，但提交照旧要做，正文带一行原因：

```text
docs: 修正 README 里的错别字和过期的截图链接

Coop-Skip: 只改了文档，无行为变化
```

```text
chore(agents-cooperation): 回写协作块 10 的 [GitCommitIds] 和 [GitBranch]

Coop-Skip: 纯登记操作
```

- 钩子**只认两样**：`Coop-Block: <编号>` 或 `Coop-Skip: <非空原因>`，都没有就拦下。
- 这行必须写清**为什么不用登记**——`Coop-Skip: 小改动` 这种等于没写。
- 事后审计：`git log --grep='^Coop-Skip:'` 能列出所有"没登记"的提交，一眼看出有没有人拿它当挡箭牌。
- **建议顺手带一行 `Coop-Author: <你的名字>`**（钩子不强制）：这样"没登记的改动是谁做的"也查得到，不然审计只看到"没登记"，看不到"谁没登记"。

---

## 反例

### 1. 标题是废话

```text
修改代码

改了一些东西。
```

问题：后来者完全不知道这步干了什么，`[GitCommitIds]` 指过来也白指。

### 2. 正文省略思路

```text
feat(player): 加音量弹窗

Coop-Block: 10
Coop-Folder: playback
Coop-Author: opencode-agent
```

问题：只说"加了什么"，没说为什么这么加、依据哪条约定。下一个 agent 只能自己重新猜，等于没协作。

### 3. 漏 trailer

```text
feat(player): 加音量弹窗

音量挂 player，弹窗放 layouts。
```

问题：`git log --grep='^Coop-Block: 10$'` 搜不到这条，反查断链。

### 4. 一次提交塞多个块

```text
feat: 加音量弹窗 + 改主题配色 + 修歌词匹配

Coop-Block: 10
Coop-Folder: playback
Coop-Author: opencode-agent
```

问题：trailer 只能写一个块，另外两个改动就丢了归属。**一个提交只服务一个块**；真要一起做，分几次提交。

---

## 反查命令

按块找历史：

```bash
git log --grep='^Coop-Block: 3$'
```

按作者找：

```bash
git log --grep='^Coop-Author: cursor-agent$'
```

按功能找：

```bash
git log --grep='^Coop-Folder: playback$'
```

> 三个都**锚定 `^…$`**。不锚定的话 `Coop-Block: 3` 会连 `Coop-Block: 30` 一起捞出来（实测过）。

看某个块的全部实现细节：

```bash
git log --grep='^Coop-Block: 3$' --oneline    # 先列出所有相关提交
git show <sha>                               # 再逐个看
```

---

## 其他纪律

- **提交到本地当前分支**，用户没要求就别 `push`。
- 用户要求开功能分支时：`git checkout -b <feature>`，并把分支名记进块的 `[GitBranch]`——后来者可以直接切过去看。
- 提交前 `git status` 确认没有把不该提交的临时文件带进去。
