#!/usr/bin/env bash
# coop-find.sh —— 按关键词 / 编号找协作块（只读）。
#
# 两个主要用途：
#   1. 不知道功能归哪个文件夹 → 先按关键词搜一遍；
#   2. **要删某个模块 / 文件 / 类之前，用它找出"哪些块的思路依赖它"**。
#      这些块可能要置 [Valid]: false —— 但**必须先问用户、等用户同意**
#      （见 SKILL.md「删模块 / 删功能」一节）。
#
# 用法：
#   ./coop-find.sh <关键词> [关键词2 ...]   # 任一关键词命中就列出（不区分大小写）
#   ./coop-find.sh --id <编号>              # 打印某个块的原文（原样，方便贴给用户看）
#   ./coop-find.sh --list                   # 列出所有块的 编号 / 标题 / 文件
#
# 搜的是块文档正文，**围栏代码块里的示例不算**（且不搜 `_` 开头的说明文件）。
# 没搜到任何东西时退出码 1，方便脚本判断"找不到对应块"。

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_coop-common.sh"

# 打印用法。默认退 1（"没给参数"这种用法错误）；-h/--help 走 usage 0。
usage() { sed -n '2,20p' "$0"; exit "${1:-1}"; }

find_md_files() {
  find "$COOP_ROOT" -type f \( -name '*.md' -o -name '*.markdown' \) -print0 | sort -z
}

# ---- --id <编号>：打印块原文 ----
print_block() {
  local id="$1" f
  f="$(coop_find_block_file "$id")" || return 1
  printf '文件: %s\n\n' "${f#"$COOP_ROOT"/}"
  awk -v id="$id" '
    /^[ \t]*(```|~~~)/ { fence = !fence }
    {
      if (!fence) {
        l = $0; sub(/\r$/, "", l)
        if (l ~ /^\[[Ii]ndex\][:：]/) {
          v = l; sub(/^\[[Ii]ndex\][:：][ \t]*/, "", v); sub(/[ \t]+$/, "", v)
          if (started && v != id) exit
          if (v == id) started = 1
        }
      }
      if (started) print
    }
  ' "$f"
}

# ---- --list：列所有块 ----
list_blocks() {
  local row n=0
  while IFS= read -r row; do
    [[ -z "$row" ]] && continue
    local file idx valid author title branch commits
    IFS="$COOP_SEP" read -r file idx valid author title branch commits <<<"$row"
    printf '  #%s  [%s]  %s  %s  (%s)\n' "${idx:-<无编号>}" "$valid" "$author" "$title" "$file"
    n=$(( n + 1 ))
  done < <(coop_scan_rows)
  (( n > 0 )) || { echo "（一个块都没有）"; return 1; }
  return 0
}

# ---- 关键词搜索 ----
search_keywords() {
  local -a KW=("$@")
  local f rel idx title cur hit n=0
  while IFS= read -r -d '' f; do
    rel="${f#"$COOP_ROOT"/}"
    coop_is_ignored "$rel" && continue
    idx=""; title=""; cur=""
    while IFS=$'\t' read -r no line; do
      if [[ "$line" =~ ^\[Index\]:[[:space:]]*(.*)$ ]]; then
        idx="${BASH_REMATCH[1]}"; cur=""
      elif [[ "$line" =~ ^\[Title\]:[[:space:]]*(.*)$ ]]; then
        title="${BASH_REMATCH[1]}"
      fi

      hit=0
      for kw in "${KW[@]}"; do
        [[ "${line,,}" == *"${kw,,}"* ]] && { hit=1; break; }
      done
      (( hit )) || continue

      if [[ "$cur" != "$idx|$title" ]]; then
        printf '\n#%s  %s  (%s)\n' "${idx:-<无编号>}" "$title" "$rel"
        cur="$idx|$title"
      fi
      printf '   %s:%s  %s\n' "$rel" "$no" "$line"
      n=$(( n + 1 ))
    done < <(coop_file_lines "$f")
  done < <(find_md_files)

  if (( n == 0 )); then
    printf '没找到包含 %s 的协作块。\n' "$(printf '%s ' "${KW[@]}")" >&2
    printf '（可能确实没有；那就是新功能/新依赖——别默认"没有"，先按关键词换着搜两遍再下结论。）\n' >&2
    return 1
  fi
  return 0
}

case "${1:-}" in
  ""|help)            usage ;;
  -h|--help)          usage 0 ;;
  --id)   shift; print_block "${1:-}" ;;
  --list) list_blocks ;;
  *)      search_keywords "$@" ;;
esac
