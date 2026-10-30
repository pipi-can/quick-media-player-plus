#!/usr/bin/env bash
# coop-init.sh —— 首次启用时，把协作目录和工具脚本一次性铺好（可选装 git 钩子）。
#
# 用法（在本 skill 的 assets/ 目录里执行）：
#   .cursor/skills/agents-cooperation/assets/coop-init.sh              # 铺协作目录 + 把脚本同步进来
#   .cursor/skills/agents-cooperation/assets/coop-init.sh --hooks      # 只装 git 钩子（不动脚本）
#   ... --force-hooks                                                  # 覆盖已有同名钩子（会先备份）
#
# 仓库里那份也能跑（它就是脚本副本）：
#   ./agents-cooperation/coop-init.sh              # 从 skill 的模板重新同步脚本（会报告改了哪几个）
#   ./agents-cooperation/coop-init.sh --check-sync # 只检查仓库副本和模板一致不一致，不改文件
#
# 行为：
#   - 在**当前仓库根目录**建出 agents-cooperation/，把同名脚本和解析库同步进去
#     （逐个报告 新建 / 更新 / 未变；`selftest.sh` 不复制，它属于 skill）；
#   - 写一个 agents-cooperation/.gitignore，忽略编号锁文件；
#   - --hooks：装 .git/hooks/pre-commit（跑 coop-lint + 防删块）和 commit-msg（查 Coop-Block / Coop-Skip）。
#     已存在同名钩子且不是我们装的 → 不覆盖，除非给 --force-hooks（会备份成 <名字>.bak-<时间>）。
#
# ⚠️ 脚本只有 skill 的 assets/ 是"模板"（正本）。agents-cooperation/ 里那份是**副本**：
#    要改脚本请改模板，然后跑一次 coop-init.sh 同步过去——别直接改副本，否则下次同步就被覆盖。
#
# 已经是初始化状态就只补缺的部分。

set -euo pipefail

force_hooks=0
want_hooks=0
want_sync=1
want_check=0
for a in "$@"; do
  case "$a" in
    --hooks)       want_hooks=1; want_sync=0 ;;
    --force-hooks) want_hooks=1; force_hooks=1; want_sync=0 ;;
    --check-sync)  want_check=1; want_sync=0 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
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

# 找"模板"（skill 的 assets/）在哪儿。从模板目录跑时它就在自己脚下；
# 从仓库那份跑时，按约定位置猜几个。猜不到就让调用方手动指定。
find_template_dir() {
  if [[ "$src" != "$target" && -f "$src/coop-lint.sh" ]]; then
    printf '%s\n' "$src"; return 0
  fi
  local c
  for c in "$root/.cursor/skills/agents-cooperation/assets" \
           "$root/.opencode/skills/agents-cooperation/assets" \
           "$HOME/.cursor/skills/agents-cooperation/assets" \
           "$HOME/.opencode/skills/agents-cooperation/assets"; do
    [[ -f "$c/coop-lint.sh" ]] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}

# ---- --check-sync：只对账，不改文件 ----
if (( want_check )); then
  tpl="$(find_template_dir)" || { echo "✗ 找不到模板目录（skill 的 assets/）。" >&2; exit 2; }
  printf '模板:     %s\n' "$tpl"
  printf '仓库副本: %s\n' "$target"
  drift=0
  for f in "$tpl"/*.sh; do
    name="$(basename "$f")"
    [[ "$name" == "selftest.sh" ]] && continue
    if [[ ! -f "$target/$name" ]]; then
      printf '  缺失: %s\n' "$name"; drift=1
    elif ! cmp -s "$f" "$target/$name"; then
      printf '  漂移: %s\n' "$name"; drift=1
    fi
  done
  for f in "$target"/*.sh; do
    [[ -e "$f" ]] || continue
    name="$(basename "$f")"
    [[ -f "$tpl/$name" ]] || printf '  （仓库里多出来的，模板里没有: %s）\n' "$name"
  done
  if (( drift )); then
    printf '✗ 仓库副本和模板不一致。跑一次 ./agents-cooperation/coop-init.sh 从模板重新同步。\n' >&2
    exit 1
  fi
  printf '✓ 仓库副本与模板一致。\n'
  exit 0
fi

# ---- 同步脚本（模板 → 仓库副本），逐个报告，不闷声覆盖 ----
if (( want_sync )); then
  if [[ "$src" == "$target" ]]; then
    printf '提示：这次是从仓库副本自己跑的，脚本没动。要跟模板对账用 --check-sync。\n'
  else
    mkdir -p "$target"
    declare -a created=() updated=() same=()
    for f in "$src"/*.sh; do
      name="$(basename "$f")"
      [[ "$name" == "selftest.sh" ]] && continue      # 回归测试脚本属于 skill，不进协作目录
      if [[ ! -f "$target/$name" ]]; then
        cp "$f" "$target/$name"; chmod +x "$target/$name"; created+=("$name")
      elif cmp -s "$f" "$target/$name"; then
        same+=("$name")
      else
        cp "$f" "$target/$name"; chmod +x "$target/$name"; updated+=("$name")
      fi
    done
    printf '协作目录: %s\n' "$target"
    if (( ${#created[@]} )); then printf '  新建 %d 个: %s\n' "${#created[@]}" "${created[*]}"; fi
    if (( ${#updated[@]} )); then printf '  更新 %d 个: %s\n' "${#updated[@]}" "${updated[*]}"; fi
    printf '  未变 %d 个\n' "${#same[@]}"
    if (( ${#updated[@]} )); then
      printf '\n⚠️ 有脚本被更新了——提交前先看一眼改了什么：\n'
      printf '    git -C "%s" diff -- agents-cooperation/\n' "$root"
      printf '  记住：模板（skill 的 assets/）才是正本；仓库那份是副本，别直接改它。\n'
    fi
  fi
fi

# ---- 铺目录（只在"同步"这一步做；--hooks 不碰这些）----
if (( want_sync )); then
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
fi

if (( want_hooks )); then
  if [[ ! -f "$target/coop-hook.sh" ]]; then
    printf '✗ 数据目录还没铺好（缺 %s/coop-hook.sh）。先跑一次不带参数的 coop-init.sh。\n' "$target" >&2
    exit 1
  fi
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
