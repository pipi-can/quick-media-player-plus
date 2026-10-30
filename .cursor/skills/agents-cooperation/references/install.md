# 把这套流程装到一个仓库里

这套东西**跟语言、框架无关**（不依赖 C++/QML/Node……），只要满足两条：仓库是 **git** 仓库，agent 能读仓库里的文件。下面说怎么搬到新仓库。

## 一共三样东西

| 东西 | 是什么 | 放哪 |
| --- | --- | --- |
| **规则**（rule） | 短，常驻：动工作区文件前先用"三问"判断要不要登记 | `.cursor/rules/agents-cooperation.mdc` |
| **技能**（skill） | 长，详细步骤 + 参考文档 + 脚本（**涉及功能 / 接口 / 取舍**时用） | `.cursor/skills/agents-cooperation/`（含 `SKILL.md` / `assets/` / `references/`） |
| **数据目录** | 协作块本身 + 脚本 + 构建说明 | `agents-cooperation/`（仓库根目录，随仓库提交） |

前两样是"安装件"，复制一次；第三样由 `coop-init.sh` 在目标仓库里生成。

## 步骤

### 1. 复制规则和技能

```
你的仓库/
└── .cursor/
    ├── rules/agents-cooperation.mdc
    └── skills/agents-cooperation/
        ├── SKILL.md
        ├── assets/        # 脚本（含 selftest.sh）
        └── references/    # 参考文档
```

### 2. 注册（opencode）

在仓库根目录的 `opencode.json` 里，把这两条并在已有配置上（别覆盖原来的）：

```json
{
  "instructions": [".cursor/rules/*.mdc"],
  "skills": [".cursor/skills"]
}
```

- `instructions` 让 rule 常驻生效；
- `skills` 让 `agents-cooperation` 这个 skill 能被加载。

### 3. 注册（Cursor）

Cursor 直接读 `.cursor/rules/*.mdc` 和 `.cursor/skills/<名字>/SKILL.md`，不用额外配置。`agents-cooperation.mdc` 里 `alwaysApply: true`，所以只要动文件就会带上。

### 4. 用别的 agent（Claude Code / Codex / 自研）

这些工具没有 `.cursor` 的概念，做法是：

- 把 **rule 的要点**贴进该工具的常驻指令文件（`AGENTS.md` / `CLAUDE.md` 之类）；
- 把 **`SKILL.md`** 作为可加载的文档放进去（路径随便，但要在指令里写明"动文件前先读它"）。

关键不是文件放哪，而是让 agent 知道这一句：**动工作区文件前，先到 `agents-cooperation/` 找同功能的协作块。**

### 5. 建数据目录

```bash
.cursor/skills/agents-cooperation/assets/coop-init.sh
```

它会在仓库根目录建 `agents-cooperation/`，把脚本复制进去，并写一个 `.gitignore`（忽略编号锁文件）。

**先别急着装钩子**——第一次提交（把 rule / skill / 数据目录加进来）还没有 `Coop-Block` trailer，会被钩子拦。所以顺序是：

### 6. 提交安装件（这一次放行）

```bash
git add .
git commit -m "chore: 引入 agents-cooperation 协作流程"
# 如果已经装了钩子：这是"还没有协作块"的提交，加 --no-verify
```

### 7. 装钩子（可选，但强烈建议）

```bash
.cursor/skills/agents-cooperation/assets/coop-init.sh --hooks
```

装好后每次提交会自动：

- 跑 `coop-lint.sh`（块格式有问题就不让提交）；
- 检查有没有**删掉**块（纯数字编号和 `ren-1` 这种人类编号都覆盖）；
- 检查提交消息里**要么有 `Coop-Block`、要么有 `Coop-Skip`**。

合并 / revert 提交钩子本来就放行。只有"初始化仓库、还没有协作目录"这种提交才需要 `git commit --no-verify`。

> 钩子装在 `.git/hooks/`，**每个克隆都要装一次**（`.git/hooks` 不进版本库）。它是瘦壳子，真正的逻辑在仓库里的 `coop-hook.sh`，所以改逻辑只要改仓库文件。

### 8. 验证

```bash
.cursor/skills/agents-cooperation/assets/selftest.sh     # 全套回归，最后一行「失败 0」才算装好
./agents-cooperation/get-index.sh                       # 应该输出"下一个可用编号: 1"
```

### 9. 填一下"怎么构建"

```bash
./agents-cooperation/coop-init.sh   # 会生成 agents-cooperation/_repo/build.md
$EDITOR agents-cooperation/_repo/build.md    # 把构建 / 测试命令填上，提交
```

这个文件**不是协作块**（`_` 开头的路径脚本不解析），是给 agent 做"编译验证"用的。
填一次，之后每个 agent 都不用重新猜构建命令；推断出来的命令也往这里写。
详见 [build-verify.md](build-verify.md)。

### 10. 第一次真跑一遍（别跳过）

装完先**真的走一次流程**，比读十遍文档管用。最简单的第一件事：**把"搭这套协作流程"本身登记成块 1**。

```bash
./agents-cooperation/coop-new-block.sh -f infra -t "引入 agents-cooperation 协作流程"
$EDITOR agents-cooperation/infra/*.md          # 写上目标 / 落点 / 约定 / 验收
git add -A && git commit -m "chore(infra): 引入协作流程

Coop-Block: 1
Coop-Folder: infra
Coop-Author: <你的名字>"
./agents-cooperation/coop-record.sh 1
git add -A && git commit -m "docs(agents-cooperation): 回写块 1 的提交记录

Coop-Skip: 纯登记操作"
```

走通一遍，你就知道这套东西在这个仓库里**顺不顺手**——不顺的地方现在就改，别等用了三个月才发现。

## 装完之后

- **功能文件夹名按新仓库自己的习惯来**，别照抄 `playback` / `theme`。第一次建块用：

  ```bash
  ./agents-cooperation/coop-new-block.sh -f <功能> -t "<标题>"
  ```

- `SKILL.md` 和 `references/` 里的举例还是原来那个 Qt 工程的，**不影响使用**（都标了"只是举例"）。想改成本仓库的例子更好。
- `index-reserved.txt` 是编号预留表，**要提交**（别人 pull 之后才不会撞号）。

## 升级

这套东西的"代码"就是 `.cursor/skills/agents-cooperation/`。目标仓库里更新就直接覆盖这个目录（`agents-cooperation/` 里的脚本用 `coop-init.sh` 重新复制一遍即可，块和预留表不会被动）。

改完脚本**一定先跑** `selftest.sh`。
