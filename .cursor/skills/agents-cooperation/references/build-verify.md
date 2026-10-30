# 编译 / 构建验证

**铁律：没编译过，就不算写完。**

一句话能说清它的地位：

> "应该能编译"、"看起来没问题"、"逻辑上是对的" —— **这些都不算验证**。
> 要么你把构建命令跑通并把结果贴出来，要么你明说"这次没编译，原因是 X"。

---

## 一、命令从哪来（按顺序找，别每次重新猜）

1. **`agents-cooperation/_repo/build.md`** —— 团队确认过的命令，**优先用它**。
   （这个文件不是协作块：`_` 开头的路径不参与块解析。`coop-init.sh` 会生成模板。）
2. **从仓库现状推断**（见下表）。
3. **推断不出来就问用户** —— 别瞎试一堆命令把环境搞脏。
4. **确认之后写回 `_repo/build.md` 并提交**，下次省事。改这里的命令前先问用户。

### 推断线索表

| 看到什么 | 大概率是这个 | 常用命令 |
| --- | --- | --- |
| `CMakeLists.txt` | CMake | `cmake -B build -DCMAKE_BUILD_TYPE=Debug && cmake --build build -j$(nproc)` |
| `Makefile` | make | `make -j$(nproc)` |
| `*.pro` / `*.pri` | qmake（Qt） | `qmake -o Makefile xxx.pro && make -j$(nproc)` |
| `meson.build` | meson | `meson setup build && meson compile -C build` |
| `package.json` | Node | `npm ci && npm run build`（看 `scripts`） |
| `Cargo.toml` | Rust | `cargo build` / `cargo check` |
| `go.mod` | Go | `go build ./...` |
| `pyproject.toml` / `setup.py` | Python | `python -m build` / `pip install -e .`（有 `pytest` 就跑测试） |
| `build.gradle*` | Gradle | `./gradlew build` |
| `BUILD` / `WORKSPACE` | Bazel | `bazel build //...` |
| `*.xcodeproj` | Xcode | `xcodebuild -scheme xxx build` |
| `Dockerfile` + `compose.yml` | 容器里构建 | `docker compose build` |

> 找不到任何线索 → **问用户**，并把答案写进 `_repo/build.md`。

---

## 二、失败怎么办（五步，别跳）

1. **不许说"做完了"。** 编译失败时，任务状态是"代码写完但没通过构建"。
2. **分清是谁的锅**：先看报错是不是指向你改的文件。
   ```bash
   git stash                 # 把你的改动收起来
   <构建命令>                 # 还是同样的错 → 环境/既有问题
   git stash pop
   ```
3. **把失败原因报给用户**，别只说"编译失败了"。至少要贴：
   - 跑的命令（原样一行）；
   - 关键报错（**贴前 10 行 / 最后一个 error，别贴 500 行**）；
   - 出错的文件和行号；
   - 你判断是自己的还是环境的，依据是什么。
4. **能修就修**（拼写、头文件、类型、漏 include、依赖声明），修完重跑，直到通过。
5. **修不了（缺环境）就明说**：`需要你装 xxx（缺 libasound2-dev）`，并把"环境缺失"和"代码问题"分开写——**别把环境问题伪装成代码通过**。

---

## 三、输出格式（放在回复里，和评分表一起）

```
## 编译验证
- 命令：`cmake -B build && cmake --build build -j8`
- 结果：✅ 通过    /    ❌ 失败
- 失败原因：（贴关键报错 + 文件:行）
- 是我的改动吗：是 / 不是（依据：git stash 后同样失败）
- 环境问题：缺 xxx，需要你装
```

---

## 四、几个现实问题

- **全量构建太慢**（Qt / 大 C++ 工程常见）→ 只编受影响的目标或模块，并在输出里写明"只编了 X 目标"。
- **实在没法编译**（缺工具链 / 缺硬件 / 只改了配置）→ 至少做**语法 / 类型层面的检查**，并把"做到哪一步"讲清楚：
  `clang++ -fsyntax-only xxx.cpp`、`tsc --noEmit`、`python -m py_compile`、`bash -n script.sh`。
- **有测试就跑测试**。测试命令同样记进 `_repo/build.md`。测试失败了也是"没做完"，照上面的五步处理。
- **编译通过 ≠ 功能正确**。要么跑测试 / 手工冒烟，要么在回复里明说"只验证到编译通过，没验证运行时行为"。
- **跑构建会改工作区**（`build/` 产物、生成文件）→ 别把它们提交进去；必要时先确认 `.gitignore` 有没有覆盖。

### 这条要求的"牙齿"有多大（说清楚，别自欺）

**钩子和脚本管不住编译。** `coop-lint.sh` 能查块格式，`pre-commit` 能查提交消息，但**没有任何机器检查能证明"我真的编译过"**——
一个 agent 完全可以写"✅ 通过"而根本没跑。所以这条靠的是三样东西，别当成硬保证：

1. **写在提交正文里**（`编译：✅ <命令>`，见下面第三节）→ 事后 `git log` 能翻账，撒谎会留下记录；
2. **`_repo/build.md` 里写死命令** → 后来者可以照着复现你那次验证，对不上就是有问题；
3. **用户抽查**。

> 所以**别把"编译通过"当成信任背书**。真正稳的验证是"有测试 + 测试命令进 `_repo/build.md` + 提交正文写了跑的是哪条命令"。
> 做不到时，**如实说做不到**比编一句"应该没问题"强——后者一旦被发现，整套协作记录的可信度都会打折。

---

## 五、反例（都是真实偷懒方式）

> "代码写好了，逻辑上应该没问题。"
> —— 没编译。也没说没编译。

> "编译有点报错，但都是老问题，不影响这次改动。"
> —— 没验证。而且"都是老问题"这个判断没有依据。

> "构建命令我试了 `make`，报了一堆错，应该是环境没配好。"
> —— 没贴报错、没跑 `git stash` 对照，用户无法判断该不该信。

> "编译通过了。"（其实只跑了一次全量构建，没看输出里有没有 `warning` 和 `error`）
> —— 退出码 0 但日志里有 error 是可能的（并行构建 + 局部失败）。

**正例长这样**：

> 编译验证：`cmake --build build -j8` ❌ 失败。
> `sources/player/Player.cpp:88: error: 'elapsed' was not declared in this scope`
> 是我这次漏改了一处（`git stash` 后同样命令是通过的），已补上，重跑 ✅ 通过；只编了目标是 `quick_media_player`。没跑真机。
