#!/usr/bin/env bash
# coop-lint.sh —— 只读。校验所有协作块的格式，把机器能查的错都查出来。
#
# 用法：./coop-lint.sh [-q]
#   有**错误** → 列出并退出码 1；只有警告 → 列出但退出码 0；干净 → 0。
#   -q 只打印有问题的那几行。
#
# 查这些（错误）：
#   - [Author] / [Title] 必填非空
#   - [Valid] 只能是 true / false
#   - AI 块必须有纯数字 [Index]；纯数字编号不能重复
#   - 人类块的 [Index]（若写了）必须是 <作者>-<序号>
#   - [GitBranch] 只能是 null 或非空且不含空格的分支名
#   - [GitCommitIds] 只能是 null，或 ["hex", ...]（每项 7~40 位十六进制）
#   - 文档必须放在功能文件夹下（agents-cooperation/<功能>/<文档>.md）
#   - 围栏代码块（``` / ~~~）必须成对闭合（不然脚本会整段跳过）
#   - 字段名大小写必须是 Index / Valid / …（脚本容忍 [index]，但要求规范写法）
#   - 冒号必须是半角 `:`（脚本也认全角 `：`，但要求规范写法）
#   - [Comments] 里 coop-new-block.sh 留的 TODO 占位符必须删掉
#
# 查这些（警告）：
#   - 字段被**缩进**了（脚本不会解析，多半是不小心）
#   - 同一功能文件夹里有重名 [Title]（扫描时容易看错）
#   - .md 文件里一个协作块都没解析到（多半是写错格式了）
#
# 不修改任何文件。

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_coop-common.sh"

quiet=0
[[ "${1:-}" == "-q" ]] && quiet=1

errors=0
warnings=0
blocks=0
declare -A seen_numeric=()
declare -A title_key=()
declare -A file_has_block=()

say()  { (( quiet )) || printf '%s\n' "$*"; }
fail() { printf '  ✗ %s\n' "$*"; errors=$(( errors + 1 )); }
warn() { printf '  ! %s\n' "$*"; warnings=$(( warnings + 1 )); }

CANON=" Index Valid Author Title GitBranch GitCommitIds Comments "
CANON_LC="${CANON,,}"

canon_of() {
  case "${1,,}" in
    index)       echo "Index" ;;
    valid)       echo "Valid" ;;
    author)      echo "Author" ;;
    title)       echo "Title" ;;
    gitbranch)   echo "GitBranch" ;;
    gitcommitids) echo "GitCommitIds" ;;
    comments)    echo "Comments" ;;
    *)           echo "$1" ;;
  esac
}

say "检查 $COOP_ROOT 下的协作块…"

# ---------- 逐块检查 ----------
while IFS= read -r row; do
  [[ -z "$row" ]] && continue
  IFS="$COOP_SEP" read -r file idx valid author title branch commits <<<"$row"
  blocks=$(( blocks + 1 ))
  file_has_block["$file"]=1
  where="$( [[ -n "$idx" ]] && echo "[Index $idx]" || echo "[无 Index]" ) $file"

  # 必填
  [[ -n "$author" ]] || fail "$where: 缺 [Author]"
  [[ -n "$title"  ]] || fail "$where: 缺 [Title]"

  # Valid
  case "$valid" in
    true|false) ;;
    "")         fail "$where: 缺 [Valid]" ;;
    *)          fail "$where: [Valid] 只能是 true 或 false，实际是 '$valid'" ;;
  esac

  # Index
  if [[ -z "$idx" ]]; then
    if [[ -n "$author" ]] && coop_is_ai "$author"; then
      fail "$where: AI 块必须有编号（用 get-index.sh --next 或 coop-new-block.sh 取），人类块才可以省"
    fi
  elif [[ "$idx" =~ ^[0-9]+$ ]]; then
    if [[ -n "${seen_numeric[$idx]:-}" ]]; then
      fail "$where: 编号 $idx 和 ${seen_numeric[$idx]} 撞了（两个 agent 同时算编号会出现这种）"
    else
      seen_numeric[$idx]="$file"
    fi
  else
    if [[ -n "$author" ]] && coop_is_ai "$author"; then
      fail "$where: AI 块必须用纯数字编号，不能用 '$idx'"
    elif [[ "$idx" != "$author"-* ]]; then
      fail "$where: 人类编号应形如 <作者>-<序号>（如 ren-1），实际是 '$idx'"
    elif [[ ! "${idx#"$author"-}" =~ ^[0-9]+$ ]]; then
      fail "$where: 人类编号的序号部分必须是数字，实际是 '$idx'"
    fi
  fi

  # GitBranch
  if [[ -n "$branch" && "$branch" != "null" ]]; then
    if [[ "$branch" =~ [[:space:]] ]]; then
      fail "$where: [GitBranch] 不能含空格：'$branch'"
    elif [[ "$branch" == "HEAD" ]]; then
      warn "$where: [GitBranch] 是 HEAD，说明提交时处于 detached HEAD，后来者切不过去"
    fi
  fi

  # GitCommitIds
  if [[ -n "$commits" && "$commits" != "null" ]]; then
    if [[ "$commits" != \[*\] ]]; then
      fail "$where: [GitCommitIds] 要么是 null，要么是 [\"sha\", ...]，实际是 '$commits'"
    else
      inner="${commits#[}"; inner="${inner%]}"
      if [[ -z "${inner// /}" ]]; then
        fail "$where: [GitCommitIds]: [] 是空数组——还没提交就写 null，写了提交就填 sha"
      else
        IFS=',' read -r -a parts <<<"$inner"
        for p in "${parts[@]}"; do
          if [[ ! "$p" =~ ^[[:space:]]*\"[0-9a-fA-F]{7,40}\"[[:space:]]*$ ]]; then
            fail "$where: [GitCommitIds] 里有不合法的项：'$p'（应为 7~40 位十六进制短 sha）"
          fi
        done
      fi
    fi
  fi

  # 位置
  if [[ "$file" != */* ]]; then
    fail "$file: 文档应放在功能文件夹下，即 agents-cooperation/<功能>/<文档>.md"
  elif [[ "${file%%/*}" == *[[:space:]]* ]]; then
    warn "$where: 功能文件夹名里有空格（'${file%%/*}'）——路径里带空格，脚本和命令行都容易踩坑"
  fi

  # 同功能重名标题
  if [[ -n "$title" ]]; then
    key="${file%%/*}|$title"
    if [[ -n "${title_key[$key]:-}" ]]; then
      warn "$where: 同一个功能里已经有同名 [Title]（'$title'），扫描时容易看混"
    else
      title_key["$key"]=1
    fi
  fi
done < <(coop_scan_rows)

# ---------- 逐文件检查 ----------
while IFS= read -r -d '' f; do
  rel="${f#"$COOP_ROOT"/}"
  coop_is_ignored "$rel" && continue      # `_` 开头的是说明文档，不是协作块

  # 围栏必须成对
  fences="$(awk '/^[ \t]*(```|~~~)/{ n++ } END{ print n+0 }' "$f")"
  if (( fences % 2 != 0 )); then
    fail "$rel: 围栏代码块没闭合（共 $fences 行围栏标记）——脚本会把后面的内容整段跳过"
  fi

  # 一个块都没解析到（且不是空文件）
  if [[ -z "${file_has_block[$rel]:-}" ]] && [[ -s "$f" ]]; then
    warn "$rel: 一个协作块都没解析到。要么这不是块文档，要么字段写法有问题（跑的时候看下面有没有报错）"
  fi

  # 逐行：字段拼写 / 全角冒号 / 缩进 / TODO 占位符
  while IFS=$'\t' read -r no line; do
    if [[ "$line" =~ ^\[([A-Za-z]+)\][:：] ]]; then
      name="${BASH_REMATCH[1]}"
      rest="${line#*]}"
      if [[ "$CANON" == *" $name "* ]]; then
        if [[ "$rest" == "："* ]]; then
          fail "$rel:$no: 字段用了全角冒号：[$name]：…，请改成半角 [ $name ]: …"
        fi
      elif [[ "$CANON_LC" == *" ${name,,} "* ]]; then
        fail "$rel:$no: 字段名大小写不对：[$name]，应为 [$(canon_of "$name")]"
      fi
    elif [[ "$line" == [[:space:]]*\[* ]]; then
      trimmed="${line#"${line%%[![:space:]]*}"}"
      if [[ "$trimmed" =~ ^\[([A-Za-z]+)\][:：] ]]; then
        name="${BASH_REMATCH[1]}"
        if [[ "$CANON_LC" == *" ${name,,} "* ]]; then
          warn "$rel:$no: 字段被缩进了（$trimmed）——脚本只认顶格的字段，这行不会被解析"
        fi
      fi
    fi

    if [[ "$line" == *"TODO: 删掉这行"* ]]; then
      fail "$rel:$no: 还留着 coop-new-block.sh 的 TODO 占位符没删——块还没写完"
    fi
  done < <(coop_file_lines "$f")
done < <(find "$COOP_ROOT" -type f \( -name '*.md' -o -name '*.markdown' \) -print0 | sort -z)

# ---------- 编号预留表 ----------
# 没有它，跨工作区/克隆的撞号保护会静默失效（编号各自算，合并后才撞）
if (( blocks > 0 )) && [[ ! -f "$COOP_RESERVE_FILE" ]]; then
  warn "没有 $COOP_RESERVE_FILE —— 跨工作区/克隆的撞号保护会失效。它应该被提交进 git"
fi

# ---------- 汇总 ----------
if (( errors == 0 && warnings == 0 )); then
  say "✓ $blocks 个协作块，格式没问题"
  exit 0
fi

(( quiet )) || echo
if (( errors > 0 )); then
  printf '✗ %d 个协作块：%d 个错误、%d 个警告\n' "$blocks" "$errors" "$warnings"
  exit 1
fi
if (( warnings > 0 )); then
  printf '△ %d 个协作块：0 个错误、%d 个警告（能用，但警告看一眼）\n' "$blocks" "$warnings"
  exit 0
fi
printf '✓ %d 个协作块，格式没问题\n' "$blocks"
exit 0
