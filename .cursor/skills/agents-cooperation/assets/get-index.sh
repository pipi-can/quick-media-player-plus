#!/usr/bin/env bash
# get-index.sh —— 只读。算出下一个协作块编号，并把现有协作块列出来。
#
# 用法：
#   ./_tools/get-index.sh                     # 完整报告
#   ./_tools/get-index.sh --next              # 只打印下一个可用编号
#   ./_tools/get-index.sh --valid             # 只列 Valid=true 的块
#   ./_tools/get-index.sh --folder <功能名>   # 只列某个功能文件夹里的块
#   （--valid 和 --folder 可以一起用，方便只扫相关的那几块）
#
# 不修改任何文件。

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_coop-common.sh"

mode_next=0
only_valid=0
only_folder=""

while (( $# > 0 )); do
  case "$1" in
    --next)   mode_next=1; shift ;;
    --valid)  only_valid=1; shift ;;
    --folder) only_folder="${2:?--folder 后面要跟功能文件夹名}"; shift 2 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

declare -a ROWS=()
mapfile -t ROWS < <(coop_scan_rows)

if (( mode_next )); then
  coop_next_index
  exit 0
fi

# 过滤
declare -a SHOWN=()
for row in "${ROWS[@]:-}"; do
  [[ -z "$row" ]] && continue
  IFS="$COOP_SEP" read -r file idx valid author title branch commits <<<"$row"
  if (( only_valid )) && [[ "$valid" != "true" ]]; then continue; fi
  if [[ -n "$only_folder" ]] && [[ "$file" != "$only_folder/"* ]]; then continue; fi
  SHOWN+=("$row")
done

echo "下一个可用编号: $(coop_next_index)"
reserved_max="$(coop_reserved_max)"
if (( reserved_max > 0 )); then
  echo "（编号预留表 index-reserved.txt 里已占到 $reserved_max；记得把它一起提交，别的 agent pull 后才看得到）"
fi
echo
# 缺编号的人类块（人类 = 作者不以 agent 结尾）
declare -a HUMAN=()
for row in "${ROWS[@]:-}"; do
  [[ -z "$row" ]] && continue
  IFS="$COOP_SEP" read -r file idx _v author title _b _c <<<"$row"
  [[ -z "$idx" ]] || continue
  if [[ -n "$only_folder" ]] && [[ "$file" != "$only_folder/"* ]]; then continue; fi
  if [[ -n "$author" ]] && coop_is_ai "$author"; then continue; fi
  if [[ -z "$author" ]]; then
    HUMAN+=("$file${COOP_SEP}(缺 [Author])${COOP_SEP}?${COOP_SEP}$title")
  else
    HUMAN+=("$file${COOP_SEP}${author}${COOP_SEP}${author}-$(coop_author_seq "$author")${COOP_SEP}$title")
  fi
done

if (( ${#HUMAN[@]} > 0 )); then
  echo "缺编号的人类协作块（建议补成 <作者>-<序号>；补前先确认作者是谁）："
  for l in "${HUMAN[@]}"; do
    IFS="$COOP_SEP" read -r file author sug title <<<"$l"
    printf '  - %s  [Author: %s] -> 建议 [Index]: %s  《%s》\n' "$file" "$author" "$sug" "$title"
  done
else
  echo "缺编号的人类协作块: 无"
fi
echo

echo "现有协作块:"
for row in "${SHOWN[@]:-}"; do
  [[ -z "$row" ]] && continue
  IFS="$COOP_SEP" read -r file idx valid author title _b _c <<<"$row"
  [[ -n "$idx" ]]    || idx="(缺)"
  [[ -n "$valid" ]]  || valid="?"
  [[ -n "$author" ]] || author="?"
  printf '  #%s  [%s]  %s  %s  (%s)\n' "$idx" "$valid" "$author" "$title" "$file"
done
