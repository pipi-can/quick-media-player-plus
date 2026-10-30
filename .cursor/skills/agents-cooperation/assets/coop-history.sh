#!/usr/bin/env bash
# coop-history.sh —— 只读。给一个协作块编号，把这条思路的来龙去脉拉出来。
#
# 用法：./_tools/coop-history.sh <块编号>   （如 ./_tools/coop-history.sh 3）
#
# 输出：块的 Title / Author / GitBranch，然后按 [GitCommitIds]（最新在最前）
#       逐个打印提交的标题、正文和改动文件；数组是空的就退回按 Coop-Block 反查。
#
# 不修改任何文件。

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_coop-common.sh"

id="${1:-}"
if [[ -z "$id" ]]; then
  echo "用法: $0 <块编号>   例如: $0 3" >&2
  exit 2
fi

row=""
while IFS= read -r r; do
  [[ -z "$r" ]] && continue
  IFS="$COOP_SEP" read -r _f idx _v _a _t _b _c <<<"$r"
  if [[ "$idx" == "$id" ]]; then row="$r"; break; fi
done < <(coop_scan_rows)

if [[ -z "$row" ]]; then
  echo "没找到编号为 '$id' 的协作块。用 ./_tools/get-index.sh 看现有块。" >&2
  exit 1
fi

IFS="$COOP_SEP" read -r file idx valid author title branch commits <<<"$row"

printf '块 #%s  %s\n' "$idx" "$title"
printf '  文件:    %s\n' "$file"
printf '  作者:    %s\n' "$author"
printf '  有效:    %s\n' "$valid"
printf '  分支:    %s\n' "$branch"
printf '  提交:    %s\n' "${commits:-null}"
echo

run_git() { git -C "$COOP_ROOT" "$@"; }

mapfile -t SHAS < <(coop_shas_lines "$commits")

if (( ${#SHAS[@]} == 0 )); then
  echo "== [GitCommitIds] 是空的，按 trailer 反查 Coop-Block: $id =="
  # 必须锚定 ^…$：不然 'Coop-Block: 3' 会把 'Coop-Block: 30' 也捞进来
  mapfile -t SHAS < <(run_git log --format='%h' --grep="^Coop-Block: ${id}$" 2>/dev/null || true)
fi

if (( ${#SHAS[@]} == 0 )); then
  echo "== 这个块还没有提交记录 =="
  exit 0
fi

echo "== 提交（最新在最前）=="
for sha in "${SHAS[@]}"; do
  echo
  echo "---- $sha ----"
  if ! run_git cat-file -e "${sha}^{commit}" 2>/dev/null; then
    echo "  找不到这个提交（可能被 rebase / squash 掉了；用 git log --grep='^Coop-Block: ${id}$' 重找）"
    continue
  fi
  run_git log -1 --format='  %h  %ad  %an%n%n  %s%n%n%b' --date=short "$sha" | sed '/^$/{ /^  $/d }'
  echo "  改动文件:"
  run_git show --stat --format='' "$sha" | sed 's/^/    /' || true
done
