#!/usr/bin/env bash
# coop-hook.sh —— git 钩子实际干活的地方。
#
# 由 `coop-init.sh --hooks` 装到 .git/hooks/ 的两个瘦壳子调用（壳子只负责找仓库根、转给这里），
# 好处是：检查逻辑本身跟着仓库走，改了这里所有克隆都生效。
# 也可以手工跑：
#
#   ./coop-hook.sh pre-commit          # 跑 coop-lint + 防删块 + coop-docs-check（脚本/Markdown 语法体检）
#   ./coop-hook.sh commit-msg <文件>    # 检查提交消息带没带 Coop-Block（或 Coop-Skip）
#
# 确实无关的提交（初始化仓库等）可以用 `git commit --no-verify` 跳过；
# 合并 / revert 提交本来就放行，不用绕。

set -uo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "不在 git 仓库里" >&2; exit 0; }
cd "$root" || exit 0
# 协作目录就是本脚本所在目录（不写死名字，也方便回归测试）
coop="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "$coop" in
  "$root"/*) coop_rel="${coop#"$root"/}" ;;
  *)         coop="$root/agents-cooperation"; coop_rel="agents-cooperation" ;;
esac

# 块编号解析：围栏感知（文档里演示块格式不算真块）、CRLF 安全。
# 和 _coop-common.sh 里的解析保持一致；`_` 开头的说明文档在调用处排除。
ids_of_stream() {
  awk '
    /^[ \t]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    /^\[[Ii]ndex\][:：]/ {
      v = $0; sub(/\r$/, "", v)
      sub(/^\[[Ii]ndex\][:：][ \t]*/, "", v); sub(/[ \t]+$/, "", v)
      if (v != "") print v
    }
  '
}

block_ids_in_head() {
  local relpath
  git ls-tree -r --name-only HEAD -- "$coop_rel" 2>/dev/null \
    | grep -E '\.(md|markdown)$' \
    | while IFS= read -r relpath; do
        case "${relpath#"$coop_rel"/}" in _*|*/_*) continue ;; esac
        git show "HEAD:$relpath" 2>/dev/null | ids_of_stream
      done
}

block_ids_in_worktree() {
  local f rel
  while IFS= read -r -d '' f; do
    rel="${f#"$coop"/}"
    case "$rel" in _*|*/_*) continue ;; esac
    ids_of_stream < "$f"
  done < <(find "$coop" -type f \( -name '*.md' -o -name '*.markdown' \) -print0 2>/dev/null)
}

stage="${1:-}"

case "$stage" in
  pre-commit)
    rc=0

    # 1) 协作块格式
    if [[ -f "$coop/coop-lint.sh" ]]; then
      bash "$coop/coop-lint.sh" -q || rc=1
    fi

    # 2) 防删块：块只作废，不删除（删了编号会被回收，Coop-Block 反查就串台）
    #    纯数字编号和人类编号（ren-1）都覆盖
    if (( rc == 0 )) && git rev-parse --verify -q HEAD >/dev/null 2>&1 && [[ -d "$coop" ]]; then
      old="$(block_ids_in_head | sort -u)"
      new="$(block_ids_in_worktree | sort -u)"
      if [[ -n "$old" ]]; then
        gone="$(comm -23 <(printf '%s\n' "$old") <(printf '%s\n' "$new") | tr '\n' ' ')"
        if [[ -n "${gone// /}" ]]; then
          echo "✗ 这些协作块编号被删掉了：$gone" >&2
          echo "  约定是**只作废不删除**：把它的 [Valid] 改成 false 就好。" >&2
          echo "  删块会把编号放回池子，后人用同一个编号时 Coop-Block 反查就串台了。" >&2
          rc=1
        fi
      fi
    fi

    # 3) 文件语法体检：脚本 bash -n + Markdown 结构 / frontmatter / 内部链接
    #    这里**不** gate 在上一步的 rc 上：两类问题互相独立，一次把话说完，省得来回改两轮。
    if [[ -f "$coop/coop-docs-check.sh" ]]; then
      bash "$coop/coop-docs-check.sh" -q || rc=1
    fi

    if (( rc != 0 )); then
      echo "（协作检查没过。先把上面报的改掉——尤其格式问题通常就是一行的事。）" >&2
      echo "（真跑不动、必须强推时，才用 git commit --no-verify。）" >&2
    fi
    exit "$rc"
    ;;
  commit-msg)
    msgfile="${2:-}"
    [[ -n "$msgfile" && -f "$msgfile" ]] || exit 0
    first="$(head -1 "$msgfile")"
    case "$first" in
      Merge*|"Revert "*|"fixup!"*|"squash!"*) exit 0 ;;
    esac
    # 明确声明"本次不用登记"（纯文案/注释/格式/笔误/纯登记）→ 放行，但要写原因
    if grep -qE '^Coop-Skip:[[:space:]]*[^[:space:]]+' "$msgfile"; then
      exit 0
    fi
    if ! grep -qE '^Coop-Block:[[:space:]]*[^[:space:]]+' "$msgfile"; then
      echo "✗ 提交消息里既没有 'Coop-Block: <编号>'，也没有 'Coop-Skip: <原因>'。" >&2
      echo "  · 改动涉及功能 / 接口 / 取舍 → 必须登记协作块，带 Coop-Block / Coop-Folder / Coop-Author。" >&2
      echo "  · 只是文案 / 注释 / 格式 / 笔误 / 纯登记 → 正文带一行 'Coop-Skip: <一句话原因>'。" >&2
      echo "  判断标准见规则文件 .cursor/rules/agents-cooperation.mdc 的第一节。" >&2
      echo "  （合并 / revert 提交钩子本来就放行；初始化仓库那种还没有协作目录的提交才用 --no-verify。）" >&2
      exit 1
    fi
    exit 0
    ;;

  *)
    echo "用法: $0 pre-commit | commit-msg <提交消息文件>" >&2
    exit 2
    ;;
esac
