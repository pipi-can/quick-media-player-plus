# 本仓库怎么构建 / 怎么测

> 这个文件**不是协作块**（`_` 开头的路径本来就不参与块解析），是给 agent 看的
> "写完代码怎么验证"。第一次确认完就把它填好并提交，之后不用每次重新猜。
> 改这里的命令前先问用户。
>
> 来源：本文件命令照抄 README.md 的「编译」一节（2026-10-30），改前先对一遍 README。

## 构建

- 命令：`./build.sh --build /home/Qt/6.5.3/gcc_64`
  （等价于依次跑 `cmake -S quick-media-player -B build -DCMAKE_PREFIX_PATH=/home/Qt/6.5.3/gcc_64`
  和 `cmake --build build`；构建目录固定为仓库根下的 `build/`）
- 增量构建（改几个文件时用它，比全量快）：`cmake --build build`
- 首次要跑的前置（装依赖 / source 环境）：仓库根执行一次 `chmod +x build.sh`
- 已知会失败的情况（环境缺失？）：**系统自带的 qmake 是 Qt 5**；不传 `-DCMAKE_PREFIX_PATH=/home/Qt/6.5.3/gcc_64`
  就会找不到 Qt 6。缺 Quick / Core5Compat 也不行。

## 测试

- 命令：无（本仓库目前没有自动化测试；`ctest` 之类没配）
- 有没有必须手动跑的用例：**有** → 构建后手工冒烟：播放 / 暂停 / 切歌 / 打开文件

## 运行 / 冒烟

- 命令：`./build.sh --run`（跑已经编好的 `build/appquick-media-player`）
- 先编再跑：`./build.sh --rebuild /home/Qt/6.5.3/gcc_64`

## 备注

- 全量构建太慢时，可以只编某个目标：`cmake --build build --target <目标名> -j8`
- 产物在 `build/`，已被根 `.gitignore` 忽略；**别提交构建产物**
