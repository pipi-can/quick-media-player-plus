#!/usr/bin/env bash
# coop-new-block.sh —— 新建一个协作块，编号自动取（不用手算、不会撞号）。
#
# 用法：
#   ./coop-new-block.sh -f <功能文件夹> -t <标题> [-d <文档名>] [-a <作者>]
#   例：./coop-new-block.sh -f playback -t "音量弹窗实现思路" -a opencode-agent
#       ./coop-new-block.sh -f playback -t "音量弹窗实现思路" -d 音量控制实现思路.md
#
# 行为：
#   - 功能文件夹不存在就创建；
#   - 文档不存在就创建（带一级标题）；
#   - 在文档末尾追加一个 [Valid]: true 的新块，[GitBranch] / [GitCommitIds] 先写 null，
#     [Comments] 留一句 TODO 提示；
#   - 作者默认取 $COOP_AUTHOR，再不然是 opencode-agent。
#
# 会写文件：只创建/追加，不动已有内容。

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_coop-common.sh"

folder=""
title=""
doc="实现思路.md"
author="${COOP_AUTHOR:-opencode-agent}"

while (( $# > 0 )); do
  case "$1" in
    -f) folder="${2:?}"; shift 2 ;;
    -t) title="${2:?}";  shift 2 ;;
    -d) doc="${2:?}";    shift 2 ;;
    -a) author="${2:?}"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$folder" ]] || { echo "必须给 -f <功能文件夹>" >&2; exit 2; }
[[ -n "$title"  ]] || { echo "必须给 -t <标题>"      >&2; exit 2; }

dir="$COOP_ROOT/$folder"
file="$dir/$doc"

# 取号必须串行化：同一工作区里两个 agent 同时建块，拿到的是不同的号。
coop_lock || exit 1
trap 'coop_unlock' EXIT

# 编号：agent 用纯数字，人用 <作者>-<序号>（在锁里算，算完立刻写块 + 登记预留）
idx="$(coop_make_index "$author")"

if ! coop_is_ai "$author"; then
  echo "注意：作者 '$author' 不以 agent 结尾，按人类块处理，编号用 $idx。" >&2
else
  coop_reserve_index "$idx" "$author"
fi

mkdir -p "$dir"

if [[ ! -f "$file" ]]; then
  printf '# %s\n' "${doc%.md}" > "$file"
  created_doc=1
else
  created_doc=0
fi

{
  printf '\n## %s\n\n' "$title"
  printf '[Index]: %s\n' "$idx"
  printf '[Valid]: true\n'
  printf '[Author]: %s\n' "$author"
  printf '[Title]: %s\n' "$title"
  printf '[GitBranch]: null\n'
  printf '[GitCommitIds]: null\n'
  printf '[Comments]:\n'
  printf '  TODO: 删掉这行，写清楚实现思路——目标 / 设计 / 关键取舍 / 遗留问题。\n'
  printf '  （写法参考 skill 的 references/examples.md）\n'
} >> "$file"

printf '已新建协作块 #%s\n' "$idx"
printf '  文件:  %s%s\n' "$file" "$( (( created_doc )) && echo '（新建）' || echo '（追加到已有文档）' )"
printf '  作者:  %s\n' "$author"
printf '  标题:  %s\n' "$title"
printf '\n下一步：\n'
printf '  1. 编辑 %s，把 [Comments] 的 TODO 换成真正的思路\n' "$file"
printf '  2. 写代码\n'
printf '  3. git add && git commit（正文写思路，尾部带 Coop-Block: %s / Coop-Folder: %s / Coop-Author: %s）\n' "$idx" "$folder" "$author"
printf '  4. ./coop-record.sh %s    # 把这次提交回写进块\n' "$idx"
