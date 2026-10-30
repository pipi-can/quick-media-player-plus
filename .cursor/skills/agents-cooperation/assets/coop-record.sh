#!/usr/bin/env bash
# coop-record.sh —— 把一个提交回写进协作块（改块的 [GitBranch] 和 [GitCommitIds]）。
#
# 用法：
#   ./coop-record.sh <块编号> [sha]
#   例：./coop-record.sh 10            # sha 默认取当前 HEAD
#       ./coop-record.sh 10 d9fe736
#
# 行为：
#   - 找到 [Index] 等于 <块编号> 的那个块；
#   - [GitCommitIds] 前面插入这个 sha（已经在里面就不重复插）；
#   - [GitBranch] 填成当前分支名；
#   - 只改这个块里的这两行，别的块和正文一律不动。
#
#   回写本身会再产生一次提交，那一次不用再登记（它是登记操作，不是实现）。

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_coop-common.sh"

id="${1:-}"
[[ -n "$id" ]] || { echo "用法: $0 <块编号> [sha]" >&2; exit 2; }

sha="${2:-}"
if [[ -z "$sha" ]]; then
  sha="$(git -C "$COOP_ROOT" rev-parse --short HEAD)"
fi
branch="$(git -C "$COOP_ROOT" rev-parse --abbrev-ref HEAD)"

# 定位块所在文件（编号必须唯一，撞号就停下让你先修）
target="$(coop_find_block_file "$id")" || exit 1

# 读现有 [GitCommitIds]（用共用库，别再手写 awk）
cur="$(coop_get_field "$target" "$id" GitCommitIds)"

mapfile -t old < <(coop_shas_lines "$cur")
for s in "${old[@]:-}"; do
  [[ -z "$s" ]] && continue
  if [[ "$s" == "$sha" ]]; then
    echo "块 #$id 里已经记了这个提交（$sha），只更新分支。" >&2
    mapfile -t new < <(printf '%s\n' "${old[@]}")
    break
  fi
done
if [[ -z "${new+x}" ]]; then
  new=("$sha" "${old[@]:-}")
fi

# 去掉可能的前导空元素
clean=()
for s in "${new[@]}"; do [[ -n "$s" ]] && clean+=("$s"); done
new_json="$(coop_shas_json "${clean[@]}")"

# 写回：字段不存在就**插入**（不能只做替换——人类手写的块可能没有这两行）
coop_set_field "$target" "$id" GitBranch    "$branch"
coop_set_field "$target" "$id" GitCommitIds "$new_json"

# 自检：确认真的写进去了（宁可报错，也不要"打印成功、其实没写"）
got_branch="$(coop_get_field "$target" "$id" GitBranch)"
got_commits="$(coop_get_field "$target" "$id" GitCommitIds)"
if [[ "$got_branch" != "$branch" || "$got_commits" != "$new_json" ]]; then
  echo "✗ 回写没有生效（写进去的是 GitBranch='$got_branch' GitCommitIds='$got_commits'）。" >&2
  echo "  这通常是块里没有这两个字段、或字段写得不是顶格。请先跑 ./coop-lint.sh 看看。" >&2
  exit 1
fi

printf '已回写块 #%s\n' "$id"
printf '  文件:        %s\n' "${target#"$COOP_ROOT"/}"
printf '  分支:        %s\n' "$branch"
printf '  提交(新→旧): %s\n' "$new_json"
printf '\n下一步：把这次改动提交掉，例如\n'
printf '  git add "%s" && git commit -m "docs(agents-cooperation): 回写协作块 %s 的提交记录\n\nCoop-Skip: 纯登记操作"\n' "${target#"$COOP_ROOT"/}" "$id"
