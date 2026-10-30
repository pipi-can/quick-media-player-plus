#!/usr/bin/env bash
# coop-init.sh —— 首次启用时，把协作目录和工具脚本一次性铺好（可选装 git 钩子）。
#
# 用法（在本 skill 的 assets/ 目录里执行）：
#   .cursor/skills/agents-cooperation/assets/coop-init.sh
#   .cursor/skills/agents-cooperation/assets/coop-init.sh --hooks     # 顺手装 pre-commit / commit-msg
#   .cursor/skills/agents-cooperation/assets/coop-init.sh --force-hooks  # 覆盖已有的同名钩子（会先备份）
#
# 行为：
#   - 在**当前仓库根目录**建出 agents-cooperation/，把同名脚本和解析库复制进去；
#   - 写一个 agents-cooperation/.gitignore，忽略编号锁文件；
#   - --hooks：装 .git/hooks/pre-commit（跑 coop-lint + 防删块）和 commit-msg（查 Coop-Block trailer）。
#     已存在同名钩子且不是我们装的 → 不覆盖，除非给 --force-hooks（会备份成 <名字>.bak-<时间>）。
#
# 已经是初始化状态就只补缺的部分。

set -euo pipefail

force_hooks=0
want_hooks=0
for a in "$@"; do
  case "$a" in
    --hooks)       want_hooks=1 ;;
    --force-hooks) want_hooks=1; force_hooks=1 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "未知参数: $a" >&2; exit 2 ;;
  esac
done

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  root="$(pwd)"
  echo "提示：当前不在 git 仓库里，只在 $root 下铺目录。整套流程依赖 git，建议先 git init。" >&2
fi

target="$root/agents-cooperation"

if [[ "$src" == "$target" ]]; then
  echo "脚本已经在 $target 里了，跳过复制。"
else
  mkdir -p "$target"
  copied=0
  for f in "$src"/*.sh; do
    base="$(basename "$f")"
    [[ "$base" == "selftest.sh" ]] && continue      # 回归测试脚本不进协作目录
    cp "$f" "$target/$base"
    chmod +x "$target/$base"
    copied=$(( copied + 1 ))
  done
  printf '已在 %s 建好协作目录，复制了 %d 个脚本。\n' "$target" "$copied"
fi

# 编号锁是临时文件，别提交
if [[ ! -f "$target/.gitignore" ]]; then
  printf '.index.lock\n.index.lock.d/\n' > "$target/.gitignore"
fi

# 仓库级说明（不是协作块——`_` 开头的路径脚本不解析）。
# 放"怎么构建 / 怎么测"，让 agent 之后不用每次重新猜。
if [[ ! -f "$target/_repo/build.md" ]]; then
  mkdir -p "$target/_repo"
  cat > "$target/_repo/build.md" <<'EOF'
# 本仓库怎么构建 / 怎么测

> 这个文件**不是协作块**（`_` 开头的路径本来就不参与块解析），是给 agent 看的
> "写完代码怎么验证"。第一次确认完就把它填好并提交，之后不用每次重新猜。
> 改这里的命令前先问用户。

## 构建

- 命令：
- 首次要跑的前置（装依赖 / source 环境）：
- 已知会失败的情况（环境缺失？）

## 测试

- 命令：
- 有没有必须手动跑的用例：

## 运行 / 冒烟

- 命令：

## 备注

- 全量构建太慢时，可以只编哪个目标：
EOF
fi

ls -1 "$target"

if (( want_hooks )); then
  hookdir="$(git -C "$root" rev-parse --git-path hooks 2>/dev/null || echo "$root/.git/hooks")"
  mkdir -p "$hookdir"
  marker="由 agents-cooperation/coop-init.sh 安装"
  stamp="$(date '+%Y%m%d%H%M%S')"
  installed=0
  skipped=0
  for name in pre-commit commit-msg; do
    dst="$hookdir/$name"
    stage_args="pre-commit"
    extra='""'
    [[ "$name" == "commit-msg" ]] && { stage_args="commit-msg"; extra='"$1"'; }
    body="#!/bin/sh
# $marker
root=\"\$(git rev-parse --show-toplevel 2>/dev/null)\" || exit 0
[ -f \"\$root/agents-cooperation/coop-hook.sh\" ] || exit 0
exec bash \"\$root/agents-cooperation/coop-hook.sh\" $stage_args $extra
"
    if [[ -f "$dst" ]] && ! grep -q "$marker" "$dst" && (( ! force_hooks )); then
      printf '跳过 %s：已存在别的钩子（要覆盖就加 --force-hooks）\n' "$dst" >&2
      skipped=$(( skipped + 1 ))
      continue
    fi
    if [[ -f "$dst" ]] && ! grep -q "$marker" "$dst"; then
      cp "$dst" "$dst.bak-$stamp"
      printf '已备份原钩子到 %s\n' "$dst.bak-$stamp" >&2
    fi
    printf '%s' "$body" > "$dst"
    chmod +x "$dst"
    installed=$(( installed + 1 ))
  done
  printf '装了 %d 个 git 钩子（跳过 %d 个）。\n' "$installed" "$skipped"
  printf '注意：钩子要求提交消息里要么有 Coop-Block、要么有 Coop-Skip；合并提交本来就放行，\n'
  printf '只有"初始化仓库、还没有协作目录"那种提交才用 git commit --no-verify。\n'
fi

printf '\n下一步：\n'
printf '  1. 把 agents-cooperation/ 提交进 git（别 ignore 掉；index-reserved.txt 要一起提交）\n'
printf '  2. 用 ./agents-cooperation/coop-new-block.sh -f <功能> -t "<标题>" 建第一个块\n'
