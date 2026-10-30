---
name: agents-cooperation
description: 多个 AI（cursor / opencode / 其他）和人协作改同一个仓库时的「实现思路登记与沿用」流程。**改动涉及功能 / 接口 / 取舍时**用它：到仓库的 agents-cooperation/ 找同功能的协作块，按它记录的思路继续实现；写完先编译、再按 references/code-review.md 自评打分，最后 git 提交并把 commit 回写到协作块。要不要登记的判断标准（三问）见 .cursor/rules/agents-cooperation.mdc；纯文案 / 注释 / 格式 / 笔误 / 纯登记的改动不用登记，提交时正文带一行 Coop-Skip 即可。Use this in ANY repository when a change touches user-visible behavior, shared interfaces, or involves a design tradeoff — adding a feature, refactoring, fixing a bug with a choice to make, or collaborating with several agents/humans on one project. 纯读代码、不改文件，或只是改错别字 / 格式时不需要用。
---

# 多 AI 协作登记

> 这是**通用流程**：任何仓库、任何语言都能用。下文出现的 `playback` / `theme` / `播放控制实现思路.md` 之类，都只是**举例**——换一个工程就换成那个工程自己的功能划分。

## 为什么要这么做

同一个仓库可能被多个 AI（`cursor-agent`、`opencode-agent`……）和人轮流改。各写各的，很容易同一种功能出现两套互相打架的实现，后来者还得从头猜前人的意图。

所以约定：**每个功能的实现思路都登记到仓库根目录的 `agents-cooperation/` 里**。谁先写下思路，后来者就先读思路、顺着写，而不是从零重新设计。

一句话：**先看别人怎么想的，再决定自己怎么写。**

## 什么时候用

**判据在常驻规则文件里**（`.cursor/rules/agents-cooperation.mdc` 第一节）——动工作区文件前先过三问：

1. 改完以后，**用户能看到 / 用到的行为**变了吗？
2. **别人依赖的东西**变了吗？
3. **你有取舍吗**？

**任一为"是" → 走本流程。三问全"否" → 不用登记，但照样要提交**（正文带 `Coop-Skip: <原因>`）。
**拿不准 → 按"要登记"处理，或者先问用户。**

> 判据和记法以规则文件为**唯一来源**（`.cursor/rules/agents-cooperation.mdc` 第一节），这里给的是展开清单和例子。

必须登记 / 不用登记的常见情形：

| 必须登记 | 不用登记 |
| --- | --- |
| 新增功能；改行为 / 接口 / 数据结构 / 默认值 / 配置项 | 纯注释 / 文案 / 拼写 / 格式 / 空白 |
| 删或替换模块、类、文件；跨文件的功能性改动 | 只改散文文档；改明显笔误（无取舍） |
| 修 bug 且修法有取舍；动公共代码或被多处引用的东西 | 只在协作块里回写 `[GitCommitIds]` / `[GitBranch]` 这种纯登记 |
| 改依赖 / 构建 / 打包；性能或安全相关 | 只调样例数据、测试数据 |

**拿不准时**的判法，见 [references/faq.md](references/faq.md)（里面有针对"改脚本 / 改配置 / 改 `.gitignore` 一行 / 界面文案"这类边界问题的回答）。

下面只讲**走流程时**该怎么办。只读代码、回答问题、不落盘 → 不走。

### 不用登记时怎么提交

不用登记 ≠ 不用提交。正文里带一行原因：

```
fix: 修正 README 里的错别字

Coop-Skip: 只改了文档错别字，无行为变化
```

- 这行让"这次为什么没登记"可以被事后审计：`git log --grep='^Coop-Skip:'`。
- 提交前**不用**跑 `coop-lint.sh`、**不用**编译验证、**不用**自评打分——它们是为"登记"路径准备的。
- 但**别拿它当挡箭牌**：只要改动真的涉及行为 / 接口 / 取舍，就必须走下面的流程。装好的 `commit-msg` 钩子会拦住"既没有 `Coop-Block` 也没有 `Coop-Skip`"的提交。

## 流程

边做边勾（`./agents-cooperation/` 简称 `./`）：

```
- [ ] 1. 从用户提示词里抽出功能关键词，定位 agents-cooperation/<功能>/
       （定位不准就先搜：./coop-find.sh <关键词>）
- [ ] 2. ./get-index.sh --valid --folder <功能>     # 只列有效且相关的块
- [ ] 3. 无关的块连正文都别读；相关的读它的 [Comments]
- [ ] 4. ./coop-history.sh <编号>                   # 拉出这条思路的提交演进
- [ ] 5. 判断这条思路是否可靠、是否和用户本次要求一致；不一致就停下来问用户
- [ ] 6. 找不到相关块（= 新功能）→ **先问用户**：要不要建块？文件夹名 / 标题 / 目标 / 边界 /
       落点 / 约束 / 验收标准分别是什么（见 references/asking-users.md 的「新功能」一节）
- [ ] 7. 用户确认后建块，并把第 6 步问到的信息写进 [Comments]：
       ./coop-new-block.sh -f <功能> -t "<标题>"     # 续写已有块 → 跳过 6、7
- [ ] 8. **本次会不会删掉某个模块 / 文件 / 类？** 会的话：
       ./coop-find.sh <模块名>                      # 找出思路依赖它的块
       → 把"这些块将被置 [Valid]: false"列给用户 → **等用户同意**
       → 同意后才置 false（**只作废、不删块**）
- [ ] 9. 还有别的任何不明确的地方，继续问用户，别自己臆想
- [ ] 10. 动手写代码（沿用第 4 步吃透的思路），注释按 references/code-comments.md 写
- [ ] 11. **编译验证**：跑构建（命令见 agents-cooperation/_repo/build.md）；失败就把原因告诉用户，
        不要当成"做完了"（见 references/build-verify.md）
- [ ] 12. **自评打分**：./coop-review.sh → 按 references/code-review.md 打四个维度，
        把「验收对照 + 分数表 + 我最不放心的三点」发给用户；C 档先问、D 档先改（见 references/code-review.md 的等级处置）
- [ ] 13. ./coop-lint.sh                            # 提交前校验格式
- [ ] 14. git 提交：标题=实现了什么，正文=实现思路，尾部带 Coop-* trailer（块和代码一起提交）
- [ ] 15. ./coop-record.sh <编号>                   # 把这次提交回写进块
- [ ] 16. 提交这次回写
```

> 三条关键顺序：
> **① 问 → 建块（把信息写进 `[Comments]`）→ 写代码**（块里的思路是"动手之前的共识"，不是"写完之后的总结"）；
> **② 删东西 → 先找出对应块 → 告诉用户将作废 → 同意了才动**；
> **③ 写完代码 → 先编译 → 再自评打分 → 才提交**。

## 目录结构

协作目录固定叫 `agents-cooperation/`，放在**仓库根目录**，随仓库提交进 git：

```
agents-cooperation/
├── _coop-common.sh       # 各脚本共用的解析库（别单独跑）
├── get-index.sh          # 编号 + 块清单（只读）
├── coop-find.sh          # 按关键词 / 编号找块（只读）——删模块前必用
├── coop-lint.sh          # 格式校验（只读）
├── coop-history.sh       # 拉某个块的提交历史（只读）
├── coop-review.sh        # 摆出自评要用的材料（只读）
├── coop-new-block.sh     # 建新块（取号加锁，防并发撞号）
├── coop-record.sh        # 回写分支 / commit
├── coop-hook.sh          # git 钩子实际跑的东西
├── coop-init.sh          # 铺脚本 / 装钩子 / --check-sync 对账（副本，正本在 skill 的 assets/）
├── index-reserved.txt    # 编号预留表（要提交，防跨工作区撞号）
├── .gitignore            # 忽略编号锁文件
├── _repo/                # ← `_` 开头 = **不是协作块**，放仓库级说明
│   └── build.md          #   怎么构建 / 怎么测（编译验证用，要提交）
├── playback/             # ← 功能文件夹，名字按本仓库自己的叫法（这里只是举例）
│   ├── 播放控制实现思路.md   # ← 文档名也随本仓库习惯
│   └── 播放后端实现思路.md
└── theme/
    └── 主题切换实现思路.md
```

> **`_` 开头的文件 / 目录不是协作块**（脚本不解析、`get-index.sh` 不统计、`coop-lint.sh` 不检查）。
> 放"怎么构建""团队约定"这类仓库级说明。示例文档仍然**不要**放进协作目录，放 skill 的 `references/`。

**固定不变的部分**（脚本依赖，别改）：

- 目录就叫 `agents-cooperation/`，在仓库根目录；脚本平铺在里面；
- 一个功能一个文件夹；一个功能可以有多篇文档；一篇文档可以有多个块；
- 块的字段格式（见下）。

**随仓库而变的部分**（按本仓库的习惯来，别照抄上面的例子）：

- 功能文件夹怎么划分、叫什么（例：播放叫 `playback`，主题叫 `theme`）——**用本仓库对这个功能的叫法**，别生造新词；
- 文档名（中文、英文都行，例：`播放控制实现思路.md`）；
- 有没有更细的层级。

> 也就是说，"`playback/` 放播放、`theme/` 放主题"这类**只是示例**，换一个工程就该换成那个工程自己的划分。

另外：

- `agents-cooperation/` 要提交进 git，别 ignore 掉。
- **示例文档不要放进 `agents-cooperation/`**——脚本会把里面每个块都当成真块统计。示例放本 skill 的 `references/` 里。

## 协作块格式

```
[Index]: 3
[Valid]: true
[Author]: opencode-agent
[Title]: 播放队列实现思路
[GitBranch]: master
[GitCommitIds]: ["d9fe736", "5454a93"]
[Comments]:
  这里写实现思路，可以多行；续行缩进一级。
```

硬性规则（脚本靠这些识别，别随意改）：

- 每个字段**顶格**从行首开始写（`[Comments]` 的正文缩进一级，别顶格）。
- 字段顺序固定：`Index < Valid < Author < Title < GitBranch < GitCommitIds < Comments`。
  一旦某个字段**又一次出现**（顺序倒退），就当作上一个块结束、新块开始——所以块之间不用写分隔线，人类块整块不写 `[Index]` 也能被正确切开。
- 不知道的值写 `null`。
- `[Author]` 和 `[Title]` 每个块都必写（人写的块也一样）。
- 冒号用**半角** `:`，字段名照抄 `Index` / `Valid` / `Author` / `Title` / `GitBranch` / `GitCommitIds` / `Comments` 的拼写和大小写。
  （脚本对全角 `：` 和小写 `[index]` 是容忍的，但 `coop-lint.sh` 会报错要求改规范——免得别的工具看错。）
- **要演示块格式，把示例放进围栏代码块**（```` ``` ```` 或 `~~~`）。脚本会整段跳过围栏内容，示例就不会变成"幽灵块"；反过来，围栏没闭合会让后面的块全被跳过，`coop-lint.sh` 会报这个错。
- 不要在 `[Comments]` 正文里**顶格**写 `[字段]: …`——那会被当成新块的开始，把当前块从中间切开（缩进一级或放进围栏就没问题）。
- 写完跑 `./coop-lint.sh` 自检。

## 字段说明

| 字段 | 含义 |
| --- | --- |
| `[Index]` | 协作块编号。**agent 写的用纯数字，全 `agents-cooperation/` 全局唯一递增**（用 `get-index.sh --next` 取，别手算）；人写的可以省略，用 `<作者>-<序号>`（如 `ren-1`）。 |
| `[Valid]` | 这个块还有没有参考价值。`true` 才能参考；`false` 表示已作废，扫到直接跳过。 |
| `[Author]` | 谁写的。agent 写 `<工具>-agent`（`cursor-agent`、`opencode-agent`……）；人写自己的名字。**以 `agent` 结尾的算 AI，其余算人。** 一个块被后来者续写时，这里**保留最初写它的人**，续写的人在 `[Comments]` 里注明自己补了什么（每次提交的 `Coop-Author` trailer 才是"哪一次是谁做的"）。 |
| `[Title]` | 一句话说清这个块实现的是什么功能，后来者靠它匹配提示词。**写得能让人一眼判断相不相关。** |
| `[GitBranch]` | 实现所在的分支名；没提交就写 `null`。 |
| `[GitCommitIds]` | 实现这个块的 commit 短 sha 数组，**最新的写在最前面**；没提交写 `null`。 |
| `[Comments]` | 实现思路正文（见下）。 |

## 怎么写 [Comments]

写**思路**，不是贴代码：

- 这个功能要解决什么、拆成哪几块、每块落在哪个文件 / 类；
- 关键决策和取舍（为什么这么设计、当时否掉了哪些方案）；
- 有哪些约定（命名、数据结构、接口形状、边界处理）；
- 顺带记下遗留问题、TODO。

后来者靠它决定「要不要顺着你这条路走」。写法参考 [references/examples.md](references/examples.md)。

## 代码注释怎么写

注释是给**别人**看的——下一个 agent 和 review 的人。原则一句话：

> **别人只读注释，能不能明白你当时在想什么？**

- 写**为什么**（为什么这么选、有什么约束、哪里不能动），不写**是什么**；
- 有坑的地方必须留注释说明原因，否则后来者会顺手"优化"掉；
- TODO 要写清原因和该在什么条件下改；
- 中文，和工程其它注释保持一致；
- 代码里可以写一句"见协作块 #N"，**让代码和思路记录互相指路**，方便 review。

正反例见 [references/code-comments.md](references/code-comments.md)。

## 写代码之前：怎么高效找思路

1. `./get-index.sh --valid --folder <功能>` —— 只列还有效、且和本次相关的块；
   （不确定归哪个功能文件夹就先跑 `./get-index.sh --valid` 看全量。）
2. **`:false` 的块一律跳过**，连正文都别看。
3. `[Title]` 判断不相关的**别读正文**——既省 context，也免得被带偏。
4. 对相关块：`./coop-history.sh <编号>`，一次把它按提交演进的来龙去脉拉出来
   （它会读 `[GitCommitIds]` / `[GitBranch]` 去 `git show`；分支不在了也不影响，同一仓库里照样能看）。
5. 吃透之后再动手，**不要**绕开它自己重新设计一套。

完整演练见 [references/worked-example.md](references/worked-example.md)。

## 删模块 / 删功能（**只作废，不删除**）

三种情况会遇到：用户在提示词里说"把 X 去掉 / 不再需要"；实现过程中你判断某个模块该删；大范围重构让某个块描述的方案整体失效。

**这几件事不许自己决定，必须先把块找出来、报给用户、等同意。**

1. 抽出被删对象的名字（模块名 / 类名 / 文件名 / 功能名）。
2. 搜一遍（多换几个关键词：类名、文件名、功能名）：
   ```bash
   ./agents-cooperation/coop-find.sh <模块名>
   ```
3. **把清单摆给用户**，说清"要作废哪些块、不删块"：

   > 这次要删掉 `AudioCtx`（`sources/audio/AudioCtx.*`）。
   >
   > 下面这两个块的思路依赖它，将被置为 `[Valid]: false`（**不会删除**，只是不再作为参考）：
   >
   > | 块 | 标题 | 文件 |
   > | --- | --- | --- |
   > | `#3` | 播放控制（Player 单例 + 状态机） | `playback/播放控制实现思路.md` |
   > | `#7` | 音频后端切换 | `playback/播放后端实现思路.md` |
   >
   > 同意的话我就：① 把这两个块置 `false`，并各自在 `[Comments]` 末尾记一句"因删掉 AudioCtx 而废弃（opencode-agent，见 `<sha>`）"；② 提交消息里写明"作废块 #3 #7"。不同意的话告诉我保留哪一个。

4. **等用户明确同意**再改 `[Valid]`。作废是"人拍板"的事——就算你觉得毫无疑问，也要问。
5. 同意后：置 `false` + 在 `[Comments]` 里记一句废弃原因 + **块本身一行都不删**。
   - 同一个提交里既删代码又作废块时：trailer 只能带一个 `Coop-Block`（带"主"块），**在正文里写清还作废了哪些块**。
6. **只是删掉模块的一部分**（不是整个）→ 不一定要作废整块。给用户两个选项让他挑：
   - A. 整块作废（`[Valid]: false`）；
   - B. 保留块，只在 `[Comments]` 里标注"X 已被移除，其余部分仍有效"——**改 `[Comments]` 同样要用户同意**。
7. 搜完确实**没有**依赖它的块 → 也要在回复里说一句"没找到依赖它的协作块"，别默默删。

## 写完代码之后（一）：编译验证

**没编译过就不算写完。** "应该能编译"不算验证。

构建命令按顺序找：`agents-cooperation/_repo/build.md` → 从仓库现状推断（`CMakeLists.txt` / `package.json` / `Cargo.toml` …）→ 问用户 → 把确认下来的命令**写回 `_repo/build.md` 并提交**。

失败了就按五步走：**① 不许说"做完了"；② 用 `git stash` 分清是自己的锅还是环境的锅；③ 把命令 + 关键报错 + `文件:行` 报给用户；④ 能修就修到通过；⑤ 缺环境就明说"需要你装 X"，别把环境问题伪装成通过。**

输出格式和更多细节见 [references/build-verify.md](references/build-verify.md)。

## 写完代码之后（二）：自评打分 + 验收对照

跑一次，把材料摆齐（它不猜分数）：

```bash
./agents-cooperation/coop-review.sh        # 审当前未提交的改动（最常用）
./agents-cooperation/coop-review.sh 3      # 审块 #3 已记录的提交
```

然后按 [references/code-review.md](references/code-review.md) 打分，**四个维度各 10 分、总分 40**：

| 维度 | 看什么 |
| --- | --- |
| 可读性 | 注释是否讲"为什么"、命名、结构、魔法数、能不能指回协作块 |
| 最小实现与合理性 | 没做没要求的事、复用已有设施、改动面最小、复杂度匹配、无残留 |
| 协作风格一致性 | 命名 / 错误处理 / 格式化 / 注释语言 / 接口风格是否像本仓库本来的代码 |
| 安全性 | 外部输入校验、无硬编码密钥、危险操作有护栏、资源与生命周期、权限隐私 |

**必须先做"验收对照"**（对照块里 `[Comments]` 写的验收标准逐条打勾），再给分数表：

```
| 维度 | 得分 | 为什么给这个分 | 扣分点（指到 文件:行） |
| 可读性 | 8/10 | ... | -1 `Player.cpp:88` 的 1500 没说明 |
| ... | | | |
| **总分** | **34/40（B）** | | |
```

- 每条扣分**必须指到 `文件:行` 并贴那段代码**。
- 打分最后补一句 **"我最不放心的三点"**——这句比分数有价值。
- 提交那几条规矩（一个提交一个块 / 正文有思路 / 带 `Coop-*`）**不占分**，表后面附一行"过程要求"即可。
- 等级：**≥36 A 直接提交 ｜ 30–35 B 提交但把扣分项写进块 `[Comments]` ｜ 24–29 C 先别提交、先问用户（联系不上又必须交差 → 提交 + 扣分项写进块 + 正文写自评分数）｜ <24 D 先改再提交**。
- N/A 的检查项**不计分**，该维度按"实得 ÷ 可评满分"折算成 10 分制（别让整维 N/A 白拿满分）。

## 必须停下来问用户的情况

用户明确要求过：不清楚就问，不要臆想。下面这些一律先问，把选项和影响讲清楚，让用户一句话能拍板：

- 提示词和某个有效块的 `[Comments]` 思路**对不上** → 问用户参考哪一种。
  - 如果用户说"按我自己的来"，再追一句：**要不要改掉那个块的 `[Comments]`？** 用户同意就改，并在这次提交里写明「协作块 `<编号>` 的 `[Comments]` 被修改」。
- 类 / 模块的**职责**没说清（比如只说"写个 PlayList 类"，没说干嘛用）→ 问。
- **放哪个目录 / 文件**没说清 → 问。
- 两个有效块的思路**互相矛盾** → 问。
- 分不清该**复用已有块**还是**新开一个块** → 问。
- **新功能**：`agents-cooperation/` 里找不到对应的块 → **必须问用户要不要建块**，并把要写进块的信息（文件夹 / 标题 / 目标 / 边界 / 落点 / 约束 / 验收）一次问齐，**写进 `[Comments]` 之后才动代码**（见下节）。
- **要删模块 / 删功能** → 先 `coop-find.sh` 找出依赖它的块，把"将被置 `[Valid]: false`"的清单报给用户，**等同意**（见上节）。
- 要不要把某个块置 `[Valid]: false` → 问（作废一般由人拍板，agent 别擅自改）。
- 要**改**某个块的 `[Comments]` → 问（包括"只标注某部分已移除"这种小改）。

提问的写法和正反例见 [references/asking-users.md](references/asking-users.md)。

## 提交

**每次改完工作区文件都要提交**，没有例外。

> 唯一的前置停顿是**自评打分**：C 档先问用户、D 档先改（见 [references/code-review.md](references/code-review.md) 第五节）。
> 那是"提交之前"的暂停，不是"可以不提交"——顺序永远是 **暂停 → 问/改 → 提交**；
> 联系不上用户又必须交差时，**照常提交**，但把扣分项写进块 `[Comments]`、正文写一行自评结论。

commit 消息三条必须：

```
<标题：这一版实现了什么>

<正文：实现思路，和块里的 [Comments] 对齐>

Coop-Block: 3
Coop-Folder: playback
Coop-Author: opencode-agent
```

- 标题一句话说清"实现了什么"，别写"修改代码"这种废话。
- 正文写思路——后来者靠 `git log` 就能看懂，这是协作的关键，**不能省**。
- trailer 用来反查：`git log --grep='^Coop-Block: 3$'`、`git log --grep='^Coop-Author: cursor-agent$'`。
  **注意锚定 `^…$`**：不锚定的话 `Coop-Block: 3` 会把 `Coop-Block: 30` 也捞进来。
- 提交到本地当前分支；用户没要求就别 push、别乱开分支。用户要求开功能分支时，`git checkout -b <feature>` 并把分支名记进 `[GitBranch]`。
- 提交前跑一次 `./coop-lint.sh`。
- **提交前必须已经做完"编译验证 + 自评打分"**（流程第 11、12 步）。正文里带上结论一行，方便 review 的人：
  `编译：✅ cmake --build build -j8 ｜ 自评：34/40（B，遗留见块 #3）`
- 如果这次还**作废**了别的块，正文里写明"作废块 #3 #7"（trailer 只能带一个 `Coop-Block`）。
- **不用登记的改动**（纯文案 / 注释 / 格式 / 笔误 / 纯登记）不做上面这些，但正文要带一行 `Coop-Skip: <一句话原因>`——钩子两种都认。判断标准见本文开头「什么时候用」。

正反例见 [references/commit-messages.md](references/commit-messages.md)。

## 回写 commit

块的 `[GitCommitIds]` 里要能找到实现它的提交，**最新的写在最前面**。

commit 的 sha 只有提交之后才知道，所以默认两步：

1. 把代码 + 协作块一起 `git add`、提交；
2. 跑 `./coop-record.sh <编号>` —— 它自动把当前 `HEAD` 的短 sha 插到 `[GitCommitIds]` 最前面、把 `[GitBranch]` 填成当前分支，然后再提交一次。这次是登记用的，标题可以写 `docs(agents-cooperation): 回写协作块 <编号> 的提交记录`。

续写已有块时，`coop-record.sh` 会把新 sha 插到数组最前、保留老的——后来者会从头到尾看整条演进。

## 新功能 / 没有记录时（**先问用户，再建块，最后才写代码**）

`agents-cooperation/` 里找不到对应的块 → 说明这是**新功能**。这时**不许直接开写**，步骤是：

**① 先问用户要不要建块**，并一次把下面这些问齐（细节和正反例见 [references/asking-users.md](references/asking-users.md) 的「新功能」一节）：

| 要问的 | 直接决定块里的哪一项 |
| --- | --- |
| 功能文件夹叫什么 | 放在 `agents-cooperation/<功能>/` |
| 一句话标题 | `[Title]` |
| 目标 / 边界（做什么、不做什么） | `[Comments]` 的目标与范围 |
| 落在哪些目录 / 文件、涉及哪些模块 | `[Comments]` 的实现落点 |
| 必须沿用的约定、已知约束 | `[Comments]` 的约定与约束 |
| 怎么算做完（验收标准） | `[Comments]` 的验收 |

**别让用户重新想**——按工程现有习惯给出建议（文件夹名、标题、落点都先拟好），让用户点头或改一处即可。

**② 用户确认后建块，并把问到的信息写进 `[Comments]`：**

```bash
./agents-cooperation/coop-new-block.sh -f <功能> -t "<标题>"
```

它会建目录、建文档、追加一个排好编号的块骨架（`[Valid]: true`、`[GitBranch]` / `[GitCommitIds]` 先 `null`、`[Comments]` 留 TODO）。**只追加，不动已有内容。**

然后把 `[Comments]` 的 TODO 换成第 ① 步问到的共识（目标 / 边界 / 落点 / 约束 / 验收）。

**③ 到这步才动代码** → 提交（块和代码一起提交）→ `coop-record.sh` 回写。

> 如果用户明确说**"不用建块"**：先提醒一句"这样这次改动就没有协作块记录，后来者看不到思路"，用户仍坚持就照做；这种提交没有 `Coop-Block`，正文带一行 `Coop-Skip: 用户明确要求不建块` 就能过钩子（钩子两种都认）。**照旧要提交**。
> **别因为用户拒绝了块，就不提交代码。**

如果 `agents-cooperation/` 目录整个都不存在（第一次启用），先跑一次 `coop-init.sh`（见 [references/install.md](references/install.md)）。

## 人写的块 / 缺编号怎么补

约定：**人可以懒得写 `[Index]`**（但至少要写 `[Author]` 和 `[Title]`）。agent 扫到"没有 `[Index]`、且 `[Author]` 不以 `agent` 结尾"的块，就替它补编号：

- 格式 `<作者>-<序号>`，比如 `ren-1`、`ren-2`；
- 序号 = 该作者已用过的最大序号 + 1（一个都没有就从 1 开始）；
- `get-index.sh` 会把这些块和建议编号列出来，照着填即可；**改文件由 agent 动手**（脚本不偷偷改文档），并在提交消息里写明"补了谁的编号"。

人类块用的是 `ren-1` 这种字符串编号，**不参与**全局纯数字最大值的计算，所以不会占掉 agent 的编号空间。

## 脚本

工具都在 `agents-cooperation/` 下。**首次启用**先铺一次：

```bash
.cursor/skills/agents-cooperation/assets/coop-init.sh           # 铺目录 + 同步脚本
.cursor/skills/agents-cooperation/assets/coop-init.sh --hooks    # 只装 pre-commit / commit-msg
```

> `agents-cooperation/` 里的脚本是**副本**，正本是 skill 的 `assets/`。改了脚本要重跑 `coop-init.sh` 同步，
> 再用 `./agents-cooperation/coop-init.sh --check-sync` 对账；别直接改副本。

之后常用：

```bash
./agents-cooperation/get-index.sh [--next] [--valid] [--folder <功能>]   # 只读：编号 + 块清单
./agents-cooperation/coop-find.sh <关键词>                                # 只读：按关键词找块（删模块前必用）
./agents-cooperation/coop-find.sh --id <编号>                             # 只读：打印块原文（方便贴给用户）
./agents-cooperation/coop-history.sh <编号>                              # 只读：某块的提交演进
./agents-cooperation/coop-review.sh [<编号>] [--diff]                    # 只读：摆出自评材料
./agents-cooperation/coop-lint.sh [-q]                                   # 只读：格式校验
./agents-cooperation/coop-new-block.sh -f <功能> -t "<标题>" [-d <文档>] [-a <作者>]
./agents-cooperation/coop-record.sh <编号> [sha]                         # 回写分支 / commit
```

几条硬约定：

- **新建块一定用 `coop-new-block.sh`，不要自己写 `[Index]`。** 它取号时上锁、并把号登记进预留表，两个 agent 同时建块才不会撞。
- `get-index.sh --next` 只是**提示**（它是只读的，占不了号）。
- 装了钩子的仓库，提交时会自动跑 `coop-lint.sh` + 防删块 + 查 `Coop-Block` / `Coop-Skip`；合并、revert 提交本来就放行，只有"还没装钩子/初始化仓库"那种提交才用 `git commit --no-verify`。

**哪些步骤被固定成了脚本、哪些必须人判断**，见 [references/scripts.md](references/scripts.md)。
**把这套东西装到别的仓库**，见 [references/install.md](references/install.md)。

## 边界情况

- 一个功能改了很多轮 → 还是**同一个块**，`[GitCommitIds]` 越来越长；不要每轮新开块。
- 思路确实换了（推翻重做）→ 新开一个块，把旧块按用户意思置 `[Valid]: false`（记得先问）。
- **块只作废、不删除**：删了编号会被回收，`Coop-Block: N` 就会同时指向两批提交。
- 两个 agent 同时改了同一篇 md → 以仓库里最新的为准；有冲突就停下来问用户。
- 两个 agent 同时建块 → `coop-new-block.sh` 取号加了锁，同一工作区不会撞；跨工作区靠 `index-reserved.txt`（**要提交，别人 pull 后才有用**）。提交前仍建议重跑 `./coop-lint.sh`。
- 一个提交只服务一个块（trailer 只能写一个 `Coop-Block`）；两个块要改就拆成两次提交。
- `[Index]` 撞号 → 以先提交的为准，后到的换成 `get-index.sh` 给的下一个号，并在提交消息里说明。
- **仓库不是 git 仓库** → 先问用户（这套流程依赖 git：`Coop-*` trailer、`[GitCommitIds]`）。
- `agents-cooperation/` 不存在 → 跑 `coop-init.sh` 铺目录。
- 只读任务、纯问答 → 不走本流程。
- 拿不准"要不要登记" → **按"要登记"处理**（宁可多记一条），或者直接问用户。
- 不用登记的改动**也要提交**，正文带 `Coop-Skip: <原因>`；别用它掩盖真正的行为改动（`git log --grep='^Coop-Skip:'` 会被审计）。
- 要删模块 / 删功能 → 先 `coop-find.sh` 找出依赖它的块，报给用户、等同意后置 `[Valid]: false`（**不删块**）。
- 构建命令不知道 → 先看 `agents-cooperation/_repo/build.md`，没有就从仓库现状推断，还不行就问用户，**并把答案写回 `_repo/build.md`**。
- 编译过了但没法跑 → 在回复里明说"只验证到编译通过"，别让用户以为是"验证通过了"。
- 打分为 C / D 档 → 先别提交（C 先问用户、D 先改）；联系不上用户又必须交差时，提交并把扣分项写进块。
- 搬迁 / 安装到新仓库 → 见 [references/install.md](references/install.md)。

**更多会翻车的地方（都实测过）见 [references/pitfalls.md](references/pitfalls.md)。**

更多问答见 [references/faq.md](references/faq.md)。

## 参考文件

- [references/install.md](references/install.md)：**把这套流程装到另一个仓库**（复制什么、怎么注册、装钩子的顺序）
- [references/scripts.md](references/scripts.md)：哪些步骤被脚本固定了、每个脚本怎么用、编号租约怎么工作
- [references/code-review.md](references/code-review.md)：**代码验收与自评打分细则**（四个维度、评分表、等级与处置）
- [references/build-verify.md](references/build-verify.md)：**编译 / 构建验证**（命令从哪来、失败了怎么报）
- [references/pitfalls.md](references/pitfalls.md)：**会翻车的地方（实测过的坑）与规避办法**
- [references/examples.md](references/examples.md)：完整示例目录 + 各字段怎么填（含人类块、作废块、多轮续写）
- [references/worked-example.md](references/worked-example.md)：从用户提需求到提交回写的完整演练
- [references/code-comments.md](references/code-comments.md)：代码注释怎么写（正反例）
- [references/commit-messages.md](references/commit-messages.md)：提交消息模板与正反例
- [references/asking-users.md](references/asking-users.md)：什么时候问、怎么问（正反例）
- [references/faq.md](references/faq.md)：常见疑问与边界情况
