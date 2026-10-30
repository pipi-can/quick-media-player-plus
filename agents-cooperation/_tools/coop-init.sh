#!/usr/bin/env bash
# coop-init.sh —— 首次启用时，把协作目录和工具脚本一次性铺好（可选装 git 钩子）。
#
# 用法（在本 skill 的 assets/ 目录里执行）：
#   .cursor/skills/agents-cooperation/assets/coop-init.sh              # 铺协作目录 + 把脚本同步进 _tools/
#   .cursor/skills/agents-cooperation/assets/coop-init.sh --hooks      # 只装 git 钩子（不动脚本）
#   ... --force-hooks                                                  # 覆盖已有同名钩子（会先备份）
#
# 仓库里那份也能跑（它就是脚本副本）：
#   ./agents-cooperation/_tools/coop-init.sh              # 从 skill 的模板重新同步脚本（会报告改了哪几个）
#   ./agents-cooperation/_tools/coop-init.sh --check-sync # 只检查仓库副本和模板一致不一致，不改文件
#
# 目录长这样：
#   agents-cooperation/            协作目录根：块文档 + index-reserved.txt + .gitignore
#   agents-cooperation/_tools/     工具脚本（副本；正本是 skill 的 assets/）
#   agents-cooperation/_repo/      仓库级说明（怎么构建 / 怎么测）
#
# 行为：
#   - 在**当前仓库根目录**建出 agents-cooperation/，把脚本同步进它的 _tools/
#     （逐个报告 新建 / 更新 / 未变；`selftest.sh` 不复制，它属于 skill）；
#   - 旧布局（脚本直接躺在 agents-cooperation/ 根下）自动搬进 _tools/；旧那份若有
#     **git 里还没有备份**的内容，就不搬、不覆盖，明确报错并退 1（把改动搞丢这种事不做）；
#   - 已经装过钩子、但壳子还指着旧路径的，自动改写并提示——否则钩子找不到脚本会
#     `exit 0` **静默失效**，门禁悄悄关掉比报错坏得多；
#   - 写 agents-cooperation/.gitignore，忽略编号锁文件；
#   - --hooks：装 .git/hooks/pre-commit（跑 coop-lint + 防删块 + 语法体检）和
#     commit-msg（查 Coop-Block / Coop-Skip）。已存在同名钩子且不是我们装的 → 不覆盖，
#     除非给 --force-hooks（会备份成 <名字>.bak-<时间>）。
#
# ⚠️ 脚本只有 skill 的 assets/ 是"模板"（正本）。agents-cooperation/_tools/ 里那份是**副本**：
#    要改脚本请改模板，然后跑一次 coop-init.sh 同步过去——别直接改副本，否则下次同步就被覆盖。
#    同步时若副本的内容**git 里还没有备份**（真手改、没提交），会跳过不覆盖并退 1；
#    已经提交 / `git add` 过的改动允许覆盖——对象库里留着，`git cat-file` 捞得回来。
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
    -h|--help) sed -n '2,34p' "$0"; exit 0 ;;
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

target="$root/agents-cooperation"     # 协作目录根
tools_dir="$target/_tools"            # 工具脚本住这儿（副本）

hook_marker="由 agents-cooperation/coop-init.sh 安装"
hook_names="pre-commit commit-msg"

hookdir() { git -C "$root" rev-parse --git-path hooks 2>/dev/null || printf '%s\n' "$root/.git/hooks"; }

# 钩子壳子的内容：只负责找仓库根、转给 coop-hook.sh。逻辑跟着仓库走，改了脚本所有克隆都生效。
hook_body() {
  local stage_args='pre-commit' extra='""'
  [[ "$1" == "commit-msg" ]] && { stage_args='commit-msg'; extra='"$1"'; }
  printf '#!/bin/sh\n# %s\nroot="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0\n[ -f "$root/agents-cooperation/_tools/coop-hook.sh" ] || exit 0\nexec bash "$root/agents-cooperation/_tools/coop-hook.sh" %s %s\n' \
    "$hook_marker" "$stage_args" "$extra"
}

# 找"模板"（skill 的 assets/）在哪儿。从模板目录跑时它就在自己脚下；
# 从仓库那份（_tools/）跑时，按约定位置猜几个。猜不到就让调用方手动指定。
find_template_dir() {
  if [[ "$src" != "$target" && "$src" != "$tools_dir" && -f "$src/coop-lint.sh" ]]; then
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

# 覆盖副本前先确认"这份内容 git 里有备份"——没有就别覆盖，覆盖了就真找不回来了。
# 判据是**内容级**的：把副本算成 blob，问对象库里有没有这个对象。已提交的、已 `git add` 的、
# 乃至"内容碰巧和历史上某个版本相同"的都算有备份（`git cat-file blob <sha>` 随时捞得回来）。
# 这样"旧布局搬过来的副本"（内容保存在老路径的提交里）不会冤成手改——第一版判据（看路径的
# 跟踪状态）就冤过一次：搬家后新路径未跟踪，全被当成手改，同步整个被挡住。
content_is_recoverable() {
  local p="$1" blob
  git -C "$root" rev-parse --git-dir >/dev/null 2>&1 || return 0   # 不在 git 仓库里：没有护栏可言
  blob="$(git -C "$root" hash-object -- "$p" 2>/dev/null)" || return 0
  git -C "$root" cat-file -e "$blob" 2>/dev/null
}

# ---- --check-sync：只对账，不改文件 ----
if (( want_check )); then
  tpl="$(find_template_dir)" || { echo "✗ 找不到模板目录（skill 的 assets/）。" >&2; exit 2; }
  printf '模板:     %s\n' "$tpl"
  printf '仓库副本: %s\n' "$tools_dir"
  drift=0
  for f in "$tpl"/*.sh; do
    name="$(basename "$f")"
    [[ "$name" == "selftest.sh" ]] && continue
    if [[ ! -f "$tools_dir/$name" ]]; then
      printf '  缺失: %s\n' "$name"; drift=1
    elif ! cmp -s "$f" "$tools_dir/$name"; then
      printf '  漂移: %s\n' "$name"; drift=1
    fi
  done
  for f in "$tools_dir"/*.sh; do
    [[ -e "$f" ]] || continue
    name="$(basename "$f")"
    [[ -f "$tpl/$name" ]] || printf '  （仓库里多出来的，模板里没有: %s）\n' "$name"
  done
  for f in "$target"/*.sh; do
    [[ -e "$f" ]] || continue
    printf '  ✗ 旧布局遗留: agents-cooperation/%s（跑一次 coop-init.sh 会把它搬进 _tools/）\n' "$(basename "$f")"
    drift=1
  done
  if (( drift )); then
    printf '✗ 仓库副本和模板不一致。跑一次**模板**那份重新同步：\n    %s/coop-init.sh\n' "$tpl" >&2
    exit 1
  fi
  printf '✓ 仓库副本与模板一致。\n'
  exit 0
fi

# ---- 同步脚本（模板 → 仓库副本 _tools/）+ 旧布局迁移，逐个报告，不闷声覆盖 ----
declare -a created=() updated=() same=() refused=() moved=() dropped=()
legacy_dirty=""
if (( want_sync )) && [[ "$src" == "$tools_dir" || "$src" == "$target" ]]; then
  printf '提示：这次是从仓库副本自己跑的，脚本没动（副本不给自己当模板）。\n'
  if tpl="$(find_template_dir)"; then
    printf '  要同步（模板 → 副本）：%s/coop-init.sh\n' "$tpl"
  else
    printf '  找不到模板目录（skill 的 assets/）——到 skill 目录里跑一次 coop-init.sh。\n'
  fi
  printf '  只对账：%s --check-sync\n' "$0"
elif (( want_sync )); then
  tpl="$(find_template_dir)" || { printf '✗ 找不到模板目录（skill 的 assets/）。到 skill 目录里跑一次，或用 --check-sync。\n' >&2; exit 2; }
  mkdir -p "$tools_dir"

  # (1) 旧布局迁移：agents-cooperation/*.sh → _tools/*.sh。先搬，让后面的同步
  #     对"搬过来的那份"照常走护栏；未提交的手改一律不碰。
  for f in "$target"/*.sh; do
    [[ -e "$f" ]] || continue
    name="$(basename "$f")"
    if [[ -f "$tools_dir/$name" ]]; then
      if cmp -s "$f" "$tools_dir/$name"; then
        rm -f "$f"; dropped+=("$name")              # 两边一样，删掉根目录这份
      else
        legacy_dirty="$legacy_dirty $name(和 _tools/ 里那份不一样)"
      fi
      continue
    fi
    if ! content_is_recoverable "$f"; then
      legacy_dirty="$legacy_dirty $name"
      continue
    fi
    mv "$f" "$tools_dir/$name"
    moved+=("$name")
  done

  # (2) 模板 → 副本
  for f in "$tpl"/*.sh; do
    name="$(basename "$f")"
    [[ "$name" == "selftest.sh" ]] && continue      # 回归测试脚本属于 skill，不进协作目录
    if [[ ! -f "$tools_dir/$name" ]]; then
      cp "$f" "$tools_dir/$name"; chmod +x "$tools_dir/$name"; created+=("$name")
    elif cmp -s "$f" "$tools_dir/$name"; then
      same+=("$name")
    elif content_is_recoverable "$tools_dir/$name"; then
      cp "$f" "$tools_dir/$name"; chmod +x "$tools_dir/$name"; updated+=("$name")
    else
      refused+=("$name")          # 内容 git 里还没有备份 → 不覆盖，免得把改动搞丢
    fi
  done

  printf '协作目录: %s\n' "$target"
  printf '工具目录: %s\n' "$tools_dir"
  if (( ${#moved[@]} )); then printf '  从根目录搬进 _tools/ %d 个: %s\n' "${#moved[@]}" "${moved[*]}"; fi
  if (( ${#dropped[@]} )); then printf '  删掉根目录重复的 %d 个: %s\n' "${#dropped[@]}" "${dropped[*]}"; fi
  if (( ${#created[@]} )); then printf '  新建 %d 个: %s\n' "${#created[@]}" "${created[*]}"; fi
  if (( ${#updated[@]} )); then printf '  更新 %d 个: %s\n' "${#updated[@]}" "${updated[*]}"; fi
  if (( ${#refused[@]} )); then
    printf '  跳过 %d 个（内容还没进 git，覆盖就找不回来了）: %s\n' "${#refused[@]}" "${refused[*]}" >&2
    printf '  ✗ 这几个没动。先把改动提交（或至少 `git add` 一次——进了对象库就算有备份）再回来同步；\n' >&2
    printf '    直接覆盖会把它们搞丢。\n' >&2
  fi
  printf '  未变 %d 个\n' "${#same[@]}"
  if (( ${#updated[@]} )); then
    printf '\n⚠️ 有脚本被更新了——提交前先看一眼改了什么：\n'
    printf '    git -C "%s" diff -- agents-cooperation/\n' "$root"
    printf '  记住：模板（skill 的 assets/）才是正本；仓库那份是副本，别直接改它。\n'
  fi

  # (3) 已经装过的钩子壳子若还指着旧路径（agents-cooperation/coop-hook.sh），
  #     它会在 `[ -f ... ] || exit 0` 那里悄悄放行——必须改写，并且说出来。
  hd="$(hookdir)"
  for name in $hook_names; do
    dst="$hd/$name"
    [[ -f "$dst" ]] || continue
    grep -q "$hook_marker" "$dst" || continue
    grep -q 'agents-cooperation/coop-hook.sh' "$dst" || continue
    hook_body "$name" > "$dst"; chmod +x "$dst"
    printf '  钩子 %s 原来指着旧路径，已改写成 _tools/coop-hook.sh（不然它会静默失效）。\n' "$dst"
  done

  if [[ -n "${legacy_dirty// /}" ]]; then
    printf '\n✗ 根目录还有没搬的工具脚本（内容 git 里还没有备份，不敢动）：%s\n' "$legacy_dirty" >&2
    printf '  这几份请自己处理：提交掉再重跑，或确认没用后删掉。\n' >&2
    exit 1
  fi
  if (( ${#refused[@]} )); then exit 1; fi
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
  if [[ ! -f "$tools_dir/coop-hook.sh" ]]; then
    printf '✗ 工具目录还没铺好（缺 %s/coop-hook.sh）。先跑一次不带参数的 coop-init.sh。\n' "$tools_dir" >&2
    exit 1
  fi
  hd="$(hookdir)"
  mkdir -p "$hd"
  stamp="$(date '+%Y%m%d%H%M%S')"
  installed=0
  skipped=0
  for name in $hook_names; do
    dst="$hd/$name"
    if [[ -f "$dst" ]] && ! grep -q "$hook_marker" "$dst" && (( ! force_hooks )); then
      printf '跳过 %s：已存在别的钩子（要覆盖就加 --force-hooks）\n' "$dst" >&2
      skipped=$(( skipped + 1 ))
      continue
    fi
    if [[ -f "$dst" ]] && ! grep -q "$hook_marker" "$dst"; then
      cp "$dst" "$dst.bak-$stamp"
      printf '已备份原钩子到 %s\n' "$dst.bak-$stamp" >&2
    fi
    hook_body "$name" > "$dst"
    chmod +x "$dst"
    installed=$(( installed + 1 ))
  done
  printf '装了 %d 个 git 钩子（跳过 %d 个）。\n' "$installed" "$skipped"
  printf '注意：钩子要求提交消息里要么有 Coop-Block、要么有 Coop-Skip；合并提交本来就放行，\n'
  printf '只有"初始化仓库、还没有协作目录"那种提交才用 git commit --no-verify。\n'
fi

printf '\n下一步：\n'
printf '  1. 把 agents-cooperation/ 提交进 git（别 ignore 掉；index-reserved.txt 要一起提交）\n'
printf '  2. 用 ./agents-cooperation/_tools/coop-new-block.sh -f <功能> -t "<标题>" 建第一个块\n'
