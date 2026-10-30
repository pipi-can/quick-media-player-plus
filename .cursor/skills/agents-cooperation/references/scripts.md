# 脚本：哪些步骤被固定了、怎么用

流程里凡是**机器能可靠判断**的步骤，都做成了脚本；剩下的是**必须人 / agent 判断**的，脚本不碰。

脚本都在 `agents-cooperation/_tools/` 下（首次用 `coop-init.sh` 铺好）。

> ⚠️ 这些是**副本**：正本在 skill 的 `assets/` 里。改脚本请改正本，再用 `coop-init.sh` 同步；
> `./agents-cooperation/_tools/coop-init.sh --check-sync` 可以随时对账。

## 总览

| # | 流程步骤 | 能否固定 | 用什么 |
| --- | --- | --- | --- |
| 1 | 从提示词定位功能文件夹 | ✗ 判断 | 定不准时用 `coop-find.sh <关键词>` 搜 |
| 2 | 取下一个可用编号 | ✓ | `get-index.sh --next`（提示用；**建块一定走 `coop-new-block.sh`**） |
| 3 | 列候选块（只列有效 / 只列某功能） | ✓ | `get-index.sh --valid --folder <功能>` |
| 4 | 拉某个块的完整演进（提交、改动文件） | ✓ | `coop-history.sh <编号>` |
| 5 | 判断已有思路是否还适用 | ✗ 判断 | — |
| 6 | 决定要不要问用户、问什么 | ✗ 判断 | — |
| 6b | **要删模块时找出依赖它的块** | ✓ | `coop-find.sh <模块名>`（**问不问用户是判断**） |
| 7 | 写代码、写注释 | ✗ 人 / agent | — |
| 7b | 编译 / 构建验证 | 半 ✓ | 命令记在 `_repo/build.md`；跑和判定由 agent 做 |
| 7c | 摆出自评打分要用的材料 | ✓ | `coop-review.sh [<编号>]` |
| 7d | 打四个维度的分 | ✗ 判断 | 按 [code-review.md](code-review.md) |
| 8 | 新建协作块（取号 + 登记预留 + 字段骨架） | ✓ | `coop-new-block.sh`（加锁，防并发撞号） |
| 9 | 写提交消息 | ✗ 判断 | 模板见 [commit-messages.md](commit-messages.md)；**带没带 trailer 由钩子兜** |
| 10 | 回写 `[GitBranch]` / `[GitCommitIds]` | ✓ | `coop-record.sh <编号>` |
| — | 校验所有块格式 | ✓ | `coop-lint.sh` |
| — | 校验**文件语法**（脚本 / Markdown / frontmatter / 链接） | ✓ | `coop-docs-check.sh` |
| — | 提交时自动跑校验 / 防删块 / 查 trailer / 体检 | ✓ | `coop-init.sh --hooks` 装的钩子 |
| — | 铺协作目录和脚本 | ✓ | `coop-init.sh`（`--check-sync` 对账） |
| — | 脚本本身的回归测试 | ✓ | `selftest.sh`（断言条数以它自己的输出为准） |
| — | 给人类块补编号 | 半 ✓ | `get-index.sh` 出建议值，改文件由 agent 做 |

**为什么"改文件"的事要交给 agent、脚本只给建议？** 脚本默默改文档，出了问题没人知道是谁改的；agent 动手改，这次改动会出现在提交里，可追溯。同理：**分数只能由 agent 打**，脚本只负责把 diff 摆齐——打分掺进脚本，就变成"机器给自己发奖状"了。

**为什么不做 `coop-commit.sh` 自动提交？** 提交消息的价值全在"人写的思路"上，机器凑不出来；而且自动 `git add` 容易把临时文件一起提交。提交这一步保持手工，但**校验**用钩子自动化。

## 哪些文件不是协作块

**`_` 开头的文件 / 目录**：脚本不解析、`get-index.sh` 不统计、`coop-lint.sh` 不检查。用来放仓库级说明，目前约定：

| 路径 | 放什么 |
| --- | --- |
| `_repo/build.md` | 本仓库怎么构建 / 怎么测（编译验证用）。`coop-init.sh` 会生成模板 |

## 编号租约：防两个 agent 撞号

编号是"读最大值 +1"算出来的，天然有竞态。三层防护：

1. **同一工作区并发** → `coop-new-block.sh` 取号时上锁（`flock`，没有就退化成 mkdir 自旋），"算号 + 写块"原子完成。所以**建块一定用 `coop-new-block.sh`，不要自己写 `[Index]`**。
2. **跨工作区 / 跨分支 / 跨克隆** → 取号后往 `index-reserved.txt` 登记一行。`get-index.sh --next` 会把预留号也算进最大值。
   ⚠️ **这个文件要提交，别人 `pull` 之后才看得到**；没提交就等于没预留。
   （`coop-lint.sh` 会在"有块但没有 `index-reserved.txt`"时**警告**一句，提醒这套保护已经失效。）
3. **兜底** → `coop-lint.sh` 发现两个块同一个编号直接报错。

`get-index.sh --next` 只是**提示**（它是只读的，不可能"占号"）。真要占号就得建块，或者让用户/agent 自己把号码写进 `index-reserved.txt`。

## 命令速查

```bash
# 一次性铺好协作目录，并把脚本同步进 _tools/（--hooks 只装 git 钩子，不碰脚本）
.cursor/skills/agents-cooperation/assets/coop-init.sh
.cursor/skills/agents-cooperation/assets/coop-init.sh --hooks

# 对账：仓库里的脚本副本跟模板是否一致（改过脚本之后跑）
./agents-cooperation/_tools/coop-init.sh --check-sync

# 脚本自己的回归测试（改完脚本先跑）
.cursor/skills/agents-cooperation/assets/selftest.sh

cd agents-cooperation

./_tools/get-index.sh                     # 完整报告
./_tools/get-index.sh --next              # 只要下一个编号（提示用）
./_tools/get-index.sh --valid             # 只列还有效的块
./_tools/get-index.sh --folder playback   # 只看某个功能

./_tools/coop-history.sh 3                # 看某个块的来龙去脉

./_tools/coop-find.sh Player              # 按关键词找块（删模块前必用）
./_tools/coop-find.sh --id 3              # 打印块原文（方便贴给用户看）
./_tools/coop-find.sh --list              # 列出所有块

./_tools/coop-review.sh                   # 摆出自评材料：当前未提交的改动
./_tools/coop-review.sh 3                 # 摆出块 #3 已记录的提交
./_tools/coop-review.sh --diff            # 连完整 diff 一起打印

./_tools/coop-new-block.sh -f playback -t "音量弹窗实现思路" -a opencode-agent

./_tools/coop-record.sh 3                 # 回写提交（sha 默认取 HEAD）
./_tools/coop-record.sh 3 d9fe736

./_tools/coop-lint.sh                    # 校验块格式
./_tools/coop-lint.sh -q                 # 只说问题

./_tools/coop-docs-check.sh              # 体检文件语法（脚本 + Markdown + frontmatter + 链接）
./_tools/coop-docs-check.sh --all        # 连别的 skill 一起查
./_tools/coop-docs-check.sh <路径>…      # 只查指定文件 / 目录

./_tools/coop-hook.sh pre-commit         # 钩子实际跑的东西（一般不用手调）
```

## 各脚本行为

### `get-index.sh`（只读）

- 无参数：输出「下一个可用编号（含预留）+ 缺编号的人类块及建议编号 + 现有块一览」。
- `--next`：只打印下一个可用编号。
- `--valid`：只列 `[Valid]: true` 的块——**扫描时先用它，无关的块不看**。
- `--folder <功能>`：只列该功能文件夹下的块。可以和 `--valid` 连用。
- **不改任何文件**（所以它不能替你占号）。

### `coop-history.sh <编号>`（只读）

- 打印块的 Title / Author / 有效 / 分支 / 提交数组；
- 按数组（最新在最前）逐个 `git show`：标题、正文（含 `Coop-*` trailer）、改动的文件；
- 数组是 `null` 时，退回按 `git log --grep='^Coop-Block: <编号>$'` 反查（锚定，免得 `3` 把 `30` 捞进来）；
- sha 找不到（被 rebase 掉了）会提示重找，不会崩。

### `coop-find.sh`（只读）—— 删模块前必用

- `coop-find.sh <关键词> [关键词2 ...]`：在块文档正文里搜（**围栏代码块里的示例不搜、`_` 开头的说明文件不搜、不区分大小写**），命中就按块分组列出「块编号 / 标题 / 文件:行 / 那一行」。
- `coop-find.sh --id <编号>`：把一个块的原文原样打出来（贴给用户看很方便）。
- `coop-find.sh --list`：列所有块。
- **搜不到时退出码 1**，方便判断"确实没有依赖"——但别搜一次就下结论，换个关键词（类名 / 文件名 / 功能名）再搜。

### `coop-review.sh [<编号>] [--diff]`（只读）

- 不给编号：审**当前未提交的改动**（`git diff HEAD --stat` + 未跟踪文件 + 改动行数），这是"提交前自评"最常用的形态。
- 给编号：审该块 `[GitCommitIds]` 里已记录的提交（从旧到新）。
- `--diff`：连完整 diff 一起打印（默认只给统计，省 context）。
- **它不猜分数**——只把材料摆齐，然后打印一张空的评分表骨架 + 等级尺子。分数由 agent 按 [code-review.md](code-review.md) 打。

### `coop-new-block.sh`（写）

```
./_tools/coop-new-block.sh -f <功能> -t <标题> [-d <文档名>] [-a <作者>]
```

- 功能文件夹、文档不存在就创建（新文档带一级标题）；
- 在文档末尾追加一个块：`[Valid]: true`、`[Author]` 默认 `$COOP_AUTHOR`（再不然 `opencode-agent`）、`[GitBranch]` / `[GitCommitIds]` 先 `null`、`[Comments]` 留 TODO；
- **取号在锁里做**，并按作者配号：agent（以 `agent` 结尾）拿纯数字，人拿 `<作者>-<序号>`（如 `ren-1`）；
- agent 块会把号登记进 `index-reserved.txt`；
- 只追加，不动已有内容。

### `coop-record.sh <编号> [sha]`（写）

- `sha` 默认取当前 `HEAD`；
- 把 sha 插到该块 `[GitCommitIds]` **最前面**（已在数组里就不重复插）；
- `[GitBranch]` 填当前分支名；
- **编号撞号时直接拒绝**，让你先跑 `coop-lint.sh` 修掉；
- 只改这个块里的这两行，别的块和正文一律不动。

### `coop-lint.sh [-q]`（只读）

- **错误**（退出码 1）：必填字段缺失、`[Valid]` 取值不对、AI 块没有纯数字编号、纯数字编号撞号、人类编号形状不对、`[GitBranch]` 含空格、`[GitCommitIds]` 不是合法短 sha 数组、文档没放在功能文件夹下、围栏代码块没闭合、字段名大小写不对、用了全角冒号、还留着 `coop-new-block.sh` 的 TODO 占位符。
- **警告**（不影响退出码）：字段被缩进了、同一功能里 `[Title]` 重名、`.md` 里一个块都没解析到、`[GitBranch]` 是 `HEAD`（detached HEAD）。

### `coop-docs-check.sh [-q] [--all] [<路径>…]`（只读）

体检**文件语法**（不管块格式，那个归 `coop-lint.sh`）。查 6 类，每条都定位到 `文件:行`：

1. `*.sh` 的 `bash -n` 语法；
2. Markdown 代码围栏是否闭合（按字符和长度，```` ``` ```` 与 `~~~` 不混用；**围栏最多缩进 3 格**，
   缩进 4 格是"缩进代码块"，里面的三连反引号只是字面文本）；
3. 行内反引号按 CommonMark 配对（**允许跨行**：长度 N 的串要由下一个长度恰好为 N 的串闭合）；
4. 表格每行列数和表头一致；
5. 内部链接指向的文件存在；
6. frontmatter：`SKILL.md` 要 `name` + `description`，`.mdc` 要 `description`，值要符合 YAML 明文标量规则。

第 3～5 项**只看正文行**：围栏内和缩进代码块里的内容算代码——里面的反引号、`|`、`[x](y)` 都是
举例用的字面文本，拿来判错就是冤枉人。

- 退出码：0 没问题 / 1 有问题 / 2 用法错；
- **默认只查"我们自己的"文件**：`agents-cooperation/`、`.cursor/rules/agents-cooperation.mdc`、本 skill 的 `SKILL.md` / `references/` / `assets/`。
  这是刻意的——连 `.cursor/skills/` 下**别的 skill** 一起查，别人的文档不合规就会挡住本仓库的提交（误伤）。要全查加 `--all`。
- **只做结构检查**：它不证明"文档意思写对了"，也不等于 shellcheck（未定义变量、误引用这类查不出来）。绿了只代表"没犯这些低级错"。

### `coop-hook.sh`（给 git 钩子用）

- `coop-hook.sh pre-commit`：跑 lint + 检查有没有**删掉**块（约定：块只作废不删除，删了编号会被回收、反查串台）+ 跑 `coop-docs-check.sh`（文件语法体检）；
- `coop-hook.sh commit-msg <消息文件>`：检查提交消息里**要么有 `Coop-Block: <编号>`、要么有 `Coop-Skip: <原因>`**（合并 / revert / fixup / squash 提交放行）。
- 由 `coop-init.sh --hooks` 装的两个瘦壳子调用；也可以手工跑。

### `coop-init.sh [--hooks] [--force-hooks] [--check-sync]`（写）

在本仓库根目录建 `agents-cooperation/`，把脚本**同步**进来（逐个报告 新建 / 更新 / 未变）、写 `.gitignore`（忽略编号锁）、生成 `_repo/build.md` 模板。

- `--hooks`：**只**装 `pre-commit` / `commit-msg`（要求数据目录已经铺好）；已有别的同名钩子会跳过，`--force-hooks` 覆盖并备份；
- `--check-sync`：**只对账不改文件**，比较仓库里的脚本副本和模板是否一致，有漂移退 1。

> **模板 vs 副本**：模板是 `.cursor/skills/agents-cooperation/assets/`（正本），仓库里的 `agents-cooperation/_tools/*.sh` 是副本。
> 改脚本只改模板，然后跑一次 `coop-init.sh` 同步——别直接改副本，下次同步会被覆盖。
> 同步覆盖前会先看：副本有**未提交**的改动就跳过不覆盖（退 1），已提交的才允许换掉。

### `selftest.sh`（只读工作区）

在临时目录里搭假仓库，把脚本的每条行为都验一遍（编号、预留、lint 各类错误与警告、围栏、字段读写、CRLF、多块文档、过滤、回写、历史、钩子、`--hooks` 真提交、`_` 说明文件、`coop-find`、`coop-review`、`Coop-Skip` 放行……）。
**改完脚本先跑它**，最后一行会打印「通过 N，失败 M」——N 是多少不重要，**失败必须是 0**。不碰你的工作区。

### `_coop-common.sh`

各脚本共用的解析库（块边界、编号、预留、锁、sha 解析、"跳过围栏"的行扫描、"忽略 `_` 开头路径"）。**不用管它，也别单独跑。**

其中**读写块字段**的函数是唯一实现，别的脚本一律调它们、**别再手写 awk**：

| 函数 | 干什么 |
| --- | --- |
| `coop_get_field <文件> <编号> <字段>` | 读某个块里某个字段的值（围栏感知、CRLF 安全、字段名大小写不敏感） |
| `coop_set_field <文件> <编号> <字段> <值>` | 写某个块里某个字段：有就替换、没有就**按字段顺序插入**；围栏里的同名行不动；CRLF 文件保持 CRLF |
| `coop_find_block_file <编号>` | 定位编号所在的**唯一**文件；找不到 / 撞号都报错（统一做了 `_` 过滤） |
| `coop_block_exists_in <文件> <编号>` | 判断某个文件里有没有这个编号的块 |

> 为什么强调"唯一实现"：曾经 `coop-record.sh` 手写了第二套 awk，结果"块里缺字段""CRLF 文件"两种情况都**静默不写**、还打印"已回写成功"。
> 详见 [pitfalls.md](pitfalls.md) 的 A5。
